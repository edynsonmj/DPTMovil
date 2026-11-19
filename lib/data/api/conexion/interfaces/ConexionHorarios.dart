import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionhorarios {
  Future<RespuestaModelo> obtenerHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );

  //201: horario creado; el grupo viaja en el propio modelo
  Future<RespuestaModelo> agregarHorario(HorarioModelo modelo);

  Future<RespuestaModelo> eliminarHorario(int id);
}
