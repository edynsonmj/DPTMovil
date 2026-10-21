import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionClases.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';

//ConexionCursoLocal ya no se crea aqui (fase 3); se borra en la fase 8
class ConexionLocalFabrica implements ConexionFabricaAbstracta {
  @override
  ConexionEstadisticas crearConexionEstadisticas() {
    throw UnimplementedError();
  }

  @override
  Conexiongrupos crearConexionGrupos() {
    // TODO: implement crearConexionGrupos
    throw UnimplementedError();
  }

  @override
  Conexionhorarios crearConexionHorarios() {
    // TODO: implement crearConexionHorarios
    throw UnimplementedError();
  }

  @override
  Conexionalumnos crearConexionAlumnos() {
    // TODO: implement crearConexionAlumnos
    throw UnimplementedError();
  }

  @override
  Conexionclases crearConexionClases() {
    // TODO: implement crearConexionClases
    throw UnimplementedError();
  }

  @override
  Conexionatenciones crearConexionAtenciones() {
    // TODO: implement crearConexionAtenciones
    throw UnimplementedError();
  }
}
