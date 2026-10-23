import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

class Serviciogrupo {
  Gruporepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  //(lib/config/inyeccion/dependencias.dart)
  Serviciogrupo(this.repositorio);

  Future<RespuestaModelo> listarGruposDe(String categoria, String curso) {
    return repositorio.listarGruposDe(categoria, curso);
  }

  Future<RespuestaModelo> listarGruposDisponiblesInscripcion() {
    return repositorio.listarGruposDisponiblesInscripcion();
  }

  Future<RespuestaModelo> listarGruposInstructores(String idInstructor) {
    return repositorio.listarGruposInstructores(idInstructor);
  }

  Future<RespuestaModelo> insertarGrupo(Grupoentidad grupo) {
    return repositorio.insertarGrupo(grupo);
  }

  String urlImagen(int idImagen) => repositorio.urlImagen(idImagen);
}
