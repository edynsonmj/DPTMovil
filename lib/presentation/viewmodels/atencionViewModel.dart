import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

//estado de la pantalla de una clase: se crea con la ruta AppRutas.clase y se
//descarta al salir, asi que no arrastra las atenciones de otra clase
//NotificacionSegura (fase 8): la ruta lo desecha al salir y una carga que
//llega despues no notifica
class Atencionviewmodel with ChangeNotifier, NotificacionSegura {
  final Servicioatencion _servicioAtencion;

  //el servicio sale de la raiz; la ruta crea el vm y llama a cargarAtenciones
  //con el grupo y la clase que recibe como argumento
  Atencionviewmodel(this._servicioAtencion);

  //null = aun no se ha cargado
  List<Atencionentidad>? _atenciones;
  List<Atencionentidad>? get atenciones => _atenciones;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  //clase a la que pertenecen las atenciones, se fija al cargar y se reutiliza
  //al registrar
  int? _idClase;

  Future<void> cargarAtenciones(Grupoentidad grupo, Claseentidad clase) async {
    if (clase.codigo == null) {
      _error = 'La clase no tiene codigo, no se pueden cargar sus atenciones';
      notifyListeners();
      return;
    }
    _idClase = clase.codigo;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final respuesta = await _servicioAtencion.listarAtencionesClase(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
        clase.codigo!,
      );
      //al 2026-10-23 el backend no tiene este endpoint y responde 404: queda
      //como error. Revisar como llega la lista vacia cuando se agregue
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _atenciones = (respuesta.datos as List).cast<Atencionentidad>();
      } else {
        _error =
            'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
        _atenciones = [];
      }
    } catch (e) {
      _error = e.toString();
      _atenciones = [];
    }
    _cargando = false;
    notifyListeners();
  }

  //la vista solo informa el cambio del checkbox; la entidad la modifica el vm
  void marcarAsistencia(int indice, bool valor) {
    final lista = _atenciones;
    if (lista == null || indice < 0 || indice >= lista.length) return;
    lista[indice].estaAtendido = valor;
    notifyListeners();
  }

  //registra las atenciones cargadas con su estado actual
  Future<Resultado<void>> registrarAtenciones() async {
    final lista = _atenciones;
    if (lista == null || _idClase == null) {
      return Fallo(0, 'No hay atenciones cargadas', origen: 'ViewModel');
    }
    if (lista.isEmpty) {
      return Fallo(0, 'No hay alumnos para registrar', origen: 'ViewModel');
    }
    try {
      final respuesta = await _servicioAtencion.registrarAtenciones(
        lista,
        _idClase!,
      );
      if (respuesta.codigoHttp == 200) return Exito();
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
