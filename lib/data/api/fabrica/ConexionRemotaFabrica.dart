import 'package:dpt_movil/data/api/conexion/ConexionCategoria.dart';
import 'package:dpt_movil/data/api/conexion/ConexionCurso.dart';
import 'package:dpt_movil/data/api/conexion/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/ConexionGrupos.dart';
import 'package:dpt_movil/data/api/conexion/ConexionHorarios.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';

class ConexionRemotaFabrica implements ConexionFabricaAbstracta {
  @override
  ConexionCategoria crearConexionCategoria() {
    return ConexionCategoriaRemota();
  }

  @override
  ConexionCurso crearConexionCurso() {
    return ConexionCursoRemoto();
  }

  @override
  ConexionEstadisticas crearConexionEstadisticas() {
    // TODO: implement crearConexionEstadisticas
    throw UnimplementedError();
  }

  @override
  Conexiongrupos crearConexionGrupos() {
    return Conexiongruposremoto();
  }

  @override
  Conexionhorarios crearConexionHorarios() {
    // TODO: implement crearConexionHorarios
    return Conexionhorariosremoto();
  }
}
