import 'dart:io';

import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCursoFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 3: estos
//casos deben pasar igual antes y despues de migrar cursos
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionCursoFalsa conexion;
  late CursoRepositorio repositorio;

  CursoModelo modelo(String nombre, {int? imagen}) => CursoModelo(
    nombreCurso: nombre,
    nombreDeporte: 'Futbol',
    tituloCategoria: 'Deportes',
    descripcion: 'Desc $nombre',
    imagen: imagen,
  );

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexionCursoFalsa();
    repositorio = CursoRepositorio(cliente: conexion);
  });

  group('Cursos (repositorio con doble):', () {
    test('$capa - $tipo - Listar cursos de - 200 convierte a entidades', () async {
      conexion.respuestaCursosDe = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo('Iniciacion', imagen: 7), modelo('Avanzado')],
      );

      final respuesta = await repositorio.listarCursosDe(
        CategoriaEntidad(titulo: 'Deportes', descripcion: 'x'),
      );

      //la conexion recibe el titulo de la categoria
      expect(conexion.ultimaCategoria, 'Deportes');
      expect(respuesta.codigoHttp, 200);
      //ningun modelo sale de la capa de datos
      expect(respuesta.datos, isA<List<CursoEntidad>>());
      final lista = respuesta.datos as List<CursoEntidad>;
      expect(lista.map((c) => c.nombreCurso), ['Iniciacion', 'Avanzado']);
      expect(lista[0].nombreDeporte, 'Futbol');
      expect(lista[0].descripcion, 'Desc Iniciacion');
      expect(lista[0].imagen, 7);
      expect(lista[1].imagen, isNull);
    });

    test('$capa - $tipo - Listar cursos de - 406 pasa sin cambios', () async {
      //la conexion responde 406 cuando el backend manda 200 sin lista
      //(categoria sin cursos)
      final sinLista = RespuestaModelo(codigoHttp: 406);
      conexion.respuestaCursosDe = sinLista;

      final respuesta = await repositorio.listarCursosDe(
        CategoriaEntidad(titulo: 'Deportes', descripcion: 'x'),
      );

      expect(respuesta, same(sinLista));
      expect(respuesta.codigoHttp, 406);
    });

    test('$capa - $tipo - Guardar curso - 201 devuelve entidad', () async {
      conexion.respuestaAgregar = RespuestaModelo(
        codigoHttp: 201,
        datos: modelo('Iniciacion', imagen: 9),
      );
      final archivo = File('assets/images/1.jpg');

      final respuesta = await repositorio.guardaCurso(
        CursoEntidad(
          nombreCurso: 'Iniciacion',
          nombreDeporte: 'Futbol',
          tituloCategoria: 'Deportes',
          descripcion: 'Desc Iniciacion',
          imagenFile: archivo,
        ),
      );

      //la peticion llego armada a la conexion, con el archivo que sube
      //la imagen antes del POST /curso
      expect(conexion.llamadasAgregar, 1);
      expect(conexion.ultimoAgregado?.nombreCurso, 'Iniciacion');
      expect(conexion.ultimoAgregado?.tituloCategoria, 'Deportes');
      expect(conexion.ultimoAgregado?.imagenFile, same(archivo));
      expect(respuesta.codigoHttp, 201);
      expect(respuesta.datos, isA<CursoEntidad>());
      expect((respuesta.datos as CursoEntidad).imagen, 9);
    });

    test('$capa - $tipo - Obtener curso - 200 devuelve entidad', () async {
      conexion.respuestaObtener = RespuestaModelo(
        codigoHttp: 200,
        datos: modelo('Iniciacion', imagen: 3),
      );

      final respuesta = await repositorio.obtenerCurso('Deportes', 'Iniciacion');

      expect(conexion.ultimaCategoria, 'Deportes');
      expect(conexion.ultimoCurso, 'Iniciacion');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<CursoEntidad>());
      final entidad = respuesta.datos as CursoEntidad;
      expect(entidad.nombreCurso, 'Iniciacion');
      expect(entidad.imagen, 3);
    });
  });

  //diagnostico del modulo 8 (plan-diagnostico-cursos.md, U-Repo)
  group('Cursos (repositorio con doble, listas vacias y errores):', () {
    RespuestaModelo error(int codigo, String url) => RespuestaModelo(
      codigoHttp: codigo,
      error: ErrorModelo(
        codigoHttp: codigo,
        mensaje: 'fallo $codigo',
        url: url,
        metodo: 'GET',
      ),
    );

    test('$capa - $tipo - Listar cursos de - 200 [] es una lista vacia de entidades', () async {
      final respuesta = await repositorio.listarCursosDe(
        CategoriaEntidad(titulo: 'Sin cursos', descripcion: 'x'),
      );

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<CursoEntidad>>());
      expect(respuesta.datos, isEmpty);
    });

    test('$capa - $tipo - Obtener curso - 404 pasa sin cambios', () async {
      final e404 = error(404, '/curso');
      conexion.respuestaObtener = e404;

      expect(await repositorio.obtenerCurso('Deportes', 'No existe'), same(e404));
    });

    test('$capa - $tipo - Guardar curso - un error pasa sin cambios y no hay entidad', () async {
      final e400 = error(400, '/curso');
      conexion.respuestaAgregar = e400;

      final respuesta = await repositorio.guardaCurso(
        CursoEntidad(
          nombreCurso: 'Iniciacion',
          nombreDeporte: 'Futbol',
          tituloCategoria: 'Deportes',
          descripcion: 'Desc',
          imagenFile: File('assets/images/1.jpg'),
        ),
      );

      expect(respuesta, same(e400));
      expect(respuesta.datos, isNull);
    });

    test('$capa - $tipo - Guardar curso - el modelo enviado lleva deporte, descripcion e imagen existente', () async {
      conexion.respuestaAgregar = RespuestaModelo(
        codigoHttp: 201,
        datos: modelo('Iniciacion', imagen: 4),
      );

      await repositorio.guardaCurso(
        CursoEntidad(
          nombreCurso: 'Iniciacion',
          nombreDeporte: 'Natacion',
          tituloCategoria: 'Deportes',
          descripcion: 'Curso de natacion',
          imagen: 4,
        ),
      );

      expect(conexion.ultimoAgregado?.nombreDeporte, 'Natacion');
      expect(conexion.ultimoAgregado?.descripcion, 'Curso de natacion');
      expect(conexion.ultimoAgregado?.imagen, 4);
    });
    //el caso rojo (CU-01) esta en
    //test/diagnostico/cursos/repositorio_diagnostico_test.dart
  });
}
