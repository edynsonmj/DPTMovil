import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/clase_grupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formCursoArgumentos.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formGrupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/views/autenticacion/AutenticacionView.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseFormulario.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:provider/provider.dart';
import 'package:dpt_movil/presentation/view/views/curso/FormularioCurso.dart';
import 'package:dpt_movil/presentation/view/views/grupo/GrupoFormulario.dart';
import 'package:dpt_movil/presentation/view/views/grupos/GruposAsignados.dart';
import 'package:dpt_movil/presentation/view/views/grupos/GruposInscripcion.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/presentation/view/views/Categorias/CategoriasView.dart';
import 'package:dpt_movil/presentation/view/views/alumnos/AlumnoView.dart';
import 'package:dpt_movil/presentation/view/views/alumnos/alumnosView.dart';
import 'package:dpt_movil/presentation/view/views/categorias/CategoriaFormulario.dart';
import 'package:dpt_movil/presentation/view/views/curso/curso.dart';
import 'package:dpt_movil/presentation/view/views/curso/cursos.dart';
import 'package:dpt_movil/presentation/view/views/estadisticas/estadisticasGeneralesView.dart';
import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';
import 'package:dpt_movil/presentation/view/views/inscripciones/inscripcionesGeneralesView.dart';
import 'package:dpt_movil/presentation/view/views/inscripciones/inscripcionesParticulares.dart';
import 'package:dpt_movil/presentation/view/views/instructores/InstructorView.dart';
import 'package:dpt_movil/presentation/view/views/instructores/InstructoresView.dart';
import 'package:dpt_movil/presentation/view/views/page1.dart';
import 'package:dpt_movil/presentation/view/views/page2.dart';

//vm de categorias por pantalla: lo usan la lista, el formulario y los dos
//filtros de inscripciones, y con uno global se pisaban la lista. Cada ruta
//tiene el suyo; el servicio sale de la raiz (dependencias.dart)
Widget _conCategorias(Widget pantalla) {
  return ChangeNotifierProvider(
    create: (c) => CategoriaViewModel(c.read()),
    child: pantalla,
  );
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRutas.page2:
      const String args = "hola";
      return MaterialPageRoute(builder: (_) => const Page2(args));

    case AppRutas.cursos:
      CategoriaEntidad datos = settings.arguments as CategoriaEntidad;
      //vm por pantalla: solo esta vista lee la lista de cursos, y con uno
      //global dos pantallas de cursos apiladas (menu lateral) compartian la
      //misma lista; al volver se veian los cursos de la otra categoria
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (_) => CursosViewModel(),
              child: CursosView(categoria: datos),
            ),
      );

    case AppRutas.curso:
      CursoEntidad datos = settings.arguments as CursoEntidad;
      //vm por pantalla: el Gruposviewmodel global lo comparten tambien
      //GruposAsignados y GruposInscripcion con otra lista; aqui cada curso
      //tiene la suya y se descarta al salir
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (_) => Gruposviewmodel(),
              child: Curso(curso: datos),
            ),
      );

    case AppRutas.grupo:
      Grupoentidad datos = settings.arguments as Grupoentidad;
      return MaterialPageRoute(builder: (_) => Grupo(grupo: datos));

    case AppRutas.categorias:
      return MaterialPageRoute(builder: (_) => _conCategorias(CategoriasView()));

    case AppRutas.InscripcionesGenerales:
      return MaterialPageRoute(
        builder: (_) => _conCategorias(InscripcionesGeneralesView()),
      );

    case AppRutas.InscripcionesParticulares:
      return MaterialPageRoute(
        builder: (_) => _conCategorias(InscripcionesParticularesView()),
      );

    case AppRutas.alumnos:
      return MaterialPageRoute(builder: (_) => Alumnosview());

    case AppRutas.alumno:
      String datos = settings.arguments.toString();
      return MaterialPageRoute(builder: (_) => Alumnoview(alumno: datos));

    case AppRutas.instructores:
      return MaterialPageRoute(builder: (_) => Instructoresview());

    case AppRutas.instructor:
      String datos = settings.arguments.toString();
      return MaterialPageRoute(
        builder: (_) => Instructorview(instructor: datos),
      );

    case AppRutas.editarCategoria:
      CategoriaEntidad? datos = settings.arguments as CategoriaEntidad?;
      //su propio vm: al guardar hace pop(true) y la lista recarga el suyo
      return MaterialPageRoute(
        builder: (_) => _conCategorias(CategoriaFormulario(categoria: datos)),
      );
    case AppRutas.estadisticasGenerales:
      return MaterialPageRoute(builder: (_) => EstadisticasGeneralesView());

    case AppRutas.clase:
      ClaseGrupoargumentos? datos = settings.arguments as ClaseGrupoargumentos;
      //vm por pantalla: las atenciones solo las usa esta clase, se crea al
      //entrar y provider llama a dispose al salir
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (_) => Atencionviewmodel(),
              child: Claseview(grupo: datos.grupo, clase: datos.clase),
            ),
      );

    case AppRutas.formularioClase:
      //sin argumentos: el grupo lo conoce el vm global, que fijo
      //widgetListaClases con inicializarGrupo
      return MaterialPageRoute(builder: (_) => const Claseformulario());

    case AppRutas.formularioCurso:
      Formcursoargumentos datos = settings.arguments as Formcursoargumentos;
      return MaterialPageRoute(
        builder: (_) => FormularioCurso(argumentos: datos),
      );

    case AppRutas.autenticacionRegistro:
      return MaterialPageRoute(builder: (_) => Autenticacionview());

    case AppRutas.gruposDisponiblesInscripcion:
      String idAlumno = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => Gruposinscripcion(alumnoId: idAlumno),
      );

    case AppRutas.gruposAsignados:
      String idInstructor = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => GruposAsignados(instructorId: idInstructor),
      );

    case AppRutas.grupoFormulario:
      Formgrupoargumentos argumentos =
          settings.arguments as Formgrupoargumentos;
      return MaterialPageRoute(
        builder: (_) => Grupoformulario(argumentos: argumentos),
      );

    case AppRutas.page1:
      //pantalla de desarrollo: ya no es la inicial, la direccion del
      //backend sale de ConfigApi (--dart-define=API_HOST)
      return MaterialPageRoute(builder: (_) => Page1());

    default:
      return MaterialPageRoute(builder: (_) => _conCategorias(CategoriasView()));
  }
}
