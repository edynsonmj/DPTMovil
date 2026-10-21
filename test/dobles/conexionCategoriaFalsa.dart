import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de categorias: no simula una bd, cada
//test fija la respuesta que quiere y despues revisa lo que llego a la
//conexion. Asi se puede probar cualquier codigo (204, 500, error de red)
//sin backend y sin depender del orden de los tests
class ConexionCategoriaFalsa implements ConexionCategoria {
  //respuesta que devuelve cada metodo; el test la fija antes de actuar
  RespuestaModelo respuestaListar = RespuestaModelo(
    codigoHttp: 200,
    datos: <categoriaModelo>[],
  );
  RespuestaModelo respuestaGuardar = RespuestaModelo(codigoHttp: 201);
  RespuestaModelo respuestaActualizar = RespuestaModelo(codigoHttp: 200);
  RespuestaModelo respuestaEliminar = RespuestaModelo(codigoHttp: 200);

  //lo que recibio, para comprobar que el repositorio armo bien la peticion
  categoriaModelo? ultimaGuardada;
  categoriaModelo? ultimaActualizada;
  String? ultimoTituloEliminado;
  int llamadasListar = 0;
  int llamadasGuardar = 0;
  int llamadasActualizar = 0;
  int llamadasEliminar = 0;

  @override
  Future<RespuestaModelo> encontrarCategorias() async {
    llamadasListar++;
    return respuestaListar;
  }

  @override
  Future<RespuestaModelo> guardarCategoria(categoriaModelo categoria) async {
    llamadasGuardar++;
    ultimaGuardada = categoria;
    return respuestaGuardar;
  }

  @override
  Future<RespuestaModelo> actualizarCategoria(categoriaModelo categoria) async {
    llamadasActualizar++;
    ultimaActualizada = categoria;
    return respuestaActualizar;
  }

  @override
  Future<RespuestaModelo> eliminarCategoria(String titulo) async {
    llamadasEliminar++;
    ultimoTituloEliminado = titulo;
    return respuestaEliminar;
  }

  @override
  String urlImagen(int idImagen) =>
      'http://falso/imagenStream?idImagen=$idImagen';
}
