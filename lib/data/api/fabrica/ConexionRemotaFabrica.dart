import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionClases.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAlumnosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionEstadisticasRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';

class ConexionRemotaFabrica implements ConexionFabricaAbstracta {
  @override
  ConexionEstadisticas crearConexionEstadisticas() {
    return Conexionestadisticasremoto();
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
}
