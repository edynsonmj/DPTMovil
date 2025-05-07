import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:flutter/material.dart';

class Clasesviewmodel with ChangeNotifier {
  final Servicioclase _servicioClase;
  Clasesviewmodel() : _servicioClase = Servicioclase();

  List<Claseentidad> _clases = [];
  List<Claseentidad> get clases => _clases;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  String? _categoria;
  String? _curso;
  int? _anio;
  int? _iterable;
  String? _idInstructor;

  void inicializarGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
    String idInstructor,
  ) {
    _categoria = categoria;
    _curso = curso;
    _anio = anio;
    _iterable = iterable;
    _idInstructor = idInstructor;
  }

  Future<RespuestaModelo> eliminarClase(int id) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await _servicioClase.eliminarClase(id);
      return respuesta;
    } on Exception catch (e) {
      //_mostrarError(context, "fallo al registrar", null);
      return RespuestaModelo.fromException(e, "Delete", "/clase", "viewmodel");
    }
  }

  Future<RespuestaModelo> guardarClase(Claseentidad entidad) async {
    try {
      final respuesta = await _servicioClase.guardarClaseGrupo(entidad);
      if (respuesta.codigoHttp == 201) {
        // Refrescar lista
        await listarYNotificarClases();
      }
      return respuesta;
    } on Exception catch (e) {
      return RespuestaModelo.fromException(e, "POST", "/clase", "viewmodel");
    }
  }

  Future<void> listarYNotificarClases() async {
    if (_categoria == null ||
        _curso == null ||
        _anio == null ||
        _iterable == null) {
      _error = 'Parámetros no inicializados';
      notifyListeners();
      return;
    }
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final respuesta = await _servicioClase.listarClasesGrupo(
        _categoria!,
        _curso!,
        _anio!,
        _iterable!,
      );
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _clases = (respuesta.datos as List).cast<Claseentidad>();
      } else {
        _error =
            'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
        _clases = [];
      }
    } catch (e) {
      _error = e.toString();
      _clases = [];
    }

    _cargando = false;
    notifyListeners();
  }
}
