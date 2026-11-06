import 'dart:io';

import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../datosPruebas.dart';

//ruta critica del modulo grupo: crear un grupo (formulario de grupo) y lo
//que muestra su pantalla (horarios, alumnos, clases), mas registrar y
//eliminar una clase. Cada caso construye su vm, como cada ruta, pero
//dependen del orden: el grupo que crea el segundo es el que usan los demas
class VmModuloGrupoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late CategoriaEntidad _categoria;
  late CursoEntidad _curso;
  late String _idInstructor;
  Grupoentidad? _grupo;

  //categoria y curso nuevos por corrida, y el primer instructor de la bd
  void preparar(
    CategoriaViewModel vmCategoria,
    Deporteviewmodel Function() crearVmDeporte,
    CursosViewModel Function() crearVmCurso,
    InstructoresViewModel Function() crearVmInstructores,
  ) {
    setUpAll(() async {
      String marca = _marcaTiempo();
      Resultado<CategoriaEntidad> categoria = await vmCategoria
          .insertarCategoria(
            CategoriaEntidad(
              titulo: 'prueba_$marca',
              descripcion: 'categoria para tests de grupo',
              imagenFile: _imagenPrueba(),
            ),
          );
      expect(categoria, isA<Exito>(), reason: 'no se creo la categoria');
      _categoria = CategoriaEntidad(
        titulo: 'prueba_$marca',
        descripcion: 'categoria para tests de grupo',
      );

      RespuestaModelo deportes = await crearVmDeporte().obtenerDeportes();
      expect(deportes.codigoHttp, 200, reason: 'no hay deportes');
      RespuestaModelo curso = await crearVmCurso().agregarCurso(
        CursoEntidad(
          nombreCurso: 'curso_$marca',
          nombreDeporte: (deportes.datos as List<String>).first,
          tituloCategoria: _categoria.titulo,
          descripcion: 'curso para tests de grupo',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201, reason: 'no se creo el curso');
      _curso = curso.datos as CursoEntidad;

      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      expect(vmInstructores.instructores, isNotEmpty, reason: 'sin instructores');
      _idInstructor = vmInstructores.instructores.first.id;
    });
  }

  void prueba1ListarInstructores(InstructoresViewModel Function() crearVm) {
    String metodo = "Listar instructores";
    String caso = "carga la lista sin error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      await vm.listarYNotificarInstructores();

      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      //el desplegable del formulario de grupo usa id y nombre
      expect(vm.instructores, isNotEmpty);
      expect(vm.instructores.every((i) => i.id.isNotEmpty), isTrue);
    });
  }

  void prueba2InsertarGrupo201(Gruposviewmodel Function() crearVm) {
    String metodo = "Insertar grupo";
    String caso = "201 y aparece en los grupos del curso";
    test('$capa - $tipo - $metodo - $caso', () async {
      //lo mismo que arma GrupoFormulario al guardar
      RespuestaModelo respuesta = await crearVm().insertarGrupo(
        Grupoentidad(
          categoria: _curso.tituloCategoria,
          curso: _curso.nombreCurso,
          anio: DateTime.now().year,
          iterable: 0,
          imagen: _curso.imagen,
          cupos: 20,
          idInstructor: _idInstructor,
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
          fechaInscripcionCierre: cierreInscripcionPruebas(),
          fechaInscripcionApertura: aperturaFuturaPruebas(),
        ),
      );
      _imprimirError(respuesta);
      expect(respuesta.codigoHttp, 201);

      //vm nuevo, como la pantalla del curso al volver con pop(true)
      final vmLista = crearVm();
      await vmLista.listarGruposDe(_curso.tituloCategoria, _curso.nombreCurso);

      expect(vmLista.cargando, isFalse);
      expect(vmLista.error, isNull);
      expect(vmLista.getListaGrupos, hasLength(1));
      _grupo = vmLista.getListaGrupos!.single;
      expect(_grupo!.idInstructor, _idInstructor);
      expect(_grupo!.cupos, 20);
    });
  }

  //un grupo recien creado no tiene horarios. A diferencia de alumnos y
  //clases, /horarios responde 200 con una lista vacia, no un objeto
  void prueba3HorariosGrupoNuevo(Horariosviewmodel Function() crearVm) {
    String metodo = "Listar horarios de grupo";
    String caso = "grupo nuevo responde 200 con lista vacia";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();

      RespuestaModelo respuesta = await crearVm().listarHorariosGrupo(
        g.categoria,
        g.curso,
        g.anio,
        g.iterable,
      );
      _imprimirError(respuesta);

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List>());
      expect(respuesta.datos, isEmpty);
    });
  }

  //alumnos si responde 200 con un objeto (GC-0002 "listado vacio") y la
  //conexion lo devuelve como 406
  void prueba4AlumnosGrupoNuevo(Alumnosviewmodel Function() crearVm) {
    String metodo = "Listar alumnos de grupo";
    String caso = "grupo nuevo responde 406";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();

      RespuestaModelo respuesta = await crearVm().listarAlumnosGrupo(
        g.categoria,
        g.curso,
        g.anio,
        g.iterable,
      );
      _imprimirError(respuesta);

      expect(respuesta.codigoHttp, 406);
    });
  }

  //la pantalla de un grupo recien creado: con F5 (fase 4c) alumnos y clases
  //vacios (406 de la conexion) se muestran como listas vacias, no como error
  void prueba4bPantallaGrupoNuevo(
    DetalleGrupoViewModel Function(Grupoentidad) crearVm,
  ) {
    String metodo = "Cargar pantalla de grupo";
    String caso = "grupo nuevo carga sin errores";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm(_grupoCreado());

      await vm.cargar();

      expect(vm.curso.cargando, isFalse);
      expect(vm.curso.error, isNull);
      expect(vm.curso.datos?.nombreCurso, _curso.nombreCurso);
      for (final seccion in [vm.horarios, vm.alumnos, vm.clases]) {
        expect(seccion.cargando, isFalse);
        expect(seccion.error, isNull);
        expect(seccion.datos, isEmpty);
      }
    });
  }

  //desde la fase 4c el formulario registra y la pantalla del grupo, con su
  //propio vm, es la que vuelve a pedir la lista
  void prueba5RegistrarClase201(
    Clasesviewmodel Function() crearVmFormulario,
    DetalleGrupoViewModel Function(Grupoentidad) crearVmGrupo,
  ) {
    String metodo = "Registrar clase";
    String caso = "exito 201 y la clase queda en la lista";
    test('$capa - $tipo - $metodo - $caso', () async {
      final g = _grupoCreado();
      await sembrarHorariosSemana(g);
      //como la ruta formularioClase: el vm se inicializa con el grupo
      final vm = crearVmFormulario();
      vm.inicializarGrupo(g.categoria, g.curso, g.anio, g.iterable, g.idInstructor!);

      //ayer: con el reloj del dispositivo, "hoy" puede quedar en el futuro
      //para el backend segun la zona horaria
      Resultado<void> resultado = await vm.registrarClase(
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        horasTexto: '2',
      );
      if (resultado is Fallo) print('fallo: ${resultado.mensaje}');
      expect(resultado, isA<Exito>());

      //la pantalla del grupo recarga al volver con true
      final vmGrupo = crearVmGrupo(g);
      await vmGrupo.cargarClases();
      expect(vmGrupo.clases.cargando, isFalse);
      expect(vmGrupo.clases.datos, hasLength(1));
      expect(vmGrupo.clases.datos.single.horas, 2);
      expect(vmGrupo.clases.datos.single.codigo, isNotNull);
    });
  }

  //se fija solo la respuesta. Visto el 2026-10-21: DELETE /clase?id=X de una
  //clase existente responde 200 sin cuerpo, pero /clasesGrupo la sigue
  //devolviendo con eliminado 0 (el parametro es id: sin el, 400). Es del
  //backend; cuando se corrija, agregar aqui que la lista quede vacia
  void prueba6EliminarClase200(
    DetalleGrupoViewModel Function(Grupoentidad) crearVm,
  ) {
    String metodo = "Eliminar clase";
    String caso = "clase existente responde 200";
    test('$capa - $tipo - $metodo - $caso', () async {
      //vm nuevo, como la pantalla del grupo al entrar
      final vm = crearVm(_grupoCreado());
      await vm.cargarClases();
      expect(vm.clases.datos, hasLength(1), reason: 'falta la clase del caso 5');

      Resultado<void> resultado = await vm.eliminarClase(
        vm.clases.datos.single.codigo!,
      );
      if (resultado is Fallo) print('fallo: ${resultado.mensaje}');

      //el 200 es lo que devuelve Exito
      expect(resultado, isA<Exito>());
    });
  }

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el caso 2 no creo el grupo');
    return _grupo!;
  }

  void _imprimirError(RespuestaModelo respuesta) {
    if (respuesta.error != null) {
      print('codigo: ${respuesta.codigoHttp}');
      print('error mensaje: ${respuesta.error!.mensaje}');
    }
  }

  //marca de tiempo sin separadores para que los nombres sean unicos en cada
  //corrida y seguros en la url
  String _marcaTiempo() =>
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
