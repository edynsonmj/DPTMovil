import 'dart:io';

import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

//abrir, programar y cerrar las inscripciones de un grupo contra el backend
//real (plan de abrir inscripciones, fase 5). Se crea un grupo propio por
//corrida y los casos van en orden sobre el. La categoria lleva espacio y
//tilde: la llave del grupo viaja codificada en la query y el backend debe
//encontrar el grupo igual. "Inscribible" = aparece en GET /gruposInscripcion
class VmPeriodoInscripcionTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Periodo de inscripcion";

  Grupoentidad? _grupo;

  final DateTime _hoy = _soloFecha(DateTime.now());

  void preparar({
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required PeriodoInscripcionViewModel Function() crearVm,
  }) {
    setUpAll(() async {
      String marca = _marcaTiempo();
      String categoria = 'prueba_$marca Educación física';
      Resultado<CategoriaEntidad> creada = await vmCategoria.insertarCategoria(
        CategoriaEntidad(
          titulo: categoria,
          descripcion: 'categoria para tests de periodo de inscripcion',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(creada, isA<Exito>(), reason: 'no se creo la categoria');

      RespuestaModelo deportes = await crearVmDeporte().obtenerDeportes();
      RespuestaModelo curso = await crearVmCurso().agregarCurso(
        CursoEntidad(
          nombreCurso: 'curso_$marca',
          nombreDeporte: (deportes.datos as List<String>).first,
          tituloCategoria: categoria,
          descripcion: 'curso para tests de periodo de inscripcion',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201, reason: 'no se creo el curso');
      final cursoCreado = curso.datos as CursoEntidad;

      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();

      RespuestaModelo grupo = await crearVmGrupos().insertarGrupo(
        Grupoentidad(
          categoria: cursoCreado.tituloCategoria,
          curso: cursoCreado.nombreCurso,
          anio: DateTime.now().year,
          iterable: 0,
          imagen: cursoCreado.imagen,
          cupos: 20,
          idInstructor: vmInstructores.instructores.first.id,
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
        ),
      );
      expect(grupo.codigoHttp, 201, reason: 'no se creo el grupo');

      //el iterable lo asigna el backend: se busca el grupo en la lista del
      //coordinador, que es justo la que usa la pantalla
      final vm = crearVm();
      await vm.cargar();
      expect(vm.grupos.error, isNull, reason: 'no se cargaron los grupos');
      _grupo = vm.grupos.datos.singleWhere(
        (g) =>
            g.categoria == cursoCreado.tituloCategoria &&
            g.curso == cursoCreado.nombreCurso,
      );
    });
  }

  void prueba1GrupoNuevoSinPeriodo(
    PeriodoInscripcionViewModel Function() crearVm,
    Gruposviewmodel Function() crearVmGrupos,
  ) {
    String caso = "un grupo nuevo no tiene periodo ni es inscribible";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      expect(await _estadoEnBackend(vm), EstadoInscripcion.sinPeriodo);
      expect(await _inscribible(crearVmGrupos()), isFalse);
    });
  }

  void prueba2AbrirDesdeHoy(
    PeriodoInscripcionViewModel Function() crearVm,
    Gruposviewmodel Function() crearVmGrupos,
  ) {
    String caso = "abrir sin fechas lo abre desde hoy y sin limite";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      final resultado = await vm.abrir(_grupoCreado());
      _imprimir(resultado);

      expect(resultado, isA<Exito<Grupoentidad>>());
      final grupo = (resultado as Exito<Grupoentidad>).datos!;
      expect(grupo.fechaInscripcionApertura, _texto(_hoy));
      expect(grupo.fechaInscripcionCierre, isNull);
      expect(await _estadoEnBackend(vm), EstadoInscripcion.abierta);
      expect(await _inscribible(crearVmGrupos()), isTrue);
    });
  }

  void prueba3CierreHoy(
    PeriodoInscripcionViewModel Function() crearVm,
    Gruposviewmodel Function() crearVmGrupos,
  ) {
    String caso = "con el cierre hoy sigue siendo inscribible";
    test('$capa - $tipo - $metodo - $caso', () async {
      //confirma la regla que la app infirio: el dia del cierre cuenta
      final vm = crearVm();

      final resultado = await vm.abrir(_grupoCreado(), apertura: _hoy, cierre: _hoy);
      _imprimir(resultado);

      expect(resultado, isA<Exito<Grupoentidad>>());
      expect(await _estadoEnBackend(vm), EstadoInscripcion.abierta);
      expect(await _inscribible(crearVmGrupos()), isTrue);
    });
  }

  void prueba4Programar(
    PeriodoInscripcionViewModel Function() crearVm,
    Gruposviewmodel Function() crearVmGrupos,
  ) {
    String caso = "una apertura futura queda programada y no es inscribible";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      final apertura = _hoy.add(const Duration(days: 10));
      final cierre = _hoy.add(const Duration(days: 20));

      final resultado = await vm.abrir(
        _grupoCreado(),
        apertura: apertura,
        cierre: cierre,
      );
      _imprimir(resultado);

      expect(resultado, isA<Exito<Grupoentidad>>());
      final grupo = (resultado as Exito<Grupoentidad>).datos!;
      expect(grupo.fechaInscripcionApertura, _texto(apertura));
      expect(grupo.fechaInscripcionCierre, _texto(cierre));
      expect(await _estadoEnBackend(vm), EstadoInscripcion.programada);
      expect(await _inscribible(crearVmGrupos()), isFalse);
    });
  }

  void prueba5CierreAntesDeApertura(
    PeriodoInscripcionViewModel Function() crearVm,
  ) {
    String caso = "un cierre anterior a la apertura es 400 y no cambia nada";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      final resultado = await vm.abrir(
        _grupoCreado(),
        apertura: _hoy.add(const Duration(days: 10)),
        cierre: _hoy.add(const Duration(days: 5)),
      );
      _imprimir(resultado);

      expect(resultado, isA<Fallo>());
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 400);
      expect(fallo.mensaje, contains('cierreValido'));
      //sigue programado como lo dejo el caso anterior
      expect(await _estadoEnBackend(vm), EstadoInscripcion.programada);
    });
  }

  void prueba6Cerrar(
    PeriodoInscripcionViewModel Function() crearVm,
    Gruposviewmodel Function() crearVmGrupos,
  ) {
    String caso = "cerrar lo deja cerrado y no inscribible";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      final resultado = await vm.cerrar(_grupoCreado());
      _imprimir(resultado);

      expect(resultado, isA<Exito<Grupoentidad>>());
      expect(await _estadoEnBackend(vm), EstadoInscripcion.cerrada);
      expect(await _inscribible(crearVmGrupos()), isFalse);
    });
  }

  void prueba7GrupoInexistente(PeriodoInscripcionViewModel Function() crearVm) {
    String caso = "cerrar un grupo inexistente es 404";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      final vm = crearVm();

      final resultado = await vm.cerrar(
        Grupoentidad(
          categoria: g.categoria,
          curso: g.curso,
          anio: g.anio,
          iterable: g.iterable + 100,
          cupos: g.cupos,
          fechaCreacion: g.fechaCreacion,
        ),
      );
      _imprimir(resultado);

      expect(resultado, isA<Fallo>());
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 404);
      expect(fallo.mensaje, contains('GC-0003'));
    });
  }

  //el estado tal como lo vuelve a leer la pantalla del coordinador
  Future<EstadoInscripcion> _estadoEnBackend(
    PeriodoInscripcionViewModel vm,
  ) async {
    await vm.cargar();
    expect(vm.grupos.error, isNull);
    final g = vm.grupos.datos.singleWhere((x) => x.clave == _grupoCreado().clave);
    return vm.estadoDe(g);
  }

  //lo que vera el alumno en su pantalla de inscripcion
  Future<bool> _inscribible(Gruposviewmodel vm) async {
    await vm.listarGruposDisponiblesInscripcion();
    expect(vm.error, isNull);
    return vm.getListaGrupos!.any((x) => x.clave == _grupoCreado().clave);
  }

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  void _imprimir(Resultado resultado) {
    if (resultado is Fallo) {
      print('codigo: ${resultado.codigo}');
      print('error mensaje: ${resultado.mensaje}');
      print('error origen: ${resultado.origen}');
    }
  }

  static DateTime _soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  String _texto(DateTime fecha) => FormatDate.fechaACadena(fecha, '-');

  //marca de tiempo sin separadores para que los nombres sean unicos en cada
  //corrida
  String _marcaTiempo() =>
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
