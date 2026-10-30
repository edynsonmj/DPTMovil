import 'dart:io';

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
//horarios.md). El backend no tiene ninguna ruta para crear horarios y la bd
//de pruebas no tiene ninguno (2026-10-29): solo se puede comprobar la lectura
//vacia. El setUpAll crea un grupo nuevo por corrida
class VmHorarioDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  Grupoentidad? _grupo;

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

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
