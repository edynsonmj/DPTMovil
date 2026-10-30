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

//diagnostico del modulo 4 contra el backend real (plan-diagnostico-
//inscripciones.md, 4.3): Inscripcionviewmodel → servicio → repositorio →
//conexion → backend. Cada corrida crea su categoria, curso, dos grupos con
//las inscripciones abiertas (cupo 20 y cupo 1) y dos alumnos. Los casos
//dependen del orden: el estado de las inscripciones pasa de uno a otro
class VmInscripcionTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late String _alumnoA;
  late String _alumnoB;
  Grupoentidad? _grupo;
  Grupoentidad? _grupoCupoUno;

  void preparar({
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required Facultadesviewmodel Function() crearVmFacultades,
    required PeriodoInscripcionViewModel Function() crearVmPeriodo,
    required Servicioautenticacion servicioAutenticacion,
  }) {
    setUpAll(() async {
      String marca = _marcaTiempo();
      Resultado<CategoriaEntidad> categoria = await vmCategoria
          .insertarCategoria(
            CategoriaEntidad(
              titulo: 'prueba_$marca',
              descripcion: 'categoria para el diagnostico de inscripciones',
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
          descripcion: 'curso para el diagnostico de inscripciones',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201, reason: 'no se creo el curso');
      final cursoCreado = curso.datos as CursoEntidad;

      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      final idInstructor = vmInstructores.instructores.first.id;

      for (final cupos in [20, 1]) {
        RespuestaModelo grupo = await crearVmGrupos().insertarGrupo(
          Grupoentidad(
            categoria: cursoCreado.tituloCategoria,
            curso: cursoCreado.nombreCurso,
            anio: DateTime.now().year,
            iterable: 0,
            imagen: cursoCreado.imagen,
            cupos: cupos,
            idInstructor: idInstructor,
            fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
          ),
        );
        expect(grupo.codigoHttp, 201, reason: 'no se creo el grupo de $cupos');
      }
      final vmLista = crearVmGrupos();
      await vmLista.listarGruposDe(
        cursoCreado.tituloCategoria,
        cursoCreado.nombreCurso,
      );
      final grupos = vmLista.getListaGrupos!;
      expect(grupos, hasLength(2), reason: 'se esperaban los dos grupos');
      _grupo = grupos.firstWhere((g) => g.cupos == 20);
      _grupoCupoUno = grupos.firstWhere((g) => g.cupos == 1);
      for (final g in grupos) {
        expect(
          await crearVmPeriodo().abrir(g),
          isA<Exito>(),
          reason: 'no se abrieron las inscripciones de ${g.clave}',
        );
      }

      //dos alumnos con id numerico unico por corrida
      final vmFacultades = crearVmFacultades();
      await vmFacultades.listarYNotificarFacultades();
      final digitos = DateTime.now().millisecondsSinceEpoch.toString();
      final base = int.parse(digitos.substring(digitos.length - 8));
      _alumnoA = '${base}1';
      _alumnoB = '${base}2';
      for (final id in [_alumnoA, _alumnoB]) {
        RespuestaModelo registro = await servicioAutenticacion.registro(
          PerfilEntidad(
            id: id,
            nombre: 'Alumno prueba $id',
            correo: 'prueba_$id@unicauca.edu.co',
            tipoId: 'CC',
            sexo: 'F',
            facultad: vmFacultades.facultades.first,
            tipoAlumno: 'Estudiante',
          ),
        );
        expect(registro.codigoHttp, 201, reason: 'no se registro el alumno $id');
      }
    });
  }

  //H-07: el mismo alumno dos veces en el mismo grupo
  void prueba1InscribirDosVeces(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    String caso = "la segunda inscripcion del mismo alumno es Fallo 409";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      final inscripcion = _inscripcion(_alumnoA, _grupoCreado());

      final primera = await vm.agregarIncripcion(inscripcion);
      expect(primera, isA<Exito>(), reason: _texto(primera));
      expect(await vm.validarInscripcion(inscripcion), isTrue);

      final segunda = await vm.agregarIncripcion(inscripcion);
      expect(segunda, isA<Fallo>(), reason: _texto(segunda));
      expect((segunda as Fallo).codigo, 409);
      expect(await vm.validarInscripcion(inscripcion), isTrue);
    });
  }

  //H-08: el backend documenta que POST /inscripcion reactiva una inscripcion
  //desvinculada
  void prueba2DesvincularYReactivar(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Desvincular e inscribir otra vez";
    String caso = "la inscripcion se reactiva";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      final inscripcion = _inscripcion(_alumnoA, _grupoCreado());

      final baja = await vm.desvincularInscripcion(inscripcion);
      expect(baja, isA<Exito>(), reason: _texto(baja));
      expect(await vm.validarInscripcion(inscripcion), isFalse);

      final alta = await vm.agregarIncripcion(inscripcion);
      expect(alta, isA<Exito>(), reason: _texto(alta));
      expect(await vm.validarInscripcion(inscripcion), isTrue);

      //deja al alumno A fuera del grupo para el caso siguiente
      expect(await vm.desvincularInscripcion(inscripcion), isA<Exito>());
    });
  }

  //H-06
  void prueba3DesvincularSinInscripcion(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Desvincular";
    String caso = "un alumno que no esta inscrito es Fallo";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      //el alumno B nunca se inscribio en el grupo de cupo 20
      final inscripcion = _inscripcion(_alumnoB, _grupoCreado());
      expect(await vm.validarInscripcion(inscripcion), isFalse);

      final resultado = await vm.desvincularInscripcion(inscripcion);

      //un Exito haria que la pantalla diga "Se quito tu matricula del grupo"
      expect(resultado, isA<Fallo>(), reason: _texto(resultado));
    });
  }

  //los dos casos siguientes salen rojos: son de diagnostico y solo los llama
  //test/diagnostico/inscripciones/remoto_diagnostico_test.dart, no
  //main_test.dart. Necesitan el setUpAll de esta clase, pero no el estado de
  //los demas casos

  //IN-13: el backend responde 404 con el cuerpo vacio y el vm arma el Fallo
  //con ese cuerpo como mensaje
  void diagnosticoMensajeDelRechazo(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Desvincular";
    String caso = "BUG IN-13 - el rechazo trae un mensaje que la pantalla pueda mostrar";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final vm = crearVm();

      final resultado = await vm.desvincularInscripcion(
        _inscripcion(_alumnoB, _grupoCreado()),
      );

      expect(resultado, isA<Fallo>(), reason: _texto(resultado));
      //DialogError pinta este texto: vacio, el alumno ve un error en blanco
      expect((resultado as Fallo).mensaje.trim(), isNotEmpty, reason: _texto(resultado));
    });
  }

  //H-07: cupo
  void prueba4CupoLleno(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    String caso = "en un grupo sin cupos es Fallo 409";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      final grupo = _grupoUno();

      final primero = await vm.agregarIncripcion(_inscripcion(_alumnoA, grupo));
      expect(primero, isA<Exito>(), reason: _texto(primero));

      final segundo = await vm.agregarIncripcion(_inscripcion(_alumnoB, grupo));
      expect(segundo, isA<Fallo>(), reason: _texto(segundo));
      expect((segundo as Fallo).codigo, 409);
      expect(await vm.validarInscripcion(_inscripcion(_alumnoB, grupo)), isFalse);
    });
  }

  //H-09
  void prueba5Inexistentes(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    String caso = "un alumno o un grupo que no existen es Fallo 404";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      final g = _grupoCreado();

      final sinAlumno = await vm.agregarIncripcion(
        _inscripcion('000000000', g),
      );
      expect(sinAlumno, isA<Fallo>(), reason: _texto(sinAlumno));
      expect((sinAlumno as Fallo).codigo, 404);

      final sinGrupo = await vm.agregarIncripcion(
        Inscripcionentidad(
          alumnoId: _alumnoB,
          categoria: g.categoria,
          curso: g.curso,
          anio: g.anio,
          iterable: 999,
        ),
      );
      expect(sinGrupo, isA<Fallo>(), reason: _texto(sinGrupo));
      expect((sinGrupo as Fallo).codigo, 404);
    });
  }

  //IN-08 contra el backend: el error de un desvincular debe nombrar el metodo
  //que de verdad salio
  void diagnosticoOrigenDelError(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Desvincular";
    String caso = "BUG IN-08 - el origen del Fallo nombra el metodo PUT";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final vm = crearVm();
      final g = _grupoCreado();

      final resultado = await vm.desvincularInscripcion(
        Inscripcionentidad(
          alumnoId: _alumnoB,
          categoria: g.categoria,
          curso: g.curso,
          anio: g.anio,
          iterable: 999,
        ),
      );

      expect(resultado, isA<Fallo>(), reason: _texto(resultado));
      expect((resultado as Fallo).origen, startsWith('PUT '));
    });
  }

  //la carga de la pantalla del alumno con lo que dejaron los casos anteriores:
  //A esta en el grupo de cupo 1 y no en el de cupo 20
  void prueba7CargarEstados(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Cargar estados";
    String caso = "pinta inscrito donde el backend dice que lo esta";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      await vm.cargarEstados(_alumnoA, [_grupoCreado(), _grupoUno()]);

      expect(vm.estadoDe(_grupoCreado()).cargando, isFalse);
      expect(vm.estadoDe(_grupoCreado()).datos, isFalse);
      expect(vm.estadoDe(_grupoUno()).datos, isTrue);
    });
  }

  Inscripcionentidad _inscripcion(String alumnoId, Grupoentidad g) =>
      Inscripcionentidad(
        alumnoId: alumnoId,
        categoria: g.categoria,
        curso: g.curso,
        anio: g.anio,
        iterable: g.iterable,
      );

  String _texto(Resultado<void> r) => switch (r) {
    Exito() => 'Exito',
    Fallo(:final codigo, :final mensaje, :final origen) =>
      'Fallo $codigo $mensaje ($origen)',
  };

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  Grupoentidad _grupoUno() {
    expect(_grupoCupoUno, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupoCupoUno!;
  }

  String _marcaTiempo() =>
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
