import 'dart:io';

import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../datosPruebas.dart';

//diagnostico del modulo 9a contra el backend real (plan-diagnostico-
//alumnos.md): la seccion de alumnos de DetalleGrupoViewModel con su cadena
//real. El setUpAll crea por corrida un curso con tres grupos (G1, G2 y G3, con
//inscripciones abiertas) y registra tres alumnos con datos distintos: A y B
//se inscriben en G1, C en G2 y G3 queda sin alumnos
class VmAlumnoDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  final List<Grupoentidad> _grupos = [];
  final List<PerfilEntidad> _alumnos = [];

  void preparar({
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required Facultadesviewmodel Function() crearVmFacultades,
    required PeriodoInscripcionViewModel Function() crearVmPeriodo,
    required Inscripcionviewmodel Function() crearVmInscripcion,
    required Servicioautenticacion servicioAutenticacion,
  }) {
    setUpAll(() async {
      final marca = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');
      expect(
        await vmCategoria.insertarCategoria(
          CategoriaEntidad(
            titulo: 'prueba_$marca',
            descripcion: 'categoria para el diagnostico de alumnos',
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
          descripcion: 'curso para el diagnostico de alumnos',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201);
      final c = curso.datos as CursoEntidad;
      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      for (var i = 0; i < 3; i++) {
        final r = await crearVmGrupos().insertarGrupo(
          Grupoentidad(
            categoria: c.tituloCategoria,
            curso: c.nombreCurso,
            anio: DateTime.now().year,
            iterable: 0,
            imagen: c.imagen,
            cupos: 20,
            idInstructor: vmInstructores.instructores.first.id,
            fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
            fechaInscripcionCierre: cierreInscripcionPruebas(),
            fechaInscripcionApertura: aperturaFuturaPruebas(),
          ),
        );
        expect(r.codigoHttp, 201);
      }
      final vmPeriodo = crearVmPeriodo();
      await vmPeriodo.cargar();
      _grupos.addAll(
        vmPeriodo.grupos.datos
            .where((x) => x.categoria == c.tituloCategoria && x.curso == c.nombreCurso)
            .toList()
          ..sort((a, b) => a.iterable.compareTo(b.iterable)),
      );
      expect(_grupos, hasLength(3));
      for (final g in _grupos) {
        await abrirInscripcionesPruebas(g);
      }

      final vmFacultades = crearVmFacultades();
      await vmFacultades.listarYNotificarFacultades();
      final digitos = DateTime.now().millisecondsSinceEpoch.toString();
      final base = digitos.substring(digitos.length - 8);
      final datos = [
        ('1', 'F', 'CC', 'Estudiante'),
        ('2', 'M', 'TI', 'Docente'),
        ('3', 'F', 'CE', 'Administrativo'),
      ];
      for (final (sufijo, sexo, tipoId, tipoAlumno) in datos) {
        final id = '$base$sufijo';
        final perfil = PerfilEntidad(
          id: id,
          nombre: 'Alumno prueba $id',
          correo: 'prueba_$id@unicauca.edu.co',
          tipoId: tipoId,
          sexo: sexo,
          facultad: vmFacultades.facultades.first,
          tipoAlumno: tipoAlumno,
        );
        final r = await servicioAutenticacion.registro(await completarRegistro(perfil));
        expect(r.codigoHttp, 201, reason: 'no se registro $id ($tipoId, $tipoAlumno)');
        _alumnos.add(perfil);
      }
      //un vm por inscripcion, como en la app (uno por usuario): el vm recuerda
      //el estado por grupo y no deja inscribir a otro alumno en el mismo
      for (final (alumno, grupo) in [
        (_alumnos[0], _grupos[0]),
        (_alumnos[1], _grupos[0]),
        (_alumnos[2], _grupos[1]),
      ]) {
        expect(
          await crearVmInscripcion().agregarIncripcion(
            Inscripcionentidad(
              alumnoId: alumno.id,
              categoria: grupo.categoria,
              curso: grupo.curso,
              anio: grupo.anio,
              iterable: grupo.iterable,
            ),
          ),
          isA<Exito>(),
          reason: 'no se inscribio ${alumno.id}',
        );
      }
    });
  }

  //H-05 y H-06
  void prueba1AlumnosDelGrupo(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "lista solo a los alumnos del grupo con los datos con que se registraron";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm(_grupos[0]);
      await vm.cargar();

      expect(vm.alumnos.error, isNull);
      final lista = {for (final a in vm.alumnos.datos) a.id: a};
      expect(lista.keys.toSet(), {_alumnos[0].id, _alumnos[1].id});
      for (final p in _alumnos.take(2)) {
        final a = lista[p.id]!;
        expect(
          [a.nombre, a.correo, a.sexo, a.tipoid, a.tipo],
          [p.nombre, p.correo, p.sexo, p.tipoId, p.tipoAlumno],
          reason: 'alumno ${p.id}',
        );
      }

      final otro = crearVm(_grupos[1]);
      await otro.cargar();
      expect(otro.alumnos.datos.map((a) => a.id), [_alumnos[2].id]);
    });
  }

  //H-07
  void prueba2GrupoSinAlumnos(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "un grupo sin alumnos deja la seccion vacia y sin error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm(_grupos[2]);
      await vm.cargar();

      expect(vm.alumnos.cargando, isFalse);
      expect(vm.alumnos.error, isNull);
      expect(vm.alumnos.datos, isEmpty);
    });
  }

  void prueba3GrupoInexistente(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "un grupo inexistente deja la seccion vacia o con un error con codigo";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupos[0];
      final vm = crearVm(
        Grupoentidad(
          categoria: g.categoria,
          curso: g.curso,
          anio: g.anio,
          iterable: 999,
          cupos: 1,
          fechaCreacion: g.fechaCreacion,
        ),
      );
      await vm.cargar();

      expect(vm.alumnos.cargando, isFalse);
      expect(vm.alumnos.datos, isEmpty);
      expect(
        vm.alumnos.error == null || vm.alumnos.error!.startsWith('Código: '),
        isTrue,
        reason: '${vm.alumnos.error}',
      );
    });
  }

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
