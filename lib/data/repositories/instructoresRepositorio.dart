import 'package:dpt_movil/data/api/conexion/interfaces/ConexionInstructores.dart';
import 'package:dpt_movil/data/mappers/instructorMapper.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Instructoresrepositorio {
  Conexioninstructores conexion;
  Instructoresrepositorio({required this.conexion});

  Future<RespuestaModelo> listarInstructores() async {
    final String metodo = "GET";
    final String path = "ListarInstructores";
    final String capa = "Repositorio";
    final RespuestaModelo respuesta = await conexion.obtenerInstructores();
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    try {
      List<Instructormodelo> modelos =
          respuesta.datos as List<Instructormodelo>;
      respuesta.datos = modelos.map(InstructorMapper.aEntidad).toList();
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        path,
        capa,
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(error, metodo, path, capa);
    } catch (e) {
      return RespuestaModelo.fromObjectError(e, metodo, path, capa);
    }
  }
}
