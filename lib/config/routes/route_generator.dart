import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/clase_grupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseFormulario.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/presentation/view/views/Categorias/CategoriasView.dart';
import 'package:dpt_movil/presentation/view/views/alumnos/AlumnoView.dart';
import 'package:dpt_movil/presentation/view/views/alumnos/alumnosView.dart';
import 'package:dpt_movil/presentation/view/views/categorias/CategoriaFormulario.dart';
import 'package:dpt_movil/presentation/view/views/curso.dart';
import 'package:dpt_movil/presentation/view/views/cursos.dart';
import 'package:dpt_movil/presentation/view/views/estadisticas/estadisticasGeneralesView.dart';
import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';
import 'package:dpt_movil/presentation/view/views/inscripciones/inscripcionesGeneralesView.dart';
import 'package:dpt_movil/presentation/view/views/inscripciones/inscripcionesParticulares.dart';
import 'package:dpt_movil/presentation/view/views/instructores/InstructorView.dart';
import 'package:dpt_movil/presentation/view/views/instructores/InstructoresView.dart';
import 'package:dpt_movil/presentation/view/views/page1.dart';
import 'package:dpt_movil/presentation/view/views/page2.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRutas.page2:
      const String args = "hola";
      return MaterialPageRoute(builder: (_) => const Page2(args));

    case AppRutas.cursos:
      CategoriaEntidad datos = settings.arguments as CategoriaEntidad;
      return MaterialPageRoute(builder: (_) => CursosView(categoria: datos));

    case AppRutas.curso:
      CursoEntidad datos = settings.arguments as CursoEntidad;
      return MaterialPageRoute(builder: (_) => Curso(curso: datos));

    case AppRutas.grupo:
      Grupoentidad datos = settings.arguments as Grupoentidad;
      return MaterialPageRoute(builder: (_) => Grupo(grupo: datos));

    case AppRutas.categorias:
      return MaterialPageRoute(builder: (_) => CategoriasView());

    case AppRutas.InscripcionesGenerales:
      return MaterialPageRoute(builder: (_) => InscripcionesGeneralesView());

    case AppRutas.InscripcionesParticulares:
      return MaterialPageRoute(builder: (_) => InscripcionesParticularesView());

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
      return MaterialPageRoute(
        builder: (_) => CategoriaFormulario(categoria: datos),
      );
    case AppRutas.estadisticasGenerales:
      return MaterialPageRoute(builder: (_) => EstadisticasGeneralesView());

    case AppRutas.clase:
      ClaseGrupoargumentos? datos = settings.arguments as ClaseGrupoargumentos;
      return MaterialPageRoute(
        builder: (_) => Claseview(grupo: datos.grupo, clase: datos.clase),
      );

    case AppRutas.formularioClase:
      Claseentidad datos = settings.arguments as Claseentidad;
      return MaterialPageRoute(builder: (_) => Claseformulario(entidad: datos));

    default:
      return MaterialPageRoute(builder: (_) => Page1());
  }
}
