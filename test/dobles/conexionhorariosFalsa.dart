import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de horarios: el test fija la respuesta
class ConexionhorariosFalsa implements Conexionhorarios {
  RespuestaModelo respuestaHorarios = RespuestaModelo(
    codigoHttp: 200,
    datos: <HorarioModelo>[],
  );

  //grupo pedido, como "categoria/curso/anio/iterable"
  String? ultimoGrupo;
  int llamadasHorarios = 0;

  @override
  Future<RespuestaModelo> obtenerHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    llamadasHorarios++;
    ultimoGrupo = '$categoria/$curso/$anio/$iterable';
    return respuestaHorarios;
  }
}
