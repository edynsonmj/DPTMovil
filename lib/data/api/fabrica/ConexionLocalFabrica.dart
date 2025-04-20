import 'package:dpt_movil/data/api/conexion/ConexionAlumnos.dart';
import 'package:dpt_movil/data/api/conexion/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/ConexionCategoria.dart';
import 'package:dpt_movil/data/api/conexion/ConexionClases.dart';
import 'package:dpt_movil/data/api/conexion/ConexionCurso.dart';
import 'package:dpt_movil/data/api/conexion/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/ConexionGrupos.dart';
import 'package:dpt_movil/data/api/conexion/ConexionHorarios.dart';
import 'package:dpt_movil/data/api/conexion/local/ConexionCursoLocal.dart';
import 'package:dpt_movil/data/api/conexion/local/ConexionEstadisticasLocal.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/api/conexion/local/ConexionCategoriaLocal.dart';

class ConexionLocalFabrica implements ConexionFabricaAbstracta {
  @override
  ConexionCategoria crearConexionCategoria() {
    return ConexionCategoriaLocal();
  }

  @override
  ConexionCurso crearConexionCurso() {
    return ConexionCursoLocal();
  }

  @override
  ConexionEstadisticas crearConexionEstadisticas() {
    return ConexionEstadisticasLocal();
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
