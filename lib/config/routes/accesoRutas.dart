import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';

//que rol puede abrir cada ruta (AS-01, AU-10). Hasta 2026-11-19 solo el menu
//lateral y algunos botones escondian las opciones; la ruta abria la pantalla
//a cualquiera. La tabla sigue lo que la interfaz ya ofrece a cada rol: no
//agrega reglas nuevas. Las reglas finas (que instructor toma la asistencia de
//que grupo, regla 3.4-1) siguen pendientes con el cliente.
//Una ruta que no esta aqui es publica (categorias, cursos, registro...)
class AccesoRutas {
  AccesoRutas._();

  static const Set<String> _soloCoordinador = {Roles.coordinador};
  static const Set<String> _quienDictaClase = {
    Roles.coordinador,
    Roles.instructor,
  };

  static const Map<String, Set<String>> _roles = {
    //opciones del menu y de las pantallas del coordinador
    AppRutas.instructores: _soloCoordinador,
    AppRutas.instructor: _soloCoordinador,
    AppRutas.InscripcionesGenerales: _soloCoordinador,
    AppRutas.InscripcionesParticulares: _soloCoordinador,
    AppRutas.estadisticasGenerales: _soloCoordinador,
    AppRutas.alumnos: _soloCoordinador,
    AppRutas.alumno: _soloCoordinador,
    //formularios que solo el coordinador ve en categorias, cursos y curso
    AppRutas.curso: _soloCoordinador,
    AppRutas.editarCategoria: _soloCoordinador,
    AppRutas.formularioCurso: _soloCoordinador,
    AppRutas.grupoFormulario: _soloCoordinador,
    //el grupo y sus clases: el coordinador por cursos, el instructor por
    //"Grupos asignados"
    AppRutas.grupo: _quienDictaClase,
    AppRutas.clase: _quienDictaClase,
    AppRutas.formularioClase: _quienDictaClase,
    //las del menu de cada rol, que reciben el id del perfil
    AppRutas.gruposAsignados: {Roles.instructor},
    AppRutas.gruposDisponiblesInscripcion: {Roles.alumno},
  };

  //roles que pueden abrir la ruta; null si es publica
  static Set<String>? rolesDe(String? ruta) => _roles[ruta];

  static bool permite(String? ruta, String? rol) {
    final roles = rolesDe(ruta);
    return roles == null || roles.contains(rol);
  }

  //quien dicta la clase ve y usa los controles de clases del grupo
  static bool dictaClase(String? rol) => _quienDictaClase.contains(rol);
}
