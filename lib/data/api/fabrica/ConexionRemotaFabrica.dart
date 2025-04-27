import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionClases.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCurso.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionDeporte.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAlumnosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionDeporteRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
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
    return Conexionhorariosremoto();
  }

  @override
  Conexionalumnos crearConexionAlumnos() {
    return Conexionalumnosremoto();
  }

  @override
  Conexionclases crearConexionClases() {
    return Conexionclasesremoto();
  }

  @override
  Conexionatenciones crearConexionAtenciones() {
    return Conexionatencionesremoto();
  }

  @override
  Conexionimagen crearConexionImagenes() {
    return Conexionimagenremoto();
  }

  @override
  Conexiondeporte crearConexionDeporte() {
    return Conexiondeporteremoto();
  }
}
