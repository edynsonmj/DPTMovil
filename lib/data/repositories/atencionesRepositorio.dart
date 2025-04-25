import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';

class Atencionesrepositorio {
  Conexionatenciones conexion;
  Atencionesrepositorio({required this.conexion});

  Future<RespuestaModelo> listarAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int idClase,
  ) async {
    String path = "listarAtencionesClase";
    String metodo = "GET";
    String capa = "Repositorio";
    final RespuestaModelo respuesta = await conexion.obtenerAtencionesClase(
      categoria,
      curso,
      anio,
      iterable,
      idClase,
    );
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    try {
      List<Atencionmodelo> listaModelo =
          respuesta.datos as List<Atencionmodelo>;
      List<Atencionentidad> listaEntidad = [];
      for (Atencionmodelo item in listaModelo) {
        Atencionentidad entidad = Atencionentidad.fromModelo(item);
        listaEntidad.add(entidad);
      }
      respuesta.datos = listaEntidad;
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
    }
  }

  Future<RespuestaModelo> registrarAtencionesClase(
    List<Atencionentidad> atenciones,
    int idClase,
  ) async {
    List<Atencionmodelo> lista = [];
    for (Atencionentidad atencion in atenciones) {
      lista.add(
        Atencionmodelo(
          alumno: Alumnomodelo(
            id: atencion.alumno.id,
            tipo: atencion.alumno.tipo,
            nombre: atencion.alumno.nombre,
            correo: atencion.alumno.correo,
            sexo: atencion.alumno.sexo,
            tipoid: atencion.alumno.tipoid,
            codigo: atencion.alumno.codigo,
            imagen: atencion.alumno.imagen,
          ),
          idClase: atencion.idClase,
          estaAtendido: atencion.estaAtendido,
        ),
      );
    }
    return await conexion.registrarAtencionesClase(lista, idClase);
  }
}
