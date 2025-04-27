import 'dart:convert';

import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCurso.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/presentation/view/views/curso/curso.dart';

class ConexionCursoLocal implements ConexionCurso {
  String data = '''
  [
    {
        "nombreCurso": "Futbol masculino",
        "nombreDeporte": "Futbol",
        "tituloCategoria": "Recreativo",
        "descripcion": "Nisi Lorem aliquip quis consequat. Excepteur laborum qui sit sunt proident. Labore laboris id veniam pariatur excepteur qui. Sit elit qui irure irure commodo consequat fugiat minim ea proident. Dolore incididunt enim cillum ad aliquip esse anim mollit ipsum occaecat officia fugiat enim. Ut aute dolore mollit dolore duis elit proident quis officia Lorem minim. Labore laboris reprehenderit occaecat aliqua sit ullamco ad est.",
        "imagen": null
    },
  ]''';

  final List<CursoModelo> _base = [
    CursoModelo(
      nombreCurso: 'Futbol masculino',
      nombreDeporte: 'Futbol',
      tituloCategoria: 'Deporte Recreativo',
      descripcion:
          'Ullamco duis laborum sint occaecat sit ut culpa culpa. Quis adipisicing mollit sunt minim cupidatat sit Lorem ea deserunt esse magna duis. Labore deserunt minim proident ullamco nostrud ipsum minim. Est proident mollit elit consectetur. Ipsum Lorem quis mollit ad magna in culpa sit esse.',
    ),
    CursoModelo(
      nombreCurso: 'Baloncesto femenino',
      nombreDeporte: 'Baloncesto',
      tituloCategoria: 'Deporte Recreativo',
      descripcion:
          'Ullamco duis laborum sint occaecat sit ut culpa culpa. Quis adipisicing mollit sunt minim cupidatat sit Lorem ea deserunt esse magna duis. Labore deserunt minim proident ullamco nostrud ipsum minim. Est proident mollit elit consectetur. Ipsum Lorem quis mollit ad magna in culpa sit esse.',
    ),
    CursoModelo(
      nombreCurso: 'Natacion nivel 1',
      nombreDeporte: 'Natacion',
      tituloCategoria: 'Deporte Recreativo',
      descripcion:
          'Ullamco duis laborum sint occaecat sit ut culpa culpa. Quis adipisicing mollit sunt minim cupidatat sit Lorem ea deserunt esse magna duis. Labore deserunt minim proident ullamco nostrud ipsum minim. Est proident mollit elit consectetur. Ipsum Lorem quis mollit ad magna in culpa sit esse.',
    ),
  ];

  @override
  Future<List<CursoModelo>> obtenerCursos() {
    List<dynamic> jsonData = jsonDecode(data);
    List<CursoModelo> cursos =
        jsonData.map((json) => CursoModelo.fromJson(json)).toList();
    return Future.value(cursos);
  }

  @override
  Future<RespuestaModelo> agregarCurso(CursoModelo curso) {
    // TODO: implement agregarCurso
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> eliminarCurso(CursoModelo curso) {
    // TODO: implement eliminarCurso
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> enconcontrarCursosDe(String tituloCategoria) {
    // TODO: implement enconcontrarCursosDe
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> encontrarTodosCursos() {
    if (_base.isEmpty) {
      return Future.delayed(Duration(seconds: 2), () {
        return RespuestaModelo(
          codigoHttp: 204,
          datos: _base,
          error: ErrorModelo(
            codigoHttp: 204,
            mensaje: 'No hay cursos en el sistema',
            url: 'mock/cursos',
            metodo: 'GET',
          ),
        );
      });
    }
    return Future.delayed(Duration(seconds: 2), () {
      return RespuestaModelo(codigoHttp: 200, datos: _base, error: null);
    });
  }

  @override
  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) {
    // TODO: implement obtenerCurso
    throw UnimplementedError();
  }
}
