import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';

class Serviciogrupo {
  Gruporepositorio repositorio;
  Serviciogrupo()
    : repositorio = Gruporepositorio(
        conexion:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionGrupos(),
      );

  Future<RespuestaModelo> listarGruposDe(String categoria, String curso) {
    return repositorio.listarGruposDe(categoria, curso);
  }

  Future<RespuestaModelo> listarGruposDisponiblesInscripcion() {
    return repositorio.listarGruposDisponiblesInscripcion();
  }

  Future<RespuestaModelo> listarGruposInstructores(String idInstructor) {
    return repositorio.listarGruposInstructores(idInstructor);
  }
}
