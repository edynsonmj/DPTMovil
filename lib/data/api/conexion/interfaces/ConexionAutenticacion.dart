import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionautenticacion {
  Future<RespuestaModelo> login(String email);

  Future<RespuestaModelo> registro(Perfilmodelo modelo);
}
