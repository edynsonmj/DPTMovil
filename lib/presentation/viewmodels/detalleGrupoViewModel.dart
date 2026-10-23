import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

//los widgets de la pantalla de grupo leen EstadoSeccion importando este vm
export 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart'
    show EstadoSeccion;

//vm de la pantalla de un grupo (fase 4c): reune lo que antes pedia cada
//widget por su cuenta (curso, horarios, alumnos, clases). Lo crea la ruta
//grupo con el grupo de la pantalla y carga todo una sola vez al entrar
class DetalleGrupoViewModel with ChangeNotifier {
  final Grupoentidad grupo;
  final ServicioCurso _servicioCurso;
  final Serviciohorario _servicioHorario;
  final Servicioalumno _servicioAlumno;
  final Servicioclase _servicioClase;

  DetalleGrupoViewModel(
    this.grupo,
    this._servicioCurso,
    this._servicioHorario,
    this._servicioAlumno,
    this._servicioClase,
  );

  //todas empiezan cargando: la ruta llama a cargar() al crear el vm
  EstadoSeccion<CursoEntidad?> _curso = const EstadoSeccion(null, cargando: true);
  EstadoSeccion<List<Horarioentidad>> _horarios = const EstadoSeccion(
    [],
    cargando: true,
  );
  EstadoSeccion<List<Alumnoentidad>> _alumnos = const EstadoSeccion(
    [],
    cargando: true,
  );
  EstadoSeccion<List<Claseentidad>> _clases = const EstadoSeccion(
    [],
    cargando: true,
  );

  EstadoSeccion<CursoEntidad?> get curso => _curso;
  EstadoSeccion<List<Horarioentidad>> get horarios => _horarios;
  EstadoSeccion<List<Alumnoentidad>> get alumnos => _alumnos;
  EstadoSeccion<List<Claseentidad>> get clases => _clases;

  //las cuatro peticiones van en paralelo; cada seccion notifica al llegar
  Future<void> cargar() async {
    await Future.wait([
      _cargarCurso(),
      _cargarHorarios(),
      _cargarAlumnos(),
      cargarClases(),
    ]);
  }

  Future<void> _cargarCurso() async {
    try {
      final respuesta = await _servicioCurso.obtenerCurso(
        grupo.categoria,
        grupo.curso,
      );
      _curso =
          (respuesta.codigoHttp == 200 && respuesta.datos is CursoEntidad)
              ? EstadoSeccion(respuesta.datos as CursoEntidad)
              : EstadoSeccion(null, error: _mensaje(respuesta));
    } catch (e) {
      _curso = EstadoSeccion(null, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> _cargarHorarios() async {
    try {
      final respuesta = await _servicioHorario.listarHoariosGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      );
      _horarios = _seccionLista<Horarioentidad>(respuesta);
    } catch (e) {
      _horarios = EstadoSeccion([], error: e.toString());
    }
    notifyListeners();
  }

  Future<void> _cargarAlumnos() async {
    try {
      final respuesta = await _servicioAlumno.listarAlumnosGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      );
      _alumnos = _seccionLista<Alumnoentidad>(respuesta);
    } catch (e) {
      _alumnos = EstadoSeccion([], error: e.toString());
    }
    notifyListeners();
  }

  //publica: la pantalla la vuelve a llamar cuando formularioClase vuelve con
  //true, y eliminarClase tras el exito
  Future<void> cargarClases() async {
    if (!_clases.cargando) {
      _clases = EstadoSeccion(_clases.datos, cargando: true);
      notifyListeners();
    }
    try {
      final respuesta = await _servicioClase.listarClasesGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      );
      _clases = _seccionLista<Claseentidad>(respuesta);
    } catch (e) {
      _clases = EstadoSeccion([], error: e.toString());
    }
    notifyListeners();
  }

  Future<Resultado<void>> eliminarClase(int codigo) async {
    try {
      final respuesta = await _servicioClase.eliminarClase(codigo);
      if (respuesta.codigoHttp == 200) {
        await cargarClases();
        return Exito();
      }
      return Fallo(
        respuesta.codigoHttp,
        _mensaje(respuesta),
        origen:
            respuesta.error == null
                ? null
                : '${respuesta.error!.metodo} ${respuesta.error!.url}',
      );
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  //una lista vacia no es un error. /alumnosGrupo y /clasesGrupo responden
  //200 con un objeto (GC-0002 "listado vacio") y la conexion lo devuelve
  //como 406; /horarios responde 200 con []
  EstadoSeccion<List<T>> _seccionLista<T>(RespuestaModelo respuesta) {
    if (respuesta.codigoHttp == 406) {
      return EstadoSeccion(<T>[]);
    }
    if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
      return EstadoSeccion((respuesta.datos as List).cast<T>());
    }
    return EstadoSeccion(<T>[], error: _mensaje(respuesta));
  }

  //la ruta desecha el vm al salir; una peticion que llega despues no debe
  //notificar (ChangeNotifier lanza si se usa tras dispose)
  bool _desechado = false;

  @override
  void dispose() {
    _desechado = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_desechado) super.notifyListeners();
  }

  String _mensaje(RespuestaModelo respuesta) =>
      'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
}
