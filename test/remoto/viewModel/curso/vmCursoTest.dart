import 'dart:io';

import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

//ruta critica de cursos: agregar (formulario), listar los de una categoria
//(cursos) y obtener uno (grupo). Cada caso construye su vm, como cada
//ruta, pero los tres dependen del orden: el curso que agrega el primero es
//el que buscan los otros dos
class VmCursoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late CategoriaEntidad _categoria;
  late String _deporte;
  late String _nombreCurso;

  //categoria nueva por corrida, con un curso propio, para que la lista del
  //caso 2 no dependa de lo que ya haya en la BD
  void preparar(
    CategoriaViewModel vmCategoria,
    Deporteviewmodel Function() crearVmDeporte,
  ) {
    setUpAll(() async {
      String marca = _marcaTiempo();
      Resultado<CategoriaEntidad> resultado = await vmCategoria
          .insertarCategoria(
            CategoriaEntidad(
              titulo: 'prueba_$marca',
              descripcion: 'categoria para tests de curso',
              imagenFile: _imagenPrueba(),
            ),
          );
      expect(resultado, isA<Exito>(), reason: 'no se creo la categoria');
      _categoria = CategoriaEntidad(
        titulo: 'prueba_$marca',
        descripcion: 'categoria para tests de curso',
      );
      RespuestaModelo deportes = await crearVmDeporte().obtenerDeportes();
      expect(deportes.codigoHttp, 200, reason: 'no hay deportes');
      _deporte = (deportes.datos as List<String>).first;
      _nombreCurso = 'curso_$marca';
    });
  }

  void prueba1Agregar201(CursosViewModel Function() crearVm) {
    String metodo = "Agregar curso";
    String caso = "201 devuelve entidad";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      //dos peticiones: POST /imagenMultipart y luego POST /curso
      RespuestaModelo respuesta = await vm.agregarCurso(
        CursoEntidad(
          nombreCurso: _nombreCurso,
          nombreDeporte: _deporte,
          tituloCategoria: _categoria.titulo,
          descripcion: 'test de caracterizacion',
          imagenFile: _imagenPrueba(),
        ),
      );
      _imprimirError(respuesta);

      expect(respuesta.codigoHttp, 201);
      expect(respuesta.datos, isA<CursoEntidad>());
      final curso = respuesta.datos as CursoEntidad;
      expect(curso.nombreCurso, _nombreCurso);
      expect(curso.tituloCategoria, _categoria.titulo);
      //el id de la imagen subida queda en el curso creado
      expect(curso.imagen, isNotNull);
    });
  }

  void prueba2ListarCursosDe(CursosViewModel Function() crearVm) {
    String metodo = "Listar cursos de";
    String caso = "200 carga la lista y las entradas";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      //un error deja la lista vacia y vuelve como Fallo: se exige el Exito
      expect(await vm.listarCursosDe(_categoria), isA<Exito<void>>());

      expect(vm.getListaCursos, isNotNull);
      expect(
        vm.getListaCursos!.map((c) => c.nombreCurso),
        contains(_nombreCurso),
      );
      expect(
        vm.getListaCursos!.every((c) => c.tituloCategoria == _categoria.titulo),
        isTrue,
      );
      //el desplegable de cursos.dart sale de la misma lista
      expect(
        vm.nombresCursos,
        contains(_nombreCurso),
      );
      expect(vm.nombresCursos.length, vm.getListaCursos!.length);
    });
  }

  void prueba3ObtenerCurso(CursosViewModel Function() crearVm) {
    String metodo = "Obtener curso";
    String caso = "200 devuelve entidad";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      RespuestaModelo respuesta = await vm.obtenerCurso(
        _categoria.titulo,
        _nombreCurso,
      );
      _imprimirError(respuesta);

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<CursoEntidad>());
      final curso = respuesta.datos as CursoEntidad;
      expect(curso.nombreCurso, _nombreCurso);
      expect(curso.nombreDeporte, _deporte);
      expect(curso.imagen, isNotNull);
    });
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
