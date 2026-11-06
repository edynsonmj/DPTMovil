import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/routes/roles.dart';
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
import '../../jwtPruebas.dart';

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
  bool _porLimpiar = true;

  //tiempo para que BK-09 no se mezcle con lo que prueba cada caso
  static const Duration _pasaElSegundo = Duration(milliseconds: 1200);
  static const String _baseUrl = 'http://localhost:8082/api/v2';

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
            fechaInscripcionCierre: cierreInscripcionPruebas(),
            fechaInscripcionApertura: aperturaFuturaPruebas(),
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
        await abrirInscripcionesPruebas(g);
      }

      //dos alumnos con id numerico unico por corrida
      final vmFacultades = crearVmFacultades();
      await vmFacultades.listarYNotificarFacultades();
      final digitos = DateTime.now().millisecondsSinceEpoch.toString();
      final base = int.parse(digitos.substring(digitos.length - 8));
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

  //antes diagnostico de IN-13 (2026-10-29: 404 con el cuerpo vacio). El backend
  //nuevo responde 404 GC-0003 con cuerpo; este caso quedo en verde sin tocar la
  //app
  void prueba8MensajeDelRechazo(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Desvincular";
    String caso = "el rechazo trae un mensaje que la pantalla pueda mostrar";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      final resultado = await vm.desvincularInscripcion(
        _inscripcion(_alumnoB, _grupoCreado()),
      );

      expect(resultado, isA<Fallo>(), reason: _texto(resultado));
      //DialogError pinta este texto: vacio, el alumno ve un error en blanco
      expect((resultado as Fallo).mensaje.trim(), isNotEmpty, reason: _texto(resultado));
    });
  }

  //los casos siguientes son de diagnostico contra el backend nuevo: solo los
  //llama test/diagnostico/inscripciones/remoto_diagnostico_test.dart, no
  //main_test.dart. Actuan con el JWT del alumno, como la pantalla, y cada uno
  //parte de los dos alumnos fuera de sus grupos (sin depender del orden). Los
  //grupos y alumnos salen del setUpAll

  //BK-09: inscr_fechainscripcion no guarda fraccion de segundo y redondea
  //hacia arriba: una inscripcion hecha en .500 o despues queda en el segundo
  //siguiente y `fechaInscripcion <= CURRENT_TIMESTAMP` da falso hasta entonces.
  //Por eso era intermitente; aqui se fija el momento del envio
  void diagnosticoValidarTrasInscribir(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    test('$capa - diagnostico - $metodo - control BK-09 - enviada en la primera mitad del segundo, el boton queda en inscrito', () async {
      await _comoAlumno(_alumnoA);
      final vm = crearVm();
      final inscripcion = _inscripcion(_alumnoA, _grupoCreado());

      await _esperarFraccion(50, 350);
      final resultado = await vm.agregarIncripcion(inscripcion);

      expect(resultado, isA<Exito>(), reason: _texto(resultado));
      expect(vm.estadoDe(_grupoCreado()).datos, isTrue);
    });

    test('$capa - diagnostico - $metodo - BUG BK-09 - enviada en la segunda mitad del segundo, el boton queda en inscrito', () async {
      await _comoAlumno(_alumnoA);
      final vm = crearVm();
      final inscripcion = _inscripcion(_alumnoA, _grupoCreado());

      await _esperarFraccion(600, 850);
      final resultado = await vm.agregarIncripcion(inscripcion);

      expect(resultado, isA<Exito>(), reason: _texto(resultado));
      //en falso la tarjeta vuelve a Matricular, sin error (estadoDe.error null)
      expect(vm.estadoDe(_grupoCreado()).datos, isTrue);
    });
  }

  //IN-14: inscribir() reactiva por existsById sin mirar si la fila ya esta
  //activa. Con el grupo lleno entra por la rama de lista de espera y pisa el
  //estado INSCRITO. Con BK-09 el alumno ve Matricular justo despues de
  //inscribirse, asi que puede repetir desde la pantalla
  void diagnosticoRepetirConGrupoLleno(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    String caso = "BUG IN-14 - repetir con el grupo lleno no quita el cupo al alumno inscrito";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final inscripcion = _inscripcion(_alumnoA, _grupoUno());
      await _comoAlumno(_alumnoA);
      final vm = crearVm();
      expect(await vm.agregarIncripcion(inscripcion), isA<Exito>());
      await Future.delayed(_pasaElSegundo);
      expect(await vm.validarInscripcion(inscripcion), isTrue, reason: 'no quedo inscrito');

      await vm.agregarIncripcion(inscripcion);
      await Future.delayed(_pasaElSegundo);

      expect(await vm.validarInscripcion(inscripcion), isTrue);
    });
  }

  void diagnosticoRepetirYAlumnoInexistente(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    //con cupos entra por la misma rama de IN-14: responde 201 y reescribe la
    //fecha de inscripcion de una fila activa
    test('$capa - diagnostico - $metodo - BUG BK-07 - repetir la inscripcion activa es rechazado', () async {
      final inscripcion = _inscripcion(_alumnoA, _grupoCreado());
      await _comoAlumno(_alumnoA);
      final vm = crearVm();
      expect(await vm.agregarIncripcion(inscripcion), isA<Exito>());
      await Future.delayed(_pasaElSegundo);

      final segunda = await vm.agregarIncripcion(inscripcion);

      expect(segunda, isA<Fallo>(), reason: _texto(segunda));
    });

    //solo llega con rol distinto de alumno: el alumno recibe 403 antes
    test('$capa - diagnostico - $metodo - BUG BK-07 - un alumno inexistente es 404, no un 500 con la traza', () async {
      actuarComoCoordinador();
      final resultado = await crearVm().agregarIncripcion(
        _inscripcion('000000000', _grupoCreado()),
      );

      expect(resultado, isA<Fallo>(), reason: _texto(resultado));
      expect((resultado as Fallo).codigo, 404);
    });
  }

  //antes diagnostico de IN-16: fromDioException ponia la respuesta entera
  void prueba9RechazoLegible(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    String caso = "un grupo cerrado da el motivo, no el JSON de la respuesta";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      Future<void> cerrar(bool cerradas) async {
        actuarComoCoordinador();
        final r = await crearDioPruebas(_baseUrl).patch(
          '/grupo/inscripciones',
          queryParameters: {
            'categoria': g.categoria,
            'curso': g.curso,
            'anio': g.anio,
            'iterable': g.iterable,
            'cerradas': cerradas,
          },
        );
        expect(r.statusCode, 200);
      }

      await _comoAlumno(_alumnoA);
      await cerrar(true);
      addTearDown(() => cerrar(false));
      await _comoAlumno(_alumnoA);

      final resultado = await crearVm().agregarIncripcion(_inscripcion(_alumnoA, g));

      expect(resultado, isA<Fallo>(), reason: _texto(resultado));
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 422);
      expect(fallo.mensaje, contains('cerradas'));
      expect(fallo.mensaje, isNot(contains('codigoError')));
    });
  }

  //antes diagnostico de IN-17: el 401 llega sin cuerpo. La app no renueva el
  //token mientras esta abierta
  void prueba10SesionVencida(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    String caso = "con el token vencido el Fallo trae un mensaje";
    test('$capa - $tipo - $metodo - $caso', () async {
      addTearDown(actuarComoCoordinador);
      almacenPruebas.token = firmarJwtPrueba(
        correo: 'alumno@prueba.test',
        rol: Roles.alumno,
        perfId: _alumnoA,
        vigencia: const Duration(hours: -1),
      );

      final resultado = await crearVm().agregarIncripcion(
        _inscripcion(_alumnoA, _grupoCreado()),
      );

      expect(resultado, isA<Fallo>(), reason: _texto(resultado));
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 401);
      expect(fallo.mensaje.trim(), isNotEmpty);
    });
  }

  //deja a los dos alumnos fuera de los dos grupos, solo la primera vez en cada
  //caso, y actua como [id]. Los rechazos se ignoran: puede no estar inscrito
  Future<void> _comoAlumno(String id) async {
    if (_porLimpiar) {
      _porLimpiar = false;
      addTearDown(() => _porLimpiar = true);
      final dio = crearDioPruebas(_baseUrl);
      actuarComoCoordinador();
      for (final alumno in [_alumnoA, _alumnoB]) {
        for (final g in [_grupoCreado(), _grupoUno()]) {
          await dio.put(
            '/desvincularInscripcion',
            data: {
              'alumnoId': alumno,
              'categoria': g.categoria,
              'curso': g.curso,
              'anio': g.anio,
              'iterable': g.iterable,
            },
            options: Options(validateStatus: (_) => true),
          );
        }
      }
    }
    actuarComoAlumno(id);
    addTearDown(actuarComoCoordinador);
  }

  //espera a que el reloj este entre [desde] y [hasta] ms dentro del segundo.
  //El backend corre en esta maquina: el reloj es el mismo
  Future<void> _esperarFraccion(int desde, int hasta) async {
    while (true) {
      final ms = DateTime.now().millisecond;
      if (ms >= desde && ms < hasta) return;
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  //H-07: cupo. Antes del backend nuevo era un 409; ahora un grupo sin cupos
  //responde 201 con estado EN_ESPERA (nacio del diagnostico de BK-06 e IN-15)
  void prueba4CupoLleno(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Inscribir";
    String caso = "en un grupo sin cupos queda en lista de espera, la pantalla lo sabe y puede salir";
    test('$capa - $tipo - $metodo - $caso', () async {
      final grupo = _grupoUno();
      await _comoAlumno(_alumnoA);
      final primero = await crearVm().agregarIncripcion(_inscripcion(_alumnoA, grupo));
      expect(primero, isA<Exito<bool>>(), reason: _texto(primero));
      expect((primero as Exito<bool>).datos, isFalse);

      await _comoAlumno(_alumnoB);
      final vm = crearVm();
      final segundo = await vm.agregarIncripcion(_inscripcion(_alumnoB, grupo));
      expect(segundo, isA<Exito<bool>>(), reason: _texto(segundo));
      expect((segundo as Exito<bool>).datos, isTrue);
      expect(vm.enEspera(grupo), isTrue);

      //una pantalla recien abierta lo lee de /inscripcion/misCursos
      final abierta = crearVm();
      await abierta.cargarEstados(_alumnoB, [grupo]);
      expect(abierta.estadoDe(grupo).error, isNull);
      expect(abierta.enEspera(grupo), isTrue);
      expect(abierta.estadoDe(grupo).datos, isFalse);

      final salida = await abierta.desvincularInscripcion(_inscripcion(_alumnoB, grupo));
      expect(salida, isA<Exito>(), reason: _texto(salida));
      expect(abierta.enEspera(grupo), isFalse);
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

  //antes diagnostico de IN-08 (corregido 2026-11-05): el error de un
  //desvincular nombra el metodo que de verdad salio. No cambia datos
  void prueba6OrigenDelError(Inscripcionviewmodel Function() crearVm) {
    String metodo = "Desvincular";
    String caso = "el origen del Fallo nombra el metodo PUT";
    test('$capa - $tipo - $metodo - $caso', () async {
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
      //BK-09: la inscripcion de A puede ser de hace menos de un segundo
      await Future.delayed(_pasaElSegundo);
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
