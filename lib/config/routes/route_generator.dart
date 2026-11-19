import 'package:dpt_movil/config/routes/accesoRutas.dart';
import 'package:dpt_movil/presentation/view/widgets/rutaProtegida.dart';
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
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:provider/provider.dart';
import 'package:dpt_movil/presentation/view/views/curso/FormularioCurso.dart';
import 'package:dpt_movil/presentation/view/views/grupo/GrupoFormulario.dart';
import 'package:dpt_movil/presentation/view/views/grupos/GruposAsignados.dart';
import 'package:dpt_movil/presentation/view/views/grupos/GruposInscripcion.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/presentation/view/views/categorias/CategoriasView.dart';
import 'package:dpt_movil/presentation/view/views/alumnos/AlumnoView.dart';
import 'package:dpt_movil/presentation/view/views/alumnos/AlumnosView.dart';
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

//rutas de la app. Las que tienen rol en AccesoRutas abren su pantalla dentro
//de RutaProtegida: sin el rol muestran "Acceso restringido" (AS-01, AU-10)
Route<dynamic> generateRoute(RouteSettings settings) {
  final ruta = _construirRuta(settings);
  final roles = AccesoRutas.rolesDe(settings.name);
  if (roles == null || ruta is! MaterialPageRoute) return ruta;
  return MaterialPageRoute(
    settings: settings,
    builder: (c) => RutaProtegida(roles: roles, child: ruta.builder(c)),
  );
}

Route<dynamic> _construirRuta(RouteSettings settings) {
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
              create: (c) => CursosViewModel(c.read()),
              child: CursosView(categoria: datos),
            ),
      );

    case AppRutas.curso:
      CursoEntidad datos = settings.arguments as CursoEntidad;
      //vm por pantalla: cada curso tiene su lista de grupos y se descarta al
      //salir (desde la fase 6 ya no hay Gruposviewmodel global)
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (c) => Gruposviewmodel(c.read()),
              child: Curso(curso: datos),
            ),
      );

    case AppRutas.grupo:
      Grupoentidad datos = settings.arguments as Grupoentidad;
      //un vm para toda la pantalla: curso, horarios, alumnos y clases del
      //grupo, cargados una vez al entrar y descartados al salir
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create:
                  (c) => DetalleGrupoViewModel(
                    datos,
                    c.read(),
                    c.read(),
                    c.read(),
                    c.read(),
                  )..cargar(),
              child: Grupo(grupo: datos),
            ),
      );

    case AppRutas.categorias:
      return MaterialPageRoute(
        builder: (_) => _conCategorias(CategoriasView()),
      );

    case AppRutas.InscripcionesGenerales:
      return MaterialPageRoute(
        builder: (_) => _conCategorias(InscripcionesGeneralesView()),
      );

    case AppRutas.InscripcionesParticulares:
      //vms propios de la pantalla: las categorias del filtro y los grupos con
      //su periodo de inscripcion; ambos cargan una vez al entrar
      return MaterialPageRoute(
        builder:
            (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create:
                      (c) =>
                          CategoriaViewModel(c.read())
                            ..listarYNotificarCategorias(),
                ),
                ChangeNotifierProvider(
                  create:
                      (c) => PeriodoInscripcionViewModel(c.read())..cargar(),
                ),
              ],
              child: InscripcionesParticularesView(),
            ),
      );

    case AppRutas.alumnos:
      return MaterialPageRoute(builder: (_) => Alumnosview());

    case AppRutas.alumno:
      String datos = settings.arguments.toString();
      return MaterialPageRoute(builder: (_) => Alumnoview(alumno: datos));

    case AppRutas.instructores:
      //vm por pantalla: carga los instructores del backend al abrir (IT-03)
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create:
                  (c) =>
                      InstructoresViewModel(c.read())
                        ..listarYNotificarInstructores(),
              child: const Instructoresview(),
            ),
      );

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
      //vm por pantalla: solo esta vista usa las estadisticas; provider
      //llama a dispose al salir
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (c) => EstadisticasViewModel(c.read()),
              child: EstadisticasGeneralesView(),
            ),
      );

    case AppRutas.clase:
      ClaseGrupoargumentos? datos = settings.arguments as ClaseGrupoargumentos;
      //vm por pantalla: las atenciones solo las usa esta clase. Se crea al
      //entrar, ya cargando con el grupo y la clase del argumento, y provider
      //llama a dispose al salir
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create:
                  (c) =>
                      Atencionviewmodel(c.read())
                        ..cargarAtenciones(datos.grupo, datos.clase),
              child: Claseview(grupo: datos.grupo, clase: datos.clase),
            ),
      );

    case AppRutas.formularioClase:
      Grupoentidad grupo = settings.arguments as Grupoentidad;
      //vm propio del formulario, inicializado con el grupo que llega como
      //argumento; carga sus horarios para saber que dias piden justificacion
      //(BK-04). Al guardar hace pop(true) y la pantalla del grupo recarga
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create:
                  (c) =>
                      Clasesviewmodel(c.read(), c.read())
                        ..inicializarGrupo(
                          grupo.categoria,
                          grupo.curso,
                          grupo.anio,
                          grupo.iterable,
                          grupo.idInstructor!,
                        )
                        ..cargarHorarios(),
              child: const Claseformulario(),
            ),
      );

    case AppRutas.formularioCurso:
      Formcursoargumentos datos = settings.arguments as Formcursoargumentos;
      //vms propios del formulario: al guardar hace pop(true) y la lista de
      //cursos recarga el suyo
      return MaterialPageRoute(
        builder:
            (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (c) => CursosViewModel(c.read()),
                ),
                ChangeNotifierProvider(
                  create: (c) => Deporteviewmodel(c.read())..cargar(),
                ),
              ],
              child: FormularioCurso(argumentos: datos),
            ),
      );

    case AppRutas.autenticacionRegistro:
      //vm por pantalla: las facultades solo las usa el registro
      return MaterialPageRoute(
        builder:
            (_) => ChangeNotifierProvider(
              create: (c) => Facultadesviewmodel(c.read()),
              child: Autenticacionview(),
            ),
      );

    case AppRutas.gruposDisponiblesInscripcion:
      String idAlumno = settings.arguments as String;
      //vms propios de la pantalla del alumno: grupos disponibles, horarios
      //de cada tarjeta y su estado de inscripcion
      return MaterialPageRoute(
        builder:
            (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (c) => Gruposviewmodel(c.read()),
                ),
                ChangeNotifierProvider(
                  create: (c) => Horariosviewmodel(c.read()),
                ),
                ChangeNotifierProvider(
                  create: (c) => Inscripcionviewmodel(c.read()),
                ),
              ],
              child: Gruposinscripcion(alumnoId: idAlumno),
            ),
      );

    case AppRutas.gruposAsignados:
      String idInstructor = settings.arguments as String;
      //vms propios de la pantalla del instructor: sus grupos y los horarios
      //de cada tarjeta
      return MaterialPageRoute(
        builder:
            (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (c) => Gruposviewmodel(c.read()),
                ),
                ChangeNotifierProvider(
                  create: (c) => Horariosviewmodel(c.read()),
                ),
              ],
              child: GruposAsignados(instructorId: idInstructor),
            ),
      );

    case AppRutas.grupoFormulario:
      Formgrupoargumentos argumentos =
          settings.arguments as Formgrupoargumentos;
      //vms propios del formulario: al guardar hace pop(true) y la pantalla
      //del curso recarga su lista
      return MaterialPageRoute(
        builder:
            (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (c) => Gruposviewmodel(c.read()),
                ),
                ChangeNotifierProvider(
                  create: (c) => InstructoresViewModel(c.read()),
                ),
              ],
              child: Grupoformulario(argumentos: argumentos),
            ),
      );

    case AppRutas.page1:
      //pantalla de desarrollo: ya no es la inicial, la direccion del
      //backend sale de ConfigApi (--dart-define=API_HOST)
      return MaterialPageRoute(builder: (_) => Page1());

    default:
      return MaterialPageRoute(
        builder: (_) => _conCategorias(CategoriasView()),
      );
  }
}
