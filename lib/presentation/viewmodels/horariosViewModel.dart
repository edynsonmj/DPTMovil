import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

class Horariosviewmodel with ChangeNotifier, NotificacionSegura {
  final Serviciohorario servicioHorario;

  //el servicio sale de la raiz; el vm lo crean las rutas
  //gruposDisponiblesInscripcion y gruposAsignados
  Horariosviewmodel(this.servicioHorario);

  //horarios de cada grupo de la pantalla, por Grupoentidad.clave (fase 6c):
  //se piden una vez al cargar la lista y cada tarjeta lee solo el suyo
  final Map<String, EstadoSeccion<List<Horarioentidad>>> _porGrupo = {};

  //mientras no llega, la tarjeta se pinta cargando
  EstadoSeccion<List<Horarioentidad>> horariosDe(Grupoentidad grupo) =>
      _porGrupo[grupo.clave] ??
      const EstadoSeccion(<Horarioentidad>[], cargando: true);

  //una peticion por grupo, en paralelo; cada grupo notifica al llegar
  Future<void> cargarHorariosDe(List<Grupoentidad> grupos) async {
    await Future.wait(grupos.map(_cargarHorarios));
  }

  Future<void> _cargarHorarios(Grupoentidad grupo) async {
    EstadoSeccion<List<Horarioentidad>> estado;
    try {
      final respuesta = await listarHorariosGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      );
      //un error deja la tarjeta sin horarios, no rompe la pantalla (I3)
      estado =
          (respuesta.codigoHttp == 200 && respuesta.datos is List)
              ? EstadoSeccion(
                (respuesta.datos as List).cast<Horarioentidad>(),
              )
              : EstadoSeccion(
                <Horarioentidad>[],
                error:
                    'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}',
              );
    } catch (e) {
      estado = EstadoSeccion(<Horarioentidad>[], error: e.toString());
    }
    _porGrupo[grupo.clave] = estado;
    notifyListeners();
  }

  Future<RespuestaModelo> listarHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioHorario.listarHoariosGrupo(
        categoria,
        curso,
        anio,
        iterable,
      );
      return respuesta;
    } on Exception catch (e) {
      return RespuestaModelo.fromException(
        e,
        'GET',
        'ObtenerHoariosGrupo',
        'ViewModel',
      );
    }
  }
}
