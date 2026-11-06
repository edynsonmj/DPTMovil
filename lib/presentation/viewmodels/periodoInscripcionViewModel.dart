import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

//vm de la pantalla del coordinador para abrir, programar y cerrar las
//inscripciones de cada grupo (ruta InscripcionesParticulares, plan de abrir
//inscripciones). La ruta lo crea y llama a cargar(); se desecha al salir
class PeriodoInscripcionViewModel with ChangeNotifier, NotificacionSegura {
  final Serviciogrupo _servicio;
  //dia que se toma como hoy para calcular el estado; las pruebas fijan uno
  final DateTime Function() _hoy;

  PeriodoInscripcionViewModel(this._servicio, {DateTime Function()? hoy})
    : _hoy = hoy ?? DateTime.now;

  //todos los grupos activos; cargando hasta que llega la primera respuesta
  EstadoSeccion<List<Grupoentidad>> _grupos = const EstadoSeccion(
    [],
    cargando: true,
  );
  EstadoSeccion<List<Grupoentidad>> get grupos => _grupos;

  //filtro por titulo de categoria; null = todas. El backend no tiene una
  //consulta por categoria, se filtra aqui
  String? _categoria;
  String? get categoria => _categoria;

  List<Grupoentidad> get gruposFiltrados =>
      _categoria == null
          ? _grupos.datos
          : _grupos.datos.where((g) => g.categoria == _categoria).toList();

  //grupos con una apertura o cierre en camino: su boton se deshabilita y una
  //segunda peticion no sale
  final Set<String> _procesando = {};
  bool procesando(Grupoentidad grupo) => _procesando.contains(grupo.clave);

  EstadoInscripcion estadoDe(Grupoentidad grupo) =>
      grupo.estadoInscripcion(_hoy());

  Future<void> cargar() async {
    _grupos = EstadoSeccion(_grupos.datos, cargando: true);
    notifyListeners();
    try {
      final respuesta = await _servicio.listarGruposNoEliminados();
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _grupos = EstadoSeccion(
          (respuesta.datos as List).cast<Grupoentidad>(),
        );
      } else {
        _grupos = EstadoSeccion(
          [],
          error:
              'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}',
        );
      }
    } catch (e) {
      _grupos = EstadoSeccion([], error: e.toString());
    }
    notifyListeners();
  }

  void filtrar(String? categoria) {
    _categoria = categoria;
    notifyListeners();
  }

  //abre desde hoy (sin apertura) o programa (apertura futura). El backend
  //exige el cierre: sin el no sale la peticion
  Future<Resultado<Grupoentidad>> abrir(
    Grupoentidad grupo, {
    DateTime? apertura,
    DateTime? cierre,
  }) async {
    if (cierre == null) {
      return Fallo(
        0,
        'Seleccione la fecha de cierre de las inscripciones',
        origen: 'ViewModel',
      );
    }
    return _operar(
      grupo,
      () => _servicio.abrirInscripciones(
        grupo,
        apertura: apertura ?? _hoy(),
        cierre: cierre,
      ),
    );
  }

  Future<Resultado<Grupoentidad>> cerrar(Grupoentidad grupo) =>
      _operar(grupo, () => _servicio.cerrarInscripciones(grupo));

  //marca el grupo como procesando, llama al servicio y, si sale bien,
  //reemplaza solo ese grupo con el que devolvio el backend (ya trae el
  //periodo nuevo): no se recarga la lista
  Future<Resultado<Grupoentidad>> _operar(
    Grupoentidad grupo,
    Future<RespuestaModelo> Function() operacion,
  ) async {
    if (procesando(grupo)) {
      return Fallo(
        0,
        'Ya hay una operación en camino para este grupo',
        origen: 'ViewModel',
      );
    }
    _procesando.add(grupo.clave);
    notifyListeners();
    try {
      final respuesta = await operacion();
      if (respuesta.codigoHttp == 200 && respuesta.datos is Grupoentidad) {
        final actualizado = respuesta.datos as Grupoentidad;
        _reemplazar(actualizado);
        return Exito(actualizado);
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    } finally {
      _procesando.remove(grupo.clave);
      notifyListeners();
    }
  }

  void _reemplazar(Grupoentidad actualizado) {
    _grupos = EstadoSeccion([
      for (final g in _grupos.datos)
        g.clave == actualizado.clave ? actualizado : g,
    ]);
  }

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
