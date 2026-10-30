import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

import 'copiaRespuesta.dart';

//doble programable de la conexion de horarios: el test fija la respuesta
class ConexionhorariosFalsa implements Conexionhorarios {
  RespuestaModelo respuestaHorarios = RespuestaModelo(
    codigoHttp: 200,
    datos: <HorarioModelo>[],
  );

  //grupo pedido, como "categoria/curso/anio/iterable", y todos los pedidos
  String? ultimoGrupo;
  final List<String> gruposPedidos = [];
  int llamadasHorarios = 0;
  //si se fija, la conexion lanza esto en vez de responder: la real solo
  //captura Exception, asi que un TypeError de HorarioModelo.fromJson sale
  //hacia el repositorio
  Object? lanzar;

  @override
  Future<RespuestaModelo> obtenerHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    llamadasHorarios++;
    ultimoGrupo = '$categoria/$curso/$anio/$iterable';
    gruposPedidos.add(ultimoGrupo!);
    if (lanzar != null) throw lanzar!;
    //una copia por peticion: la misma respuesta sirve para varios grupos
    return copiaRespuesta(respuestaHorarios);
  }
}
