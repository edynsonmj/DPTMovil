import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/material.dart';

//NotificacionSegura (fase 6c): las pantallas encadenan la carga de la lista
//con otras y el usuario puede salir antes de que llegue
class Gruposviewmodel with ChangeNotifier, NotificacionSegura {
  final Serviciogrupo serviciogrupo;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  //objeto que conserva listado de grupos
  List<Grupoentidad>? _listaGrupos;

  //get para la lista
  List<Grupoentidad>? get getListaGrupos => _listaGrupos;

  //el servicio sale de la raiz. Hay una instancia global (GruposAsignados y
  //GruposInscripcion, fase 6) y una propia en las rutas curso y grupoFormulario
  Gruposviewmodel(this.serviciogrupo);

  //url de la imagen de un grupo o curso: la vista no conoce el servidor
  String urlImagen(int idImagen) => serviciogrupo.urlImagen(idImagen);

  Future<List<Grupoentidad>> listarGruposDe(
    String categoria,
    String curso,
  ) async {
    RespuestaModelo? respuesta;
    //null mientras carga: con [] la vista pintaba un instante "aun no hay
    //grupos" antes de que llegaran los datos
    _listaGrupos = null;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      respuesta = await serviciogrupo.listarGruposDe(categoria, curso);
      if (respuesta.codigoHttp != 200) {
        _cargando = false;
        _error = respuesta.error?.mensaje ?? "no hay datos del error";
        notifyListeners();
        return Future.value([]);
      }
      if (respuesta.datos is List<Grupoentidad>) {
        _listaGrupos = respuesta.datos as List<Grupoentidad>;
        _cargando = false;
        _error = null;
        notifyListeners();
        return Future.value(_listaGrupos);
      } else {
        _cargando = false;
        _error =
            "la informacion encontrada no corresponde a una lista de grupos";
        notifyListeners();
        return Future.value([]);
      }
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      return Future.value([]);
    }
  }

  Future<void> listarGruposDisponiblesInscripcion() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    RespuestaModelo? respuesta;
    _listaGrupos = [];
    try {
      respuesta = await serviciogrupo.listarGruposDisponiblesInscripcion();
      if (respuesta.codigoHttp != 200) {
        _cargando = false;
        _error =
            'Error encontrado: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje}';
        notifyListeners();
        return;
      }
      if (respuesta.datos is List<Grupoentidad>) {
        _listaGrupos = respuesta.datos as List<Grupoentidad>;
        _cargando = false;
        _error = null;
        notifyListeners();
        return;
      } else {
        _cargando = false;
        _error =
            'Error datos incompatibles, lista no es de tipo GrupoEntidad, en viewmodel';
        notifyListeners();
      }
    } catch (e) {
      _cargando = false;
      _error = 'Error no controlado: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> listarGruposInstructor(String idInstructor) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    RespuestaModelo? respuesta;
    _listaGrupos = [];
    try {
      respuesta = await serviciogrupo.listarGruposInstructores(idInstructor);
      if (respuesta.codigoHttp != 200) {
        _cargando = false;
        _error =
            'Error encontrado: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje}';
        notifyListeners();
        return;
      }
      if (respuesta.datos is List<Grupoentidad>) {
        _listaGrupos = respuesta.datos as List<Grupoentidad>;
        _cargando = false;
        _error = null;
        notifyListeners();
        return;
      } else {
        _cargando = false;
        _error =
            'Error datos incompatibles, lista no es de tipo GrupoEntidad, en viewmodel';
        notifyListeners();
      }
    } catch (e) {
      _cargando = false;
      _error = 'Error no controlado: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<RespuestaModelo> insertarGrupo(Grupoentidad entidad) async {
    try {
      //no refresca: el formulario tiene su propio vm y la pantalla del
      //curso recarga su lista al volver con pop(true)
      return await serviciogrupo.insertarGrupo(entidad);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        "POST",
        "Insertar grupo",
        "view model",
      );
    }
  }
}
