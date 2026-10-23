import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/material.dart';

//vm de la pantalla de inscripcion del alumno (ruta gruposDisponiblesInscripcion).
//Inscribir y desvincular devuelven Resultado (fase 6b). Desde la fase 6c guarda
//si el alumno esta inscrito en cada grupo: se valida una vez al cargar y,
//tras inscribir o desvincular, solo se vuelve a validar ese grupo
class Inscripcionviewmodel with ChangeNotifier, NotificacionSegura {
  final Servicioinscripcion _servicio;

  //el servicio sale de la raiz; el vm lo crea la ruta
  Inscripcionviewmodel(this._servicio);

  //inscrito si/no por Grupoentidad.clave
  final Map<String, EstadoSeccion<bool>> _estados = {};
  //grupos con una inscripcion o desvinculacion en camino: su boton se
  //deshabilita para no enviar dos veces la misma operacion
  final Set<String> _procesando = {};

  EstadoSeccion<bool> estadoDe(Grupoentidad grupo) =>
      _estados[grupo.clave] ?? const EstadoSeccion(false, cargando: true);

  bool procesando(Grupoentidad grupo) => _procesando.contains(grupo.clave);

  //una validacion por grupo, en paralelo; cada grupo notifica al llegar
  Future<void> cargarEstados(String alumnoId, List<Grupoentidad> grupos) async {
    await Future.wait(
      grupos.map(
        (grupo) => _actualizarEstado(
          Inscripcionentidad(
            alumnoId: alumnoId,
            categoria: grupo.categoria,
            curso: grupo.curso,
            anio: grupo.anio,
            iterable: grupo.iterable,
          ),
        ),
      ),
    );
  }

  Future<Resultado<void>> agregarIncripcion(Inscripcionentidad entidad) =>
      _operar(entidad, _servicio.agregarInscripcion, 201);

  Future<Resultado<void>> desvincularInscripcion(Inscripcionentidad entidad) =>
      _operar(entidad, _servicio.desvincularInscripcion, 200);

  //marca el grupo como procesando, llama al servicio y, si sale bien, vuelve
  //a validar solo ese grupo: el backend dice si quedo inscrito
  Future<Resultado<void>> _operar(
    Inscripcionentidad entidad,
    Future<RespuestaModelo> Function(Inscripcionentidad) operacion,
    int codigoExito,
  ) async {
    final clave = _clave(entidad);
    _procesando.add(clave);
    notifyListeners();
    try {
      RespuestaModelo respuesta = await operacion(entidad);
      if (respuesta.codigoHttp == codigoExito) {
        await _actualizarEstado(entidad);
        return Exito();
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    } finally {
      _procesando.remove(clave);
      notifyListeners();
    }
  }

  Future<void> _actualizarEstado(Inscripcionentidad entidad) async {
    final inscrito = await validarInscripcion(entidad);
    _estados[_clave(entidad)] = EstadoSeccion(inscrito);
    notifyListeners();
  }

  Future<bool> validarInscripcion(Inscripcionentidad entidad) async {
    try {
      RespuestaModelo respuesta = await _servicio.validarInscripcion(entidad);
      if (respuesta.codigoHttp == 200) {
        return respuesta.datos as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _clave(Inscripcionentidad e) =>
      Grupoentidad.claveDe(e.categoria, e.curso, e.anio, e.iterable);

  //unico punto donde se lee el ErrorModelo: la vista recibe codigo y mensaje
  //ya resueltos y no necesita conocer la capa de datos
  Fallo<T> _fallo<T>(RespuestaModelo respuesta) {
    final error = respuesta.error;
    return Fallo(
      respuesta.codigoHttp,
      error?.mensaje ?? 'Error desconocido. Código: ${respuesta.codigoHttp}',
      origen: error == null ? null : '${error.metodo} ${error.url}',
    );
  }
}
