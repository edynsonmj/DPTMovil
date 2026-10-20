import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
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

  //punto de entrada del formulario: valida, arma la clase con el grupo que se
  //fijo en inicializarGrupo y la registra. La vista solo entrega lo que hay en
  //pantalla y recibe exito o fallo ya resueltos
  Future<Resultado<void>> registrarClase({
    DateTime? fecha,
    required String horasTexto,
  }) async {
    if (fecha == null) {
      return Fallo(0, 'Selecciona la fecha de la clase', origen: 'ViewModel');
    }
    final horas = int.tryParse(horasTexto.trim());
    if (horas == null || horas <= 0) {
      return Fallo(
        0,
        'Ingresa la duracion de la clase en horas (un numero mayor que 0)',
        origen: 'ViewModel',
      );
    }
    if (_categoria == null ||
        _curso == null ||
        _anio == null ||
        _iterable == null ||
        _idInstructor == null) {
      return Fallo(0, 'Grupo no inicializado', origen: 'ViewModel');
    }
    final entidad = Claseentidad(
      idGrupoCategoria: _categoria!,
      idGrupoCurso: _curso!,
      idGrupoAnio: _anio!,
      idGrupoIterable: _iterable!,
      idInstructor: _idInstructor!,
      fecha: fecha,
      horas: horas,
      minutos: 0,
      eliminado: 0,
    );
    try {
      final respuesta = await _servicioClase.guardarClaseGrupo(entidad);
      //tras el exito se refresca la lista, la vista del grupo consume vm.clases
      if (respuesta.codigoHttp == 201) {
        await listarYNotificarClases();
        return Exito();
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
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
