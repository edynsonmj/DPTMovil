import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../datosPruebas.dart';
import '../../jwtPruebas.dart';

//diagnostico del modulo 5 contra el backend real (plan-diagnostico-
//estadisticas.md, 4.3): EstadisticasViewModel → servicio → repositorio →
//conexion → backend, sobre datos propios de cada corrida. El setUpAll crea
//categoria, curso, grupo, abre sus inscripciones, inscribe a dos alumnos,
//registra una clase de 2 h con fecha de ayer y marca la asistencia del
//alumno A. La asistencia se siembra con PUT /clase/{codigo}/asistencia directo:
//la conexion de atenciones de la app usa rutas que el backend ya no tiene (BK-02).
//Los casos dependen del orden
class VmEstadisticasAsistenciaTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late Dio _dio;
  late String _alumnoA;
  late String _alumnoB;
  late int _idClase;
  Grupoentidad? _grupo;
  final DateTime _ayer = DateTime.now().subtract(const Duration(days: 1));

  //lo reusa test/diagnostico/transversal/remoto_backend_nuevo_test.dart
  Grupoentidad get grupoSembrado => _grupoCreado();

  void preparar({
    required Dio dio,
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required Facultadesviewmodel Function() crearVmFacultades,
    required PeriodoInscripcionViewModel Function() crearVmPeriodo,
    required Inscripcionviewmodel Function() crearVmInscripcion,
    required Clasesviewmodel Function() crearVmClase,
    required DetalleGrupoViewModel Function(Grupoentidad) crearVmDetalle,
    required Servicioautenticacion servicioAutenticacion,
  }) {
    _dio = dio;
    setUpAll(() async {
      String marca = _marcaTiempo();
      Resultado<CategoriaEntidad> categoria = await vmCategoria
          .insertarCategoria(
            CategoriaEntidad(
              titulo: 'prueba_$marca',
              descripcion: 'categoria para el diagnostico de estadisticas',
              imagenFile: _imagenPrueba(),
            ),
          );
      expect(categoria, isA<Exito>(), reason: 'no se creo la categoria');

      RespuestaModelo deportes = await crearVmDeporte().obtenerDeportes();
      RespuestaModelo curso = await crearVmCurso().agregarCurso(
        CursoEntidad(
          nombreCurso: 'curso_$marca',
          nombreDeporte: (deportes.datos as List<String>).first,
          tituloCategoria: 'prueba_$marca',
          descripcion: 'curso para el diagnostico de estadisticas',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201, reason: 'no se creo el curso');
      final cursoCreado = curso.datos as CursoEntidad;

      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      final idInstructor = vmInstructores.instructores.first.id;

      RespuestaModelo grupo = await crearVmGrupos().insertarGrupo(
        Grupoentidad(
          categoria: cursoCreado.tituloCategoria,
          curso: cursoCreado.nombreCurso,
          anio: DateTime.now().year,
          iterable: 0,
          imagen: cursoCreado.imagen,
          cupos: 20,
          idInstructor: idInstructor,
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
          fechaInscripcionCierre: cierreInscripcionPruebas(),
          fechaInscripcionApertura: aperturaFuturaPruebas(),
        ),
      );
      expect(grupo.codigoHttp, 201, reason: 'no se creo el grupo');
      final vmLista = crearVmGrupos();
      await vmLista.listarGruposDe(
        cursoCreado.tituloCategoria,
        cursoCreado.nombreCurso,
      );
      _grupo = vmLista.getListaGrupos!.single;
      final g = _grupo!;
      await abrirInscripcionesPruebas(g);

      final vmFacultades = crearVmFacultades();
      await vmFacultades.listarYNotificarFacultades();
      final digitos = DateTime.now().millisecondsSinceEpoch.toString();
      final base = digitos.substring(digitos.length - 8);
      _alumnoA = '${base}1';
      _alumnoB = '${base}2';
      for (final id in [_alumnoA, _alumnoB]) {
        RespuestaModelo registro = await servicioAutenticacion.registro(await completarRegistro(PerfilEntidad(
            id: id,
            nombre: 'Alumno prueba $id',
            correo: 'prueba_$id@unicauca.edu.co',
            tipoId: 'CC',
            sexo: 'F',
            facultad: vmFacultades.facultades.first,
            tipoAlumno: 'Estudiante',
          )));
        expect(registro.codigoHttp, 201, reason: 'no se registro $id');
        final inscrito = await crearVmInscripcion().agregarIncripcion(
          Inscripcionentidad(
            alumnoId: id,
            categoria: g.categoria,
            curso: g.curso,
            anio: g.anio,
            iterable: g.iterable,
          ),
        );
        expect(inscrito, isA<Exito>(), reason: 'no se inscribio $id');
      }

      //como la ruta formularioClase: ayer, para no caer en el futuro del
      //backend por la zona horaria
      await sembrarHorariosSemana(g);
      final vmClase = crearVmClase();
      vmClase.inicializarGrupo(g.categoria, g.curso, g.anio, g.iterable, idInstructor);
      final clase = await vmClase.registrarClase(fecha: _ayer, horasTexto: '2');
      expect(clase, isA<Exito>(), reason: 'no se registro la clase');
      final vmDetalle = crearVmDetalle(g);
      await vmDetalle.cargarClases();
      _idClase = vmDetalle.clases.datos.single.codigo!;

      await _marcarAsistencia({_alumnoA: true});
    });
  }

  //H-06 y H-08 (en la fila de la categoria nueva)
  void prueba1AsistenciaContada(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "la clase con una asistencia cuenta 1 clase y 120 minutos en las tres secciones";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar(_dia(_ayer.subtract(const Duration(days: 30))), _dia(DateTime.now()));

      for (final fila in [
        _filaCategoria(vm),
        _filaCurso(vm),
        _filaGrupo(vm),
      ]) {
        expect(fila, isNotNull, reason: 'no aparece el grupo de prueba');
        expect(fila!.clases, 1, reason: _texto(fila));
        expect(fila.duracion, 120, reason: _texto(fila));
        expect(fila.horas, 2, reason: _texto(fila));
        expect(fila.minutos, 0, reason: _texto(fila));
      }
    });
  }

  //H-08 en toda la bd de pruebas: cada fila cuadra consigo misma y cada
  //nivel suma lo del nivel de abajo
  void prueba2TotalesCuadran(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "horas y minutos suman la duracion y cada nivel suma los de abajo";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar('2020-01-01', '2030-12-31');
      for (final s in [vm.categorias, vm.cursos, vm.grupos]) {
        expect(s.error, isNull);
      }

      for (final e in [...vm.categorias.datos, ...vm.cursos.datos, ...vm.grupos.datos]) {
        expect(e.horas * 60 + e.minutos, e.duracion, reason: _texto(e));
      }
      for (final c in vm.categorias.datos) {
        final cursos = vm.cursos.datos.where((e) => e.leyenda1 == c.leyenda1);
        expect(
          cursos.fold<double>(0, (t, e) => t + e.duracion),
          c.duracion,
          reason: 'categoria ${c.leyenda1}',
        );
      }
      for (final c in vm.cursos.datos) {
        final grupos = vm.grupos.datos.where(
          (e) => e.leyenda1 == c.leyenda1 && e.leyenda2 == c.leyenda2,
        );
        expect(
          grupos.fold<double>(0, (t, e) => t + e.duracion),
          c.duracion,
          reason: 'curso ${c.leyenda1} / ${c.leyenda2}',
        );
      }
    });
  }

  //antes diagnostico de ES-05 (2026-10-29: el ultimo dia del rango no contaba).
  //El backend nuevo compara cls_fecha con between; quedo en verde sin tocar la
  //app. No cambia datos
  void prueba3UltimoDiaDelRango(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "un rango de un solo dia incluye la clase de ese dia";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar(_dia(_ayer), _dia(_ayer));

      final fila = _filaCategoria(vm);
      expect(fila?.clases, 1, reason: fila == null ? 'sin fila' : _texto(fila));
      expect(fila?.duracion, 120);
    });
  }

  //ES-06: la consulta suma horas y minutos por separado y no pasa los minutos a
  //horas. La duracion sale bien, pero la app grafica `horas`. Crea su propio
  //grupo, con horario de 1 h 30 cada dia (el backend toma la duracion de ahi)
  void prueba7MinutosAcumulados(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "tres clases de 1 h 30 dan 4 horas y 30 minutos";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      final hoy = DateTime.now();
      final grupo = await _dio.post(
        '/grupo',
        data: {
          'categoria': g.categoria,
          'curso': g.curso,
          'anio': g.anio,
          'iterable': 0,
          'imagenGrupo': g.imagen,
          'idInstructor': g.idInstructor,
          'cupos': 5,
          'fechaCreacion': _dia(hoy),
          'fechaIncripcionCierre': cierreInscripcionPruebas(),
        },
      );
      final iterable = grupo.data['iterable'] as int;
      for (final dia in const [
        'LUNES',
        'MARTES',
        'MIERCOLES',
        'JUEVES',
        'VIERNES',
        'SABADO',
        'DOMINGO',
      ]) {
        await _dio.post(
          '/horario',
          data: {
            'categoria': g.categoria,
            'curso': g.curso,
            'anio': g.anio,
            'iterable': iterable,
            'dia': dia,
            'horaInicio': '08:00',
            'horaFin': '09:30',
            'escenario': 'Escenario prueba',
          },
        );
      }
      for (final dias in const [1, 2, 3]) {
        await _dio.post(
          '/claseGrupo',
          data: {
            'idGrupoCategoria': g.categoria,
            'idGrupoCurso': g.curso,
            'idGrupoAnio': g.anio,
            'idGrupoIterable': iterable,
            'idInstructor': g.idInstructor,
            'fecha': hoy.subtract(Duration(days: dias)).toUtc().toIso8601String(),
            'horas': 1,
            'minutos': 30,
          },
        );
      }

      final vm = crearVm();
      await vm.cargar(_dia(hoy.subtract(const Duration(days: 10))), _dia(hoy));

      final fila = vm.grupos.datos.singleWhere(
        (e) => e.leyenda1 == g.categoria && e.leyenda4 == '$iterable',
      );
      expect(fila.duracion, 270, reason: _texto(fila));
      expect(fila.horas, 4, reason: _texto(fila));
      expect(fila.minutos, 30, reason: _texto(fila));
    });
  }

  //antes diagnostico de ES-07: el 401 no trae cuerpo. La app no renueva
  //el token mientras esta abierta
  void pruebaSesionVencida(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "con el token vencido la seccion dice que paso";
    test('$capa - $tipo - $metodo - $caso', () async {
      addTearDown(actuarComoCoordinador);
      almacenPruebas.token = firmarJwtPrueba(
        correo: 'coordinador@prueba.test',
        rol: Roles.coordinador,
        perfId: 'coordinador-prueba',
        vigencia: const Duration(hours: -1),
      );
      final vm = crearVm();

      await vm.cargar(_dia(_ayer), _dia(DateTime.now()));

      final error = vm.categorias.error;
      expect(error, startsWith('Código: 401'));
      expect(error!.replaceFirst('Código: 401 -', '').trim(), isNotEmpty);
    });
  }

  //BK-02: esta clase siembra por PUT /clase/{codigo}/asistencia porque la ruta
  //que usa la app ya no existe. Este caso conserva esa evidencia: antes la daba
  //el fallo del setUpAll. Una lista vacia basta, la peticion no cambia datos
  void prueba8RegistroDesdeLaApp(Conexionatenciones Function() crearConexion) {
    String metodo = "Registrar asistencia";
    String caso = "la conexion de la app llega a una ruta que existe";
    test('$capa - $tipo - $metodo - $caso', () async {
      final respuesta = await crearConexion().registrarAtencionesClase(
        [],
        _idClase,
      );

      expect(respuesta.codigoHttp, 200, reason: '${respuesta.error?.mensaje}');
    });
  }

  //H-09
  void prueba4RangoSinLaClase(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "un rango que no incluye la clase no la cuenta";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar(
        _dia(_ayer.subtract(const Duration(days: 40))),
        _dia(_ayer.subtract(const Duration(days: 10))),
      );

      expect(vm.categorias.error, isNull);
      final fila = _filaCategoria(vm);
      expect(fila == null || fila.duracion == 0, isTrue, reason: fila == null ? '' : _texto(fila));
    });
  }

  //H-07: el backend documenta que solo inserta las asistencias que no
  //existian
  void prueba5AsistenciaRepetida(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "registrar otra vez la misma asistencia no cambia los totales";
    test('$capa - $tipo - $metodo - $caso', () async {
      await _marcarAsistencia({_alumnoA: true});
      final vm = crearVm();
      await vm.cargar(_dia(_ayer.subtract(const Duration(days: 30))), _dia(DateTime.now()));

      final fila = _filaCategoria(vm);
      expect(fila?.clases, 1, reason: fila == null ? 'sin fila' : _texto(fila));
      expect(fila?.duracion, 120);
    });
  }

  //H-12, observacion: con dos alumnos en la misma clase no esta definido si
  //se cuenta 1 clase o 2 asistencias. Solo se afirma que la fila cuadra; el
  //valor se imprime para el registro
  void prueba6DosAsistencias(EstadisticasViewModel Function() crearVm) {
    String metodo = "Estadisticas generales";
    String caso = "observacion - dos asistencias en la misma clase";
    test('$capa - $tipo - $metodo - $caso', () async {
      await _marcarAsistencia({_alumnoA: true, _alumnoB: true});
      final vm = crearVm();
      await vm.cargar(_dia(_ayer.subtract(const Duration(days: 30))), _dia(DateTime.now()));

      final fila = _filaCategoria(vm);
      expect(fila, isNotNull);
      print('H-12 dos asistencias en una clase de 2 h: ${_texto(fila!)}');
      expect(fila.horas * 60 + fila.minutos, fila.duracion);
    });
  }

  Future<void> _marcarAsistencia(Map<String, bool> marcas) async {
    //PUT /clase/{codigo}/asistencia: /asistenciasClase ya no existe (BK-02). El
    //coordinador esta exento del plazo de registro; el resto del grupo queda
    //como ausente
    final respuesta = await _dio.put(
      '/clase/$_idClase/asistencia',
      data: {
        'asistencias': [
          for (final m in marcas.entries)
            {'idPerfil': m.key, 'estaAtendido': m.value},
        ],
        'confirmaTodosAusentes': false,
      },
    );
    expect(respuesta.statusCode, 200, reason: 'no se registro la asistencia');
  }

  Estadistica? _filaCategoria(EstadisticasViewModel vm) => vm.categorias.datos
      .where((e) => e.leyenda1 == _grupoCreado().categoria)
      .firstOrNull;

  Estadistica? _filaCurso(EstadisticasViewModel vm) => vm.cursos.datos
      .where(
        (e) =>
            e.leyenda1 == _grupoCreado().categoria &&
            e.leyenda2 == _grupoCreado().curso,
      )
      .firstOrNull;

  Estadistica? _filaGrupo(EstadisticasViewModel vm) => vm.grupos.datos
      .where(
        (e) =>
            e.leyenda1 == _grupoCreado().categoria &&
            e.leyenda2 == _grupoCreado().curso &&
            e.leyenda3 == '${_grupoCreado().anio}' &&
            e.leyenda4 == '${_grupoCreado().iterable}',
      )
      .firstOrNull;

  String _texto(Estadistica e) =>
      '${e.leyenda1}/${e.leyenda2}/${e.leyenda3}/${e.leyenda4}: '
      'clases ${e.clases}, horas ${e.horas}, minutos ${e.minutos}, duracion ${e.duracion}';

  String _dia(DateTime fecha) => FormatDate.fechaACadena(fecha, '-');

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  String _marcaTiempo() =>
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
