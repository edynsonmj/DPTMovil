import 'package:dpt_movil/config/configServicio.dart';
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
  Conexionimagen crearConexionImagenes();
  Conexiondeporte crearConexionDeporte();
}
