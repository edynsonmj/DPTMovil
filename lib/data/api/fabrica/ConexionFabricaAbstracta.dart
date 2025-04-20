import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/ConexionAlumnos.dart';
import 'package:dpt_movil/data/api/conexion/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/ConexionCategoria.dart';
import 'package:dpt_movil/data/api/conexion/ConexionClases.dart';
import 'package:dpt_movil/data/api/conexion/ConexionCurso.dart';
import 'package:dpt_movil/data/api/conexion/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/ConexionGrupos.dart';
import 'package:dpt_movil/data/api/conexion/ConexionHorarios.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionRemotaFabrica.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionLocalFabrica.dart';

abstract class ConexionFabricaAbstracta {
  static final String SERVICIO_REMOTO = 'remoto';
  static final String SERVICIO_LOCAL = 'local';

  static ConexionFabricaAbstracta obtenerConexionFabrica() {
    if (ConfigServicio.tipoFabricaServicio == SERVICIO_LOCAL) {
      return ConexionLocalFabrica();
    }
    if (ConfigServicio.tipoFabricaServicio == SERVICIO_REMOTO) {
      return ConexionRemotaFabrica();
    }
    return ConexionLocalFabrica();
  }

  ConexionCategoria crearConexionCategoria();
  ConexionCurso crearConexionCurso();
  ConexionEstadisticas crearConexionEstadisticas();
  Conexiongrupos crearConexionGrupos();
  Conexionhorarios crearConexionHorarios();
  Conexionalumnos crearConexionAlumnos();
  Conexionclases crearConexionClases();
  Conexionatenciones crearConexionAtenciones();
}
