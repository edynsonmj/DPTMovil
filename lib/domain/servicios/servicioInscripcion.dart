import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';

class Servicioinscripcion {
  Inscripcionrepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  Servicioinscripcion(this.repositorio);

  Future<RespuestaModelo> agregarInscripcion(Inscripcionentidad entidad) {
    return repositorio.agregarInscripcion(entidad);
  }

  Future<RespuestaModelo> validarInscripcion(Inscripcionentidad entidad) {
    return repositorio.validarInscripcion(entidad);
  }

  Future<RespuestaModelo> desvincularInscripcion(Inscripcionentidad entidad) {
    return repositorio.eliminarInscripcion(entidad);
  }

  Future<RespuestaModelo> obtenerMisCursos() {
    return repositorio.obtenerMisCursos();
  }
}
