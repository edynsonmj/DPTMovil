import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

//diagnostico del modulo 6 contra el backend real (plan-diagnostico-
//horarios.md). El setUpAll crea un grupo nuevo por corrida; las pruebas 1 a 3
//lo leen vacio. Desde el 2026-11-04 el backend tiene POST, PUT y DELETE
///horario, pero la app no (plan-diagnostico-horarios-escritura.md): las
//pruebas 4 a 6 siembran los horarios con Dio directo y comprueban que la
//cadena real de lectura los muestra. Van despues de las 1 a 3
class VmHorarioDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  Grupoentidad? _grupo;
  late Dio _dio;

  void preparar({
    required Dio dio,
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required PeriodoInscripcionViewModel Function() crearVmPeriodo,
  }) {
    _dio = dio;
    setUpAll(() async {
      final marca = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');
      expect(
        await vmCategoria.insertarCategoria(
          CategoriaEntidad(
            titulo: 'prueba_$marca',
            descripcion: 'categoria para el diagnostico de horarios',
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
          descripcion: 'curso para el diagnostico de horarios',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201);
      final c = curso.datos as CursoEntidad;
      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      final g = await crearVmGrupos().insertarGrupo(
        Grupoentidad(
          categoria: c.tituloCategoria,
          curso: c.nombreCurso,
          anio: DateTime.now().year,
          iterable: 0,
          imagen: c.imagen,
          cupos: 20,
          idInstructor: vmInstructores.instructores.first.id,
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
        ),
      );
      expect(g.codigoHttp, 201);
      final vm = crearVmPeriodo();
      await vm.cargar();
      _grupo = vm.grupos.datos.firstWhere(
        (x) => x.categoria == c.tituloCategoria && x.curso == c.nombreCurso,
      );
    });
  }

  //H-06, tarjetas de grupos asignados y de inscripcion
  void prueba1TarjetaSinHorarios(Horariosviewmodel Function() crearVm) {
    String metodo = "Cargar horarios de";
    String caso = "un grupo sin horarios deja la tarjeta vacia y sin error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargarHorariosDe([_grupoCreado()]);

      final estado = vm.horariosDe(_grupoCreado());
      expect(estado.cargando, isFalse);
      expect(estado.error, isNull);
      expect(estado.datos, isEmpty);
    });
  }

  //H-06, pantalla del grupo
  void prueba2PantallaSinHorarios(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "la seccion de horarios de un grupo nuevo queda vacia y sin error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm(_grupoCreado());
      await vm.cargar();

      expect(vm.horarios.cargando, isFalse);
      expect(vm.horarios.error, isNull);
      expect(vm.horarios.datos, isEmpty);
    });
  }

  //un grupo que no existe no debe romper la tarjeta: lista vacia o un error
  //con codigo, nunca una excepcion
  void prueba3GrupoInexistente(Horariosviewmodel Function() crearVm) {
    String metodo = "Cargar horarios de";
    String caso = "un grupo inexistente deja la tarjeta vacia o con un error con codigo";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      final inexistente = Grupoentidad(
        categoria: g.categoria,
        curso: g.curso,
        anio: g.anio,
        iterable: 999,
        cupos: 1,
        fechaCreacion: g.fechaCreacion,
      );
      final vm = crearVm();
      await vm.cargarHorariosDe([inexistente]);

      final estado = vm.horariosDe(inexistente);
      expect(estado.cargando, isFalse);
      expect(estado.datos, isEmpty);
      expect(estado.error == null || estado.error!.startsWith('Código: '), isTrue, reason: '${estado.error}');
    });
  }

  //H-10: lo que el backend guarda llega completo a las dos lecturas de la app
  void prueba4HorariosCreados(
    Horariosviewmodel Function() crearVm,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
  ) {
    String metodo = "Cargar horarios de";
    String caso = "los horarios creados en el backend llegan a la tarjeta y a la pantalla del grupo con id, dia, horas y escenario";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      final lunes = await _crear(g, {'dia': 'Lunes', 'horaInicio': '08:00', 'horaFin': '10:00', 'escenario': 'Coliseo'});
      final jueves = await _crear(g, {'dia': 'Jueves', 'horaInicio': '14:00:00', 'horaFin': '15:30:00', 'escenario': 'Piscina'});

      final vm = crearVm();
      await vm.cargarHorariosDe([g]);
      final tarjeta = vm.horariosDe(g);
      expect(tarjeta.error, isNull);
      final detalle = crearVmGrupo(g);
      await detalle.cargar();
      expect(detalle.horarios.error, isNull);

      for (final lista in [tarjeta.datos, detalle.horarios.datos]) {
        final porId = {for (final h in lista) h.id: h};
        expect(
          [porId[lunes]?.dia, porId[lunes]?.horaInicio, porId[lunes]?.horaFin, porId[lunes]?.escenario],
          ['Lunes', '08:00', '10:00', 'Coliseo'],
        );
        //el backend devuelve la hora como se envio (H-14)
        expect(
          [porId[jueves]?.dia, porId[jueves]?.horaInicio, porId[jueves]?.horaFin, porId[jueves]?.escenario],
          ['Jueves', '14:00:00', '15:30:00', 'Piscina'],
        );
      }
    });
  }

  //H-11
  void prueba5HorarioEditado(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "un horario editado en el backend se ve con sus datos nuevos";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      final id = await _crear(g, {'dia': 'Martes', 'horaInicio': '06:00', 'horaFin': '07:00', 'escenario': 'Cancha 1'});
      final r = await _dio.put(
        '/horario',
        queryParameters: {'id': id},
        data: {'dia': 'Viernes', 'horaInicio': '18:00', 'horaFin': '19:30', 'escenario': 'Cancha 2'},
      );
      expect(r.statusCode, 200);

      final vm = crearVm(g);
      await vm.cargar();

      final h = vm.horarios.datos.where((x) => x.id == id).single;
      expect([h.dia, h.horaInicio, h.horaFin, h.escenario], ['Viernes', '18:00', '19:30', 'Cancha 2']);
    });
  }

  //H-12: con las clases el DELETE no borra (CL-01)
  void prueba6HorarioEliminado(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "un horario eliminado en el backend deja de aparecer";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      final id = await _crear(g, {'dia': 'Sabado', 'horaInicio': '09:00', 'horaFin': '11:00', 'escenario': 'Coliseo'});
      final r = await _dio.delete('/horario', queryParameters: {'id': id});
      expect(r.statusCode, 200);

      final vm = crearVm(g);
      await vm.cargar();

      expect(vm.horarios.error, isNull);
      expect(vm.horarios.datos.map((x) => x.id), isNot(contains(id)));
    });
  }

  //la app no tiene como crear horarios: datos de apoyo por POST directo
  Future<int> _crear(Grupoentidad g, Map<String, String> datos) async {
    final r = await _dio.post(
      '/horario',
      queryParameters: {'categoria': g.categoria, 'curso': g.curso, 'anio': g.anio, 'iterable': g.iterable},
      data: datos,
    );
    expect(r.statusCode, 201, reason: 'no se creo el horario $datos');
    return r.data['id'] as int;
  }

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
