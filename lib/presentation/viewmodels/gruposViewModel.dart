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
        /*_mostrarError(
          context,
          "datos inconsistentes",
          ErrorModelo(
            codigoHttp: 406,
            mensaje:
                'no se ha obtenido una lista de tipo entidad para cargar los datos',
            url: "gruposdecurso",
            metodo: "GET",
          ),
        );*/
        return Future.value([]);
      }
    } catch (e) {
      /*_mostrarError(
        context,
        'excepcion no controlada',
        ErrorModelo(
          codigoHttp: 0,
          mensaje: e.toString(),
          url: 'GruposDecurso',
          metodo: 'GET',
        ),
      );*/
      return Future.value([]);
    }
  }

  void _mostrarError(context, String titulo, ErrorModelo? error) {
    showDialog(
      context: context,
      builder: (context) {
        return (error != null)
            ? DialogError(
              titulo: titulo,
              mensaje: error.mensaje,
              codigo: error.codigoHttp,
            )
            : DialogError(
              titulo: 'Error sin informacion',
              mensaje: "Se desconoce el error",
              codigo: 0,
            );
      },
    );
  }
}
