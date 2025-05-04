import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAutenticacion.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionClases.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCurso.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionDeporte.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
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

  @override
  Conexionimagen crearConexionImagenes() {
    // TODO: implement crearConexionImagenes
    throw UnimplementedError();
  }

  @override
  Conexiondeporte crearConexionDeporte() {
    // TODO: implement crearConexionDeporte
    throw UnimplementedError();
  }

  @override
  Conexionautenticacion crearConexionAutenticacion() {
    // TODO: implement crearConexionAutenticacion
    throw UnimplementedError();
  }
}
