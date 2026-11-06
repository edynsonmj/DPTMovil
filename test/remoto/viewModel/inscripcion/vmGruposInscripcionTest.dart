import 'dart:io';

import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
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
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../datosPruebas.dart';

//rutas criticas de las pantallas Grupos asignados (instructor) y Grupos de
//inscripcion (alumno). Se crea un grupo y un alumno de prueba nuevos por
//corrida; los casos dependen del orden: el ciclo de inscripcion va paso a
//paso sobre el mismo alumno y grupo
class VmGruposInscripcionTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late String _idInstructor;
  late String _idAlumno;
  Grupoentidad? _grupo;

  void preparar({
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required Facultadesviewmodel Function() crearVmFacultades,
    required Servicioautenticacion servicioAutenticacion,
  }) {
    setUpAll(() async {
      String marca = _marcaTiempo();
      Resultado<CategoriaEntidad> categoria = await vmCategoria
          .insertarCategoria(
            CategoriaEntidad(
              titulo: 'prueba_$marca',
              descripcion: 'categoria para tests de inscripcion',
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
          descripcion: 'curso para tests de inscripcion',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201, reason: 'no se creo el curso');
      final cursoCreado = curso.datos as CursoEntidad;

      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      _idInstructor = vmInstructores.instructores.first.id;

      RespuestaModelo grupo = await crearVmGrupos().insertarGrupo(
        Grupoentidad(
          categoria: cursoCreado.tituloCategoria,
          curso: cursoCreado.nombreCurso,
          anio: DateTime.now().year,
          iterable: 0,
          imagen: cursoCreado.imagen,
          cupos: 20,
          idInstructor: _idInstructor,
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

      //alumno de prueba: id numerico unico por corrida, como el formulario
      //de registro (solo digitos)
      final vmFacultades = crearVmFacultades();
      await vmFacultades.listarYNotificarFacultades();
      final digitos = DateTime.now().millisecondsSinceEpoch.toString();
      _idAlumno = digitos.substring(digitos.length - 9);
      RespuestaModelo registro = await servicioAutenticacion.registro(await completarRegistro(PerfilEntidad(
          id: _idAlumno,
          nombre: 'Alumno prueba $_idAlumno',
          correo: 'prueba_$_idAlumno@unicauca.edu.co',
          tipoId: 'CC',
          sexo: 'F',
          facultad: vmFacultades.facultades.first,
          tipoAlumno: 'Estudiante',
        )));
      expect(registro.codigoHttp, 201, reason: 'no se registro el alumno');
    });
  }

  void prueba1GruposDelInstructor(Gruposviewmodel Function() crearVm) {
    String metodo = "Listar grupos del instructor";
    String caso = "incluye el grupo recien asignado";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      final vm = crearVm();

      await vm.listarGruposInstructor(_idInstructor);

      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(
        vm.getListaGrupos!.any(
          (x) =>
              x.categoria == g.categoria &&
              x.curso == g.curso &&
              x.iterable == g.iterable,
        ),
        isTrue,
      );
    });
  }

  void prueba2GruposDisponibles(Gruposviewmodel Function() crearVm) {
    String metodo = "Listar grupos disponibles para inscripcion";
    String caso = "termina sin error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      await vm.listarGruposDisponiblesInscripcion();

      //solo se fija que la pantalla quede pintable: no se sabe de que
      //depende que un grupo este disponible
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.getListaGrupos, isNotNull);
    });
  }

  //regla del backend desde el 2026-10-29 (con los endpoints de periodo de
  //inscripcion): no se puede inscribir en un grupo cuyas inscripciones no
  //estan abiertas. El grupo recien creado nunca se abrio
  void prueba3SinInscripcionesAbiertas(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscripcion de alumno";
    String caso = "un grupo sin inscripciones abiertas responde 409 GC-0012";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      Resultado<void> inscribir = await vm.agregarIncripcion(_inscripcion());

      expect(inscribir, isA<Fallo>());
      final fallo = inscribir as Fallo;
      expect(fallo.codigo, 409);
      expect(fallo.mensaje, contains('cerradas'));
      expect(await vm.validarInscripcion(_inscripcion()), isFalse);
    });
  }

  //el ciclo del boton Matricular / Quitar matricula de la pantalla del alumno.
  //Antes de inscribir, el coordinador abre las inscripciones del grupo
  void prueba4CicloInscripcion(
    Inscripcionviewmodel Function() crearVm,
    PeriodoInscripcionViewModel Function() crearVmPeriodo,
  ) {
    String metodo = "Inscripcion de alumno";
    String caso = "abrir el grupo, validar, inscribir, validar, desvincular, validar";
    test('$capa - $tipo - $metodo - $caso', () async {
      final inscripcion = _inscripcion();
      final vm = crearVm();

      await abrirInscripcionesPruebas(_grupoCreado());
      expect(await vm.validarInscripcion(inscripcion), isFalse);

      //fase 6b (I4): inscribir y desvincular devuelven Resultado. Antes aqui
      //se leian vm.cargando, vm.error y vm.codigoInsercion == 201, y
      //desvincular devolvia el codigo 200; el Exito es ese mismo 201 / 200
      Resultado<void> inscribir = await vm.agregarIncripcion(inscripcion);
      if (inscribir is Fallo) print('error al inscribir: ${inscribir.mensaje}');
      expect(inscribir, isA<Exito>());
      expect(await vm.validarInscripcion(inscripcion), isTrue);

      expect(await vm.desvincularInscripcion(inscripcion), isA<Exito>());
      expect(await vm.validarInscripcion(inscripcion), isFalse);
    });
  }

  Inscripcionentidad _inscripcion() {
    final g = _grupoCreado();
    return Inscripcionentidad(
      alumnoId: _idAlumno,
      categoria: g.categoria,
      curso: g.curso,
      anio: g.anio,
      iterable: g.iterable,
    );
  }

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  //marca de tiempo sin separadores para que los nombres sean unicos en cada
  //corrida y seguros en la url
  String _marcaTiempo() =>
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
