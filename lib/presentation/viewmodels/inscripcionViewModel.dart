import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionResumenEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/material.dart';

//vm de la pantalla de inscripcion del alumno (ruta gruposDisponiblesInscripcion).
//Inscribir y desvincular devuelven Resultado (fase 6b). Desde la fase 6c guarda
//si el alumno esta inscrito en cada grupo: se valida una vez al cargar y,
//tras inscribir o desvincular, solo se vuelve a validar ese grupo. Validar solo
//cuenta INSCRITO: quien esta en lista de espera sale de /inscripcion/misCursos
class Inscripcionviewmodel with ChangeNotifier, NotificacionSegura {
  final Servicioinscripcion _servicio;

  //el servicio sale de la raiz; el vm lo crea la ruta
  Inscripcionviewmodel(this._servicio);

  //inscrito si/no por Grupoentidad.clave
  final Map<String, EstadoSeccion<bool>> _estados = {};
  //grupos con una inscripcion o desvinculacion en camino: su boton se
  //deshabilita para no enviar dos veces la misma operacion
  final Set<String> _procesando = {};
  //grupos donde el alumno esta en lista de espera, por Grupoentidad.clave
  final Set<String> _enEspera = {};

  EstadoSeccion<bool> estadoDe(Grupoentidad grupo) =>
      _estados[grupo.clave] ?? const EstadoSeccion(false, cargando: true);

  bool procesando(Grupoentidad grupo) => _procesando.contains(grupo.clave);

  bool enEspera(Grupoentidad grupo) => _enEspera.contains(grupo.clave);

  //una validacion por grupo, en paralelo; cada grupo notifica al llegar
  Future<void> cargarEstados(String alumnoId, List<Grupoentidad> grupos) async {
    final espera = await _consultarEspera();
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
          espera: espera,
        ),
      ),
    );
  }

  //el Exito dice si el alumno quedo en lista de espera: un grupo sin cupos
  //tambien responde 201 (BK-06)
  Future<Resultado<bool>> agregarIncripcion(Inscripcionentidad entidad) =>
      _operar(entidad, _servicio.agregarInscripcion, 201, inscritoTras: true);

  //tambien saca al alumno de la lista de espera
  Future<Resultado<bool>> desvincularInscripcion(Inscripcionentidad entidad) =>
      _operar(
        entidad,
        _servicio.desvincularInscripcion,
        200,
        inscritoTras: false,
      );

  //vuelve a consultar un grupo cuya consulta fallo (boton "Reintentar")
  Future<void> reintentar(Inscripcionentidad entidad) async {
    _estados[_clave(entidad)] = const EstadoSeccion(false, cargando: true);
    notifyListeners();
    await _actualizarEstado(entidad, espera: await _consultarEspera());
  }

  //marca el grupo como procesando, llama al servicio y, si sale bien, vuelve
  //a validar solo ese grupo: el backend dice si quedo inscrito
  Future<Resultado<bool>> _operar(
    Inscripcionentidad entidad,
    Future<RespuestaModelo> Function(Inscripcionentidad) operacion,
    int codigoExito, {
    required bool inscritoTras,
  }) async {
    final clave = _clave(entidad);
    //quien ya esta inscrito no repite la inscripcion: el backend la acepta (201)
    //y, con el grupo lleno, le quita el cupo (IN-14, BK-07). Un segundo toque
    //con el estado desactualizado no sale de la app
    final estadoActual = _estados[clave];
    if (inscritoTras &&
        estadoActual != null &&
        estadoActual.error == null &&
        estadoActual.datos) {
      return Fallo(
        409,
        'Ya estás inscrito en este grupo',
        origen: 'ViewModel',
      );
    }
    _procesando.add(clave);
    notifyListeners();
    try {
      RespuestaModelo respuesta = await operacion(entidad);
      if (respuesta.codigoHttp == codigoExito) {
        //la operacion ya se hizo: si la revalidacion falla, el grupo queda
        //con el resultado que se espera y el error a la vista. Antes quedaba
        //como "no inscrito" y el boton volvia a Matricular (IN-10)
        final bool quedoEnEspera =
            respuesta.datos == Inscripcionentidad.estadoEnEspera;
        if (quedoEnEspera) {
          //validar responderia false: la respuesta ya dice lo que paso
          _enEspera.add(clave);
          _estados[clave] = const EstadoSeccion(false);
        } else {
          _enEspera.remove(clave);
          //el 201 ya dijo que quedo inscrito: un "no inscrito" que llega
          //enseguida no lo contradice (BK-09), ver _consultar
          await _actualizarEstado(
            entidad,
            siFalla: inscritoTras,
            recienInscrito: inscritoTras,
          );
        }
        return Exito(quedoEnEspera);
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    } finally {
      _procesando.remove(clave);
      notifyListeners();
    }
  }

  //[siFalla]: lo que se sabe del grupo si la consulta no se puede hacer.
  //[espera]: la lista de espera ya consultada; sin ella no se toca _enEspera
  //[recienInscrito]: se acaba de recibir un 201 de inscripcion
  Future<void> _actualizarEstado(
    Inscripcionentidad entidad, {
    bool siFalla = false,
    bool recienInscrito = false,
    ({Set<String> claves, String? error})? espera,
  }) async {
    final clave = _clave(entidad);
    var estado = await _consultar(
      entidad,
      siFalla,
      recienInscrito: recienInscrito,
    );
    if (espera != null && estado.error == null) {
      _enEspera.remove(clave);
      if (!estado.datos && espera.error != null) {
        //sin saber si esta en la lista no se puede ofrecer Matricular
        estado = EstadoSeccion(false, error: espera.error);
      } else if (!estado.datos && espera.claves.contains(clave)) {
        _enEspera.add(clave);
      }
    }
    _estados[clave] = estado;
    notifyListeners();
  }

  //una sola peticion para todos los grupos
  Future<({Set<String> claves, String? error})> _consultarEspera() async {
    try {
      final respuesta = await _servicio.obtenerMisCursos();
      if (respuesta.codigoHttp != 200) {
        return (claves: <String>{}, error: _fallo(respuesta).mensaje);
      }
      final cursos = respuesta.datos as List<Inscripcionresumenentidad>;
      return (
        claves:
            cursos
                .where((c) => c.enEspera)
                .map(
                  (c) => Grupoentidad.claveDe(
                    c.categoria,
                    c.curso,
                    c.anio,
                    c.iterable,
                  ),
                )
                .toSet(),
        error: null,
      );
    } catch (e) {
      return (claves: <String>{}, error: e.toString());
    }
  }

  //una consulta que falla deja el error en el estado del grupo, para que la
  //pantalla no pinte "Matricular" como si no estuviera inscrito (IN-09)
  //BK-09: el backend guarda fechaInscripcion redondeada hacia arriba y
  //validar exige fechaInscripcion <= ahora, asi que durante menos de un segundo
  //responde "no inscrito" a quien acaba de inscribirse. Con [recienInscrito]
  //ese falso no se toma en cuenta: el 201 es la fuente de la verdad
  Future<EstadoSeccion<bool>> _consultar(
    Inscripcionentidad entidad,
    bool siFalla, {
    bool recienInscrito = false,
  }) async {
    try {
      final respuesta = await _servicio.validarInscripcion(entidad);
      if (respuesta.codigoHttp == 200 && respuesta.datos is bool) {
        return EstadoSeccion((respuesta.datos as bool) || recienInscrito);
      }
      return EstadoSeccion(siFalla, error: _fallo(respuesta).mensaje);
    } catch (e) {
      return EstadoSeccion(siFalla, error: e.toString());
    }
  }

  //consulta directa (si/no) que usan las pruebas remotas para leer lo que
  //quedo en el backend; un error cuenta como no inscrito. La pantalla usa
  //estadoDe, que conserva el error
  Future<bool> validarInscripcion(Inscripcionentidad entidad) async =>
      (await _consultar(entidad, false)).datos;

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
