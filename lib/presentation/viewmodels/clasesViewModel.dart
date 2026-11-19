import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

//vm del formulario de clase. Desde la fase 4c listar y eliminar viven en
//DetalleGrupoViewModel (la pantalla del grupo); aqui solo se registra
class Clasesviewmodel with ChangeNotifier, NotificacionSegura {
  final Servicioclase _servicioClase;
  final Serviciohorario _servicioHorario;

  //los servicios salen de la raiz; la ruta formularioClase crea el vm, lo
  //inicializa con el grupo que recibe como argumento y carga sus horarios
  Clasesviewmodel(this._servicioClase, this._servicioHorario);

  //limites del backend para la justificacion (ClaseServicio)
  static const int justificacionMinima = 10;
  static const int justificacionMaxima = 500;

  String? _categoria;
  String? _curso;
  int? _anio;
  int? _iterable;
  String? _idInstructor;

  //dias de la semana (DateTime.weekday) en los que el grupo tiene horario.
  //null mientras no se sepa: sin cargar o con error
  Set<int>? _diasConHorario;
  bool _cargandoHorarios = false;

  bool get cargandoHorarios => _cargandoHorarios;

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

  //el backend exige justificacion cuando el grupo no tiene horario el dia de
  //la clase (BK-04). Para saberlo antes de enviar, el formulario carga los
  //horarios del grupo una vez. Si fallan, la regla queda en manos del backend
  Future<void> cargarHorarios() async {
    if (_categoria == null) return;
    _cargandoHorarios = true;
    notifyListeners();
    try {
      final respuesta = await _servicioHorario.listarHoariosGrupo(
        _categoria!,
        _curso!,
        _anio!,
        _iterable!,
      );
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _diasConHorario =
            (respuesta.datos as List)
                .whereType<Horarioentidad>()
                .map((h) => numeroDia(h.dia))
                .whereType<int>()
                .toSet();
      }
    } catch (_) {
      //sin horarios no se decide: el campo queda opcional
    }
    _cargandoHorarios = false;
    notifyListeners();
  }

  //true: ese dia no hay horario y la justificacion es obligatoria; false: hay
  //horario y el backend calcula la duracion; null: no se sabe todavia
  bool? requiereJustificacion(DateTime? fecha) {
    final dias = _diasConHorario;
    if (fecha == null || dias == null) return null;
    return !dias.contains(fecha.weekday);
  }

  //dia de un horario → DateTime.weekday, con la misma regla del backend
  //(CalculadoraDuracionClase: equalsIgnoreCase contra 'LUNES'..'DOMINGO', sin
  //tildes). Asi la app pide justificacion justo cuando el backend la exige.
  //Por eso 'Miércoles' y 'Sábado', que envia el formulario de horarios, no
  //cuentan como horario (bug HO-06 en registro-bugs.md)
  static int? numeroDia(String dia) {
    const dias = [
      'LUNES',
      'MARTES',
      'MIERCOLES',
      'JUEVES',
      'VIERNES',
      'SABADO',
      'DOMINGO',
    ];
    final i = dias.indexOf(dia.toUpperCase());
    return i < 0 ? null : i + 1;
  }

  //punto de entrada del formulario: valida, arma la clase con el grupo que se
  //fijo en inicializarGrupo y la registra. La vista solo entrega lo que hay en
  //pantalla y recibe exito o fallo ya resueltos. El Exito dice si la clase es
  //nueva: con false ya existia en esa fecha y las horas enviadas no se guardaron
  Future<Resultado<bool>> registrarClase({
    DateTime? fecha,
    required String horasTexto,
    String? justificacion,
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
    //el backend rechaza espacios al inicio o al final: se recortan aqui
    final texto = justificacion?.trim() ?? '';
    final requiere = requiereJustificacion(fecha);
    if (requiere == true && texto.isEmpty) {
      return Fallo(
        0,
        'El grupo no tiene horario ese dia: escribe por que se dicto la clase',
        origen: 'ViewModel',
      );
    }
    if (requiere != false &&
        texto.isNotEmpty &&
        (texto.length < justificacionMinima ||
            texto.length > justificacionMaxima)) {
      return Fallo(
        0,
        'La justificacion debe tener entre $justificacionMinima y '
        '$justificacionMaxima caracteres',
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
      //con horario ese dia el backend la ignora: no se envia
      justificacion: requiere != false && texto.isNotEmpty ? texto : null,
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
