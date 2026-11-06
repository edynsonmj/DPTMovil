import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:flutter/material.dart';

//vm del formulario de clase. Desde la fase 4c listar y eliminar viven en
//DetalleGrupoViewModel (la pantalla del grupo); aqui solo se registra
class Clasesviewmodel with ChangeNotifier {
  final Servicioclase _servicioClase;

  //el servicio sale de la raiz; la ruta formularioClase lo crea y lo
  //inicializa con el grupo que recibe como argumento
  Clasesviewmodel(this._servicioClase);

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

  //punto de entrada del formulario: valida, arma la clase con el grupo que se
  //fijo en inicializarGrupo y la registra. La vista solo entrega lo que hay en
  //pantalla y recibe exito o fallo ya resueltos. El Exito dice si la clase es
  //nueva: con false ya existia en esa fecha y las horas enviadas no se guardaron
  Future<Resultado<bool>> registrarClase({
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
      //no refresca: la pantalla del grupo recarga sus clases al volver
      if (respuesta.codigoHttp == 201) {
        return Exito(true);
      }
      if (respuesta.codigoHttp == 200) {
        return Exito(false);
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
}
