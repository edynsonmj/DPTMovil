import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:flutter/material.dart';

class Atencionviewmodel with ChangeNotifier {
  Servicioatencion _servicioAtencion;
  Atencionviewmodel() : _servicioAtencion = Servicioatencion();

  Future<RespuestaModelo> listarAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int idClase,
  ) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await _servicioAtencion.listarAtencionesClase(
        categoria,
        curso,
        anio,
        iterable,
        idClase,
      );
      return respuesta;
    } on Exception catch (e) {
      return RespuestaModelo.fromException(
        e,
        'GET',
        'ListarClasesGrupo',
        'ViewModel',
      );
    }
  }

  Future<RespuestaModelo> registrarAtenciones(
    context,
    List<Atencionentidad> atenciones,
    int idClase,
  ) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await _servicioAtencion.registrarAtenciones(
        atenciones,
        idClase,
      );
      /*if (respuesta.codigoHttp != 200) {
        _mostrarError(context, "falllo al registrar", respuesta.error);
      }
      showDialog(
        context: context,
        builder: (context) {
          return DialogError(
            titulo: "operacion exitosa",
            mensaje: "se han registrado las asistencias-atenciones",
            codigo: 0,
          );
        },
      );*/
      return respuesta;
    } on Exception catch (e) {
      //_mostrarError(context, "fallo al registrar", null);
      return RespuestaModelo.fromException(
        e,
        "POST",
        "registro atenciones",
        "viewmodel",
      );
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
