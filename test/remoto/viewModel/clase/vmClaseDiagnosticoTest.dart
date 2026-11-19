import 'dart:io';

import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../datosPruebas.dart';

//diagnostico del modulo 2 contra el backend real (plan-diagnostico-
//clases.md): el formulario de clase (Clasesviewmodel) y la pantalla del grupo
//(DetalleGrupoViewModel) con sus cadenas reales. El setUpAll crea por
//corrida una categoria, un curso y un grupo; cada caso registra sus clases y
//las identifica por el codigo nuevo que aparece en la lista
class VmClaseDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late String _idInstructor;
  Grupoentidad? _grupo;
  //segundo grupo del mismo curso, sin horarios: para BK-04
  Grupoentidad? _grupoSinHorario;

  void preparar({
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required PeriodoInscripcionViewModel Function() crearVmPeriodo,
  }) {
    setUpAll(() async {
      final marca = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');
      expect(
        await vmCategoria.insertarCategoria(
          CategoriaEntidad(
            titulo: 'prueba_$marca',
            descripcion: 'categoria para el diagnostico de clases',
            imagenFile: _imagenPrueba(),
          ),
        ),
        isA<Exito>(),
      );
      final deporte =
          ((await crearVmDeporte().obtenerDeportes()).datos as List<String>).first;
      final curso = await crearVmCurso().agregarCurso(
        CursoEntidad(
          nombreCurso: 'curso_$marca',
          nombreDeporte: deporte,
          tituloCategoria: 'prueba_$marca',
          descripcion: 'curso para el diagnostico de clases',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201);
      final c = curso.datos as CursoEntidad;

      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      _idInstructor = vmInstructores.instructores.first.id;
      final g = await crearVmGrupos().insertarGrupo(
        Grupoentidad(
          categoria: c.tituloCategoria,
          curso: c.nombreCurso,
          anio: DateTime.now().year,
          iterable: 0,
          imagen: c.imagen,
          cupos: 20,
          idInstructor: _idInstructor,
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
          fechaInscripcionCierre: cierreInscripcionPruebas(),
          fechaInscripcionApertura: aperturaFuturaPruebas(),
        ),
      );
      expect(g.codigoHttp, 201);
      final vm = crearVmPeriodo();
      await vm.cargar();
      _grupo = vm.grupos.datos.firstWhere(
        (x) => x.categoria == c.tituloCategoria && x.curso == c.nombreCurso,
      );
      await sembrarHorariosSemana(_grupo!);

      //BK-04: un grupo sin horarios, para las clases que piden justificacion
      final sin = await crearVmGrupos().insertarGrupo(
        Grupoentidad(
          categoria: c.tituloCategoria,
          curso: c.nombreCurso,
          anio: DateTime.now().year,
          iterable: 0,
          imagen: c.imagen,
          cupos: 20,
          idInstructor: _idInstructor,
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
          fechaInscripcionCierre: cierreInscripcionPruebas(),
          fechaInscripcionApertura: aperturaFuturaPruebas(),
        ),
      );
      expect(sin.codigoHttp, 201);
      final vm2 = crearVmPeriodo();
      await vm2.cargar();
      _grupoSinHorario = vm2.grupos.datos.firstWhere(
        (x) =>
            x.categoria == c.tituloCategoria &&
            x.curso == c.nombreCurso &&
            x.iterable != _grupo!.iterable,
      );
    });
  }

  void prueba1RegistrarAyer(
    Clasesviewmodel Function() crearVm,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
  ) {
    String metodo = "Registrar clase";
    String caso = "la clase de ayer aparece en la pantalla del grupo con sus datos";
    test('$capa - $tipo - $metodo - $caso', () async {
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      final nueva = await _registrar(crearVm, crearVmGrupo, ayer, '2');

      expect(nueva, isNotNull, reason: 'no aparecio la clase');
      expect(nueva!.codigo, isNotNull);
      expect(nueva.horas, 2);
      expect(nueva.minutos, 0);
      expect(nueva.idInstructor, _idInstructor);
      expect(_dia(nueva.fecha!), _dia(ayer));
    });
  }

  //H-03
  void prueba2RegistrarHoy(
    Clasesviewmodel Function() crearVm,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
  ) {
    String metodo = "Registrar clase";
    String caso = "una clase con fecha de hoy se registra";
    test('$capa - $tipo - $metodo - $caso', () async {
      final hoy = DateTime.now();
      final r = await _crearVm(crearVm).registrarClase(fecha: hoy, horasTexto: '1');
      expect(r, isA<Exito>(), reason: _texto(r));
    });
  }

  //H-02 (descartada: el backend responde con error)
  void prueba5EliminarInexistente(DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo) {
    String metodo = "Eliminar clase";
    String caso = "eliminar una clase que no existe no es Exito";
    test('$capa - $tipo - $metodo - $caso', () async {
      final r = await crearVmGrupo(_grupoCreado()).eliminarClase(999999999);
      expect(r, isA<Fallo>(), reason: _texto(r));
    });
  }

  //los dos siguientes salen rojos: solo los llama
  //test/diagnostico/clases/remoto_diagnostico_test.dart, no main_test.dart

  //CL-07 (corregido): el backend nuevo recibe un LocalDate y la app envia solo
  //el dia local. Antes, en UTC, de noche la clase caia en el dia siguiente.
  //CL-06 (reemplazado por CL-07): la app mandaba la hora local sin zona y el backend la
  //tomaba como UTC; lo de 00:00 a 04:59 quedaba en el dia anterior.
  //showDatePicker (claseFormulario.dart) devuelve la
  //fecha elegida a las 00:00, que es el primer caso; 04:59 y 05:00 son el
  //borde que se corria
  void prueba3FechaSinCorrimiento(
    Clasesviewmodel Function() crearVm,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
  ) {
    String metodo = "Registrar clase";
    String caso = "la fecha elegida en el selector (00:00), a las 04:59, 05:00 y 23:30 queda en ese dia";
    test('$capa - $tipo - $metodo - $caso', () async {
      final base = DateTime.now().subtract(const Duration(days: 7));
      final primero = DateTime(base.year, base.month, base.day);
      //un dia por hora: el backend deja una sola clase por fecha (BK-08)
      final horas = [
        Duration.zero,
        const Duration(hours: 4, minutes: 59),
        const Duration(hours: 5),
        const Duration(hours: 23, minutes: 30),
      ];
      for (var i = 0; i < horas.length; i++) {
        final dia = DateTime(primero.year, primero.month, primero.day - i);
        final hora = dia.add(horas[i]);
        final nueva = await _registrar(crearVm, crearVmGrupo, hora, '1');
        expect(nueva, isNotNull, reason: 'no aparecio la clase de $hora');
        expect(_dia(nueva!.fecha!), _dia(dia), reason: 'enviada $hora');
      }
    });
  }

  //antes diagnostico de BK-08: el backend reutiliza la clase de esa fecha y
  //responde 200 con ella. Antes llegaba como un Fallo con un TypeError
  void prueba7FechaConClase(
    Clasesviewmodel Function() crearVm,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
  ) {
    String metodo = "Registrar clase";
    String caso = "una fecha que ya tiene clase es Exito, avisa y no crea otra";
    test('$capa - $tipo - $metodo - $caso', () async {
      final fecha = DateTime.now().subtract(const Duration(days: 2));
      await _crearVm(crearVm).registrarClase(fecha: fecha, horasTexto: '1');
      final antes = crearVmGrupo(_grupoCreado());
      await antes.cargarClases();

      final r = await _crearVm(crearVm).registrarClase(fecha: fecha, horasTexto: '2');

      expect(r, isA<Exito<bool>>(), reason: _texto(r));
      expect((r as Exito<bool>).datos, isFalse);
      final despues = crearVmGrupo(_grupoCreado());
      await despues.cargarClases();
      expect(despues.clases.datos, hasLength(antes.clases.datos.length));
    });
  }

  //H-08, observacion: la regla de fechas y duracion es del cliente (AS-13)
  void prueba4ObservacionFuturaYLarga(Clasesviewmodel Function() crearVm) {
    String metodo = "Registrar clase";
    String caso = "observacion - clase de manana y clase de 30 horas";
    test('$capa - $tipo - $metodo - $caso', () async {
      final manana = await _crearVm(crearVm).registrarClase(
        fecha: DateTime.now().add(const Duration(days: 1)),
        horasTexto: '1',
      );
      final larga = await _crearVm(crearVm).registrarClase(
        fecha: DateTime.now().subtract(const Duration(days: 2)),
        horasTexto: '30',
      );
      print('H-08 clase de manana: ${_texto(manana)}; clase de 30 horas: ${_texto(larga)}');
    });
  }

  //H-01
  void prueba6EliminarClase(
    Clasesviewmodel Function() crearVm,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
  ) {
    String metodo = "Eliminar clase";
    //antes diagnostico de CL-01: quedo en verde con el backend nuevo
    String caso = "la clase eliminada sale de la pantalla del grupo";
    test('$capa - $tipo - $metodo - $caso', () async {
      final nueva = await _registrar(
        crearVm,
        crearVmGrupo,
        DateTime.now().subtract(const Duration(days: 5)),
        '2',
      );
      expect(nueva, isNotNull);

      final vm = crearVmGrupo(_grupoCreado());
      await vm.cargarClases();
      final r = await vm.eliminarClase(nueva!.codigo!);
      expect(r, isA<Exito>(), reason: _texto(r));

      //eliminarClase recarga la lista del mismo vm
      final quedan = vm.clases.datos.where((c) => c.codigo == nueva.codigo).toList();
      expect(
        quedan,
        isEmpty,
        reason: 'sigue la clase ${nueva.codigo} con eliminado ${quedan.firstOrNull?.eliminado}',
      );
    });
  }

  //registra y devuelve la clase nueva: la que aparece en la lista y no
  //estaba antes
  Future<Claseentidad?> _registrar(
    Clasesviewmodel Function() crearVm,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
    DateTime fecha,
    String horas,
  ) async {
    final antes = crearVmGrupo(_grupoCreado());
    await antes.cargarClases();
    final codigos = antes.clases.datos.map((c) => c.codigo).toSet();

    final r = await _crearVm(crearVm).registrarClase(fecha: fecha, horasTexto: horas);
    expect(r, isA<Exito>(), reason: _texto(r));

    final despues = crearVmGrupo(_grupoCreado());
    await despues.cargarClases();
    return despues.clases.datos.where((c) => !codigos.contains(c.codigo)).firstOrNull;
  }

  //como la ruta formularioClase: el vm se inicializa con el grupo
  Clasesviewmodel _crearVm(Clasesviewmodel Function() crearVm) {
    final g = _grupoCreado();
    return crearVm()..inicializarGrupo(g.categoria, g.curso, g.anio, g.iterable, _idInstructor);
  }

  String _dia(DateTime f) => FormatDate.fechaACadena(f, '-');

  String _texto(Resultado r) => switch (r) {
    Exito() => 'Exito',
    Fallo(:final codigo, :final mensaje) => 'Fallo $codigo $mensaje',
  };

  //antes diagnostico de BK-04 (transversal/remoto_backend_nuevo): sin horario
  //ese dia el backend exige una justificacion. El formulario carga los
  //horarios, la pide y la envia; sin ella el backend responde 422
  void prueba8Justificacion(Clasesviewmodel Function() crearVm) {
    String metodo = "Registrar clase";
    String caso = "sin horario ese dia la pide y se registra con justificacion; con horario no la pide";
    test('$capa - $tipo - $metodo - $caso', () async {
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      final g = _grupoSinHorario;
      expect(g, isNotNull, reason: 'el setUpAll no creo el grupo sin horarios');

      Clasesviewmodel formulario(Grupoentidad grupo) =>
          crearVm()..inicializarGrupo(
            grupo.categoria,
            grupo.curso,
            grupo.anio,
            grupo.iterable,
            _idInstructor,
          );

      //sin cargar los horarios decide el backend: sin justificacion, 422
      final sinJustificacion = await formulario(g!).registrarClase(
        fecha: ayer,
        horasTexto: '2',
      );
      expect(sinJustificacion, isA<Fallo>(), reason: _texto(sinJustificacion));
      expect((sinJustificacion as Fallo).codigo, 422);

      //como la ruta: con los horarios cargados la app sabe que la pide
      final vm = formulario(g);
      await vm.cargarHorarios();
      expect(vm.requiereJustificacion(ayer), isTrue);
      final r = await vm.registrarClase(
        fecha: ayer,
        horasTexto: '2',
        justificacion: 'Clase de reposicion acordada con el grupo',
      );
      expect(r, isA<Exito<bool>>(), reason: _texto(r));
      expect((r as Exito<bool>).datos, isTrue);

      //el grupo con horario toda la semana no la pide
      final conHorario = formulario(_grupoCreado());
      await conHorario.cargarHorarios();
      expect(conHorario.requiereJustificacion(ayer), isFalse);
    });
  }

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
