import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:flutter/material.dart';

class Gruposviewmodel with ChangeNotifier {
  late final Serviciogrupo serviciogrupo;

  //objeto que conserva listado de grupos
  List<Grupoentidad>? _listaGrupos;

  //get para la lista
  List<Grupoentidad>? get getListaGrupos => _listaGrupos;

  Gruposviewmodel() : serviciogrupo = Serviciogrupo();

  Future<List<Grupoentidad>> listarGruposDe(
    context,
    String categoria,
    String curso,
  ) async {
    RespuestaModelo? respuesta;
    _listaGrupos = [];
    try {
      respuesta = await serviciogrupo.listarGruposDe(categoria, curso);
      if (respuesta.codigoHttp != 200) {
        //_mostrarError(context, "Sin datos", respuesta.error);
        return Future.value(_listaGrupos);
      }
      if (respuesta.datos is List<Grupoentidad>) {
        _listaGrupos = respuesta.datos as List<Grupoentidad>;
        return Future.value(_listaGrupos);
      } else {
        return Future.value([]);
      }
    } catch (e) {
      return Future.value([]);
    }
  }

  Future<void> listarGruposDisponiblesInscripcion() async {
    RespuestaModelo? respuesta;
    _listaGrupos = [];
    try {
      respuesta = await serviciogrupo.listarGruposDisponiblesInscripcion();
      if (respuesta.codigoHttp != 200) {
        notifyListeners();
        return;
      }
      if (respuesta.datos is List<Grupoentidad>) {
        _listaGrupos = respuesta.datos as List<Grupoentidad>;
        notifyListeners();
        return;
      }
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }
}
