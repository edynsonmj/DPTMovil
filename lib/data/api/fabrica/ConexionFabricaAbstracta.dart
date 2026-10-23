import 'package:dpt_movil/config/configServicio.dart';
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

  //categoria ya no pasa por la fabrica: se inyecta desde la raiz (fase 1)
  //curso, deporte e imagenes tampoco (fase 3), ni grupos, horarios,
  //alumnos y clases (fase 4), ni atenciones (fase 5), ni estadisticas
  //(fase 7). Ya no crea ninguna conexion: solo quedan las constantes que
  //leen ConfigServicio y page1; se borra en la fase 8
  //autenticacion nunca paso por la fabrica (lanzaba UnimplementedError):
  //se inyecta desde la raiz (fase 2)
}
