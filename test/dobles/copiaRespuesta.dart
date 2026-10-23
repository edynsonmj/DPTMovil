import 'package:dpt_movil/data/models/respuestaModelo.dart';

//los repositorios convierten modelos a entidades escribiendo sobre
//respuesta.datos. La conexion real crea una respuesta nueva por peticion; un
//doble que devuelve siempre el mismo objeto a varias peticiones (un grupo
//tras otro) tiene que devolver una copia, o la segunda llega ya convertida.
//Solo se copia si hay lista (lo que se convierte): asi un error o un 406
//sigue llegando como el mismo objeto y los tests con same() no cambian.
//toList() conserva el tipo de la lista (List<HorarioModelo>, ...)
RespuestaModelo copiaRespuesta(RespuestaModelo original) =>
    original.datos is List
        ? RespuestaModelo(
          codigoHttp: original.codigoHttp,
          datos: (original.datos as List).toList(),
          error: original.error,
        )
        : original;
