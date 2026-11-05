import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
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

  //punto de entrada del formulario: aplica las reglas que antes vivian en la
  //vista (instructor obligatorio, cupos numericos), arma el grupo del curso y
  //lo registra. La vista entrega lo que hay en pantalla y recibe exito o
  //fallo ya resueltos. [hoy] fija el anio y la fecha de creacion; por
  //defecto el reloj del dispositivo, como antes
  Future<Resultado<Grupoentidad>> registrarGrupo({
    required CursoEntidad curso,
    required String cupos,
    String? idInstructor,
    Grupoentidad? original, //null = crear
    DateTime? hoy,
  }) async {
    //no hay operacion de edicion; ninguna pantalla abre el formulario asi,
    //pero si llega se dice en vez de callar
    if (original != null) {
      return Fallo(0, 'La edicion de grupos aun no esta disponible', origen: 'ViewModel');
    }
    if (idInstructor == null) {
      return Fallo(0, 'Seleccione un instructor', origen: 'ViewModel');
    }
    //el campo solo admite digitos, pero no limita el largo: int.parse lanzaba
    //con un numero que no cabe en un int
    final numeroCupos = int.tryParse(cupos.trim());
    if (numeroCupos == null) {
      return Fallo(0, 'Los cupos deben ser un numero valido', origen: 'ViewModel');
    }
    final fecha = hoy ?? DateTime.now();
    final grupo = Grupoentidad(
      categoria: curso.tituloCategoria,
      curso: curso.nombreCurso,
      anio: fecha.year,
      //el iterable lo asigna el backend
      iterable: 0,
      imagen: curso.imagen,
      cupos: numeroCupos,
      idInstructor: idInstructor,
      fechaCreacion: FormatDate.fechaACadena(fecha, '-'),
    );
    final respuesta = await insertarGrupo(grupo);
    if (respuesta.codigoHttp == 201) {
      return Exito(respuesta.datos is Grupoentidad ? respuesta.datos as Grupoentidad : null);
    }
    final error = respuesta.error;
    return Fallo(
      respuesta.codigoHttp,
      error?.mensaje ?? 'Error desconocido. Código: ${respuesta.codigoHttp}',
      origen: error == null ? null : '${error.metodo} ${error.url}',
    );
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
