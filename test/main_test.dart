// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAlumnosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionDeporteRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionEstadisticasRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionFacultadRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionInscripcionRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionInstructoresRemoto.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/deporteRepositorio.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioDeporte.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles/conexionCategoriaLocal.dart';
import 'dobles/googleSignInFalso.dart';
import 'local/viewModel/categoria/vmListarCategoriaLocalTest.dart';
import 'remoto/viewModel/categoria/vmActualizarCategoriaTest.dart';
import 'remoto/viewModel/clase/vmRegistrarClaseTest.dart';
import 'remoto/viewModel/curso/vmCursoTest.dart';
import 'remoto/viewModel/deporte/vmListarDeportesTest.dart';
import 'remoto/viewModel/atencion/vmAtencionTest.dart';
import 'remoto/viewModel/autenticacion/vmLoginTest.dart';
import 'remoto/viewModel/facultades/vmListarFacultadesTest.dart';
import 'remoto/viewModel/grupo/vmListarGruposTest.dart';
import 'remoto/viewModel/grupo/vmModuloGrupoTest.dart';
import 'remoto/viewModel/inscripcion/vmGruposInscripcionTest.dart';
import 'remoto/viewModel/inscripcion/vmInscripcionTest.dart';
import 'remoto/viewModel/estadisticas/vmEstadisticasAsistenciaTest.dart';
import 'remoto/viewModel/grupo/vmGrupoDiagnosticoTest.dart';
import 'remoto/viewModel/curso/vmCursoDiagnosticoTest.dart';
import 'remoto/viewModel/categoria/vmCategoriaDiagnosticoTest.dart';
import 'remoto/viewModel/clase/vmClaseDiagnosticoTest.dart';
import 'remoto/viewModel/horario/vmHorarioDiagnosticoTest.dart';
import 'remoto/viewModel/alumno/vmAlumnoDiagnosticoTest.dart';
import 'remoto/viewModel/instructor/vmInstructorDiagnosticoTest.dart';
import 'remoto/viewModel/grupo/vmPeriodoInscripcionTest.dart';
import 'remoto/viewModel/estadisticas/vmEstadisticasTest.dart';
import 'remoto/viewModel/categoria/vmEliminarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmListarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmGuardarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmGuardarFormularioCategoriaTest.dart';

//direccion del backend de pruebas: cada vm recibe un Dio armado aqui, sin
//pasar por ConfigServicio (desde la fase 7 no queda ningun modulo sin
//migrar)
const String baseUrlPruebas = 'http://localhost:8082/api/v2';

//misma cadena que arma la raiz de composicion, con la conexion indicada
CategoriaViewModel crearCategoriaViewModel(ConexionCategoria conexion) {
  return CategoriaViewModel(
    ServicioCategoria(CategoriaRepositorio(cliente: conexion)),
  );
}

void main() {
  probarViewModelCategoriaLocal();
  probarViewModelCategoria();
  probarViewModelClase();
  probarViewModelAtencion();
  probarViewModelGrupo();
  probarViewModelFacultades();
  probarViewModelAutenticacion();
  probarViewModelDeporte();
  probarViewModelCurso();
  probarViewModelModuloGrupo();
  probarViewModelGruposInscripcion();
  probarViewModelPeriodoInscripcion();
  probarViewModelInscripcion();
  probarViewModelEstadisticas();
  probarViewModelGrupoDiagnostico();
  probarViewModelCursoDiagnostico();
  probarViewModelCategoriaDiagnostico();
  probarViewModelClaseDiagnostico();
  probarViewModelHorarioDiagnostico();
  probarViewModelAlumnoDiagnostico();
  probarViewModelInstructorDiagnostico();
}
//misma cadena que la raiz, con el Dio de pruebas; un vm por caso, como la
//ruta InscripcionesParticulares
PeriodoInscripcionViewModel crearPeriodoInscripcionViewModel() =>
    PeriodoInscripcionViewModel(
      Serviciogrupo(
        Gruporepositorio(
          conexion: Conexiongruposremoto(crearClienteHttp(baseUrlPruebas)),
        ),
      ),
    );
probarViewModelPeriodoInscripcion(){
  //categoria, curso y grupo solo arman los datos de apoyo
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  group('Periodo de inscripcion remoto:', () {
    VmPeriodoInscripcionTest test = VmPeriodoInscripcionTest();
    test.preparar(
      vmCategoria: crearCategoriaViewModel(
        ConexionCategoriaRemota(dio, conexionImagen),
      ),
      crearVmDeporte: crearDeporteViewModel,
      crearVmCurso: () => CursosViewModel(
        ServicioCurso(
          CursoRepositorio(cliente: ConexionCursoRemoto(dio, conexionImagen)),
        ),
      ),
      crearVmInstructores: crearInstructoresViewModel,
      crearVmGrupos: crearGruposViewModel,
      crearVm: crearPeriodoInscripcionViewModel,
    );
    test.prueba1GrupoNuevoSinPeriodo(crearPeriodoInscripcionViewModel, crearGruposViewModel);
    test.prueba2AbrirDesdeHoy(crearPeriodoInscripcionViewModel, crearGruposViewModel);
    test.prueba3CierreHoy(crearPeriodoInscripcionViewModel, crearGruposViewModel);
    test.prueba4Programar(crearPeriodoInscripcionViewModel, crearGruposViewModel);
    test.prueba5CierreAntesDeApertura(crearPeriodoInscripcionViewModel);
    test.prueba6Cerrar(crearPeriodoInscripcionViewModel, crearGruposViewModel);
    test.prueba7GrupoInexistente(crearPeriodoInscripcionViewModel);
  });
}
//misma cadena que la raiz, con el Dio de pruebas; un vm por caso, como la
//ruta estadisticasGenerales
EstadisticasViewModel crearEstadisticasViewModel() => EstadisticasViewModel(
  ServicioEstadisticas(
    EstadisticasRespositorio(
      conexion: Conexionestadisticasremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
probarViewModelEstadisticas(){
  group('Estadisticas generales remotas:', () {
    VmEstadisticasTest test = VmEstadisticasTest();
    test.prueba1Categorias(crearEstadisticasViewModel);
    test.prueba2GruposParaExportar(crearEstadisticasViewModel);
    test.prueba3RangoSinClases(crearEstadisticasViewModel);
    test.prueba4FechaMalFormada(crearEstadisticasViewModel);
  });
  //diagnostico del modulo 5 (plan-diagnostico-estadisticas.md): su propio
  //grupo con una clase y asistencias reales por corrida
  group('Estadisticas con asistencias remotas:', () {
    VmEstadisticasAsistenciaTest test = VmEstadisticasAsistenciaTest();
    prepararVmEstadisticasAsistencia(test);
    test.prueba1AsistenciaContada(crearEstadisticasViewModel);
    test.prueba2TotalesCuadran(crearEstadisticasViewModel);
    test.prueba4RangoSinLaClase(crearEstadisticasViewModel);
    test.prueba5AsistenciaRepetida(crearEstadisticasViewModel);
    test.prueba6DosAsistencias(crearEstadisticasViewModel);
    //el caso rojo (ES-05) va en
    //test/diagnostico/estadisticas/remoto_diagnostico_test.dart
  });
}
//datos de apoyo del diagnostico de estadisticas; tambien lo usa
//test/diagnostico/estadisticas/remoto_diagnostico_test.dart
void prepararVmEstadisticasAsistencia(VmEstadisticasAsistenciaTest test) {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  test.preparar(
    dio: dio,
    vmCategoria: crearCategoriaViewModel(
      ConexionCategoriaRemota(dio, conexionImagen),
    ),
    crearVmDeporte: crearDeporteViewModel,
    crearVmCurso: () => CursosViewModel(
      ServicioCurso(
        CursoRepositorio(cliente: ConexionCursoRemoto(dio, conexionImagen)),
      ),
    ),
    crearVmInstructores: crearInstructoresViewModel,
    crearVmGrupos: crearGruposViewModel,
    crearVmFacultades: () => Facultadesviewmodel(
      Serviciofacultades(
        Facultadesrepositorio(conexion: Conexionfacultadremoto(dio)),
      ),
    ),
    crearVmPeriodo: crearPeriodoInscripcionViewModel,
    crearVmInscripcion: crearInscripcionViewModel,
    crearVmClase: crearClasesViewModel,
    crearVmDetalle: crearDetalleGrupoViewModel,
    servicioAutenticacion: Servicioautenticacion(
      Autenticacionrepositorio(conexion: Conexionautenticacionremoto(dio)),
    ),
  );
}
//misma cadena que la raiz, con el Dio de pruebas; un vm por caso, como la
//ruta gruposDisponiblesInscripcion
Inscripcionviewmodel crearInscripcionViewModel() => Inscripcionviewmodel(
  Servicioinscripcion(
    Inscripcionrepositorio(
      conexion: Conexioninscripcionremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
probarViewModelGruposInscripcion(){
  //categoria, curso, grupo y alumno solo arman los datos de apoyo
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  Facultadesviewmodel crearVmFacultades() => Facultadesviewmodel(
    Serviciofacultades(
      Facultadesrepositorio(conexion: Conexionfacultadremoto(dio)),
    ),
  );
  group('Grupos asignados e inscripcion remotos:', () {
    VmGruposInscripcionTest test = VmGruposInscripcionTest();
    test.preparar(
      vmCategoria: crearCategoriaViewModel(
        ConexionCategoriaRemota(dio, conexionImagen),
      ),
      crearVmDeporte: crearDeporteViewModel,
      crearVmCurso: () => CursosViewModel(
        ServicioCurso(
          CursoRepositorio(cliente: ConexionCursoRemoto(dio, conexionImagen)),
        ),
      ),
      crearVmInstructores: crearInstructoresViewModel,
      crearVmGrupos: crearGruposViewModel,
      crearVmFacultades: crearVmFacultades,
      servicioAutenticacion: Servicioautenticacion(
        Autenticacionrepositorio(conexion: Conexionautenticacionremoto(dio)),
      ),
    );
    test.prueba1GruposDelInstructor(crearGruposViewModel);
    test.prueba2GruposDisponibles(crearGruposViewModel);
    test.prueba3SinInscripcionesAbiertas(crearInscripcionViewModel);
    test.prueba4CicloInscripcion(
      crearInscripcionViewModel,
      crearPeriodoInscripcionViewModel,
    );
  });
}
//diagnostico del modulo 4 (plan-diagnostico-inscripciones.md): su propio
//grupo de datos por corrida
probarViewModelInscripcion(){
  group('Inscripcion del alumno remota:', () {
    VmInscripcionTest test = VmInscripcionTest();
    prepararVmInscripcion(test);
    test.prueba1InscribirDosVeces(crearInscripcionViewModel);
    test.prueba2DesvincularYReactivar(crearInscripcionViewModel);
    test.prueba3DesvincularSinInscripcion(crearInscripcionViewModel);
    test.prueba4CupoLleno(crearInscripcionViewModel);
    test.prueba5Inexistentes(crearInscripcionViewModel);
    test.prueba6OrigenDelError(crearInscripcionViewModel);
    test.prueba7CargarEstados(crearInscripcionViewModel);
    //el caso rojo (IN-13) va en
    //test/diagnostico/inscripciones/remoto_diagnostico_test.dart
  });
}
//datos de apoyo (categoria, curso, grupos y alumnos); tambien lo usa el
//diagnostico remoto de inscripciones
void prepararVmInscripcion(VmInscripcionTest test) {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  test.preparar(
    vmCategoria: crearCategoriaViewModel(
      ConexionCategoriaRemota(dio, conexionImagen),
    ),
    crearVmDeporte: crearDeporteViewModel,
    crearVmCurso: () => CursosViewModel(
      ServicioCurso(
        CursoRepositorio(cliente: ConexionCursoRemoto(dio, conexionImagen)),
      ),
    ),
    crearVmInstructores: crearInstructoresViewModel,
    crearVmGrupos: crearGruposViewModel,
    crearVmFacultades: () => Facultadesviewmodel(
      Serviciofacultades(
        Facultadesrepositorio(conexion: Conexionfacultadremoto(dio)),
      ),
    ),
    crearVmPeriodo: crearPeriodoInscripcionViewModel,
    servicioAutenticacion: Servicioautenticacion(
      Autenticacionrepositorio(conexion: Conexionautenticacionremoto(dio)),
    ),
  );
}
//misma cadena que la raiz para el modulo grupo, con el Dio de pruebas; un
//vm por caso, como cada ruta
Gruposviewmodel crearGruposViewModel() => Gruposviewmodel(
  Serviciogrupo(
    Gruporepositorio(
      conexion: Conexiongruposremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
Horariosviewmodel crearHorariosViewModel() => Horariosviewmodel(
  Serviciohorario(
    Horariorepositorio(
      conexion: Conexionhorariosremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
Alumnosviewmodel crearAlumnosViewModel() => Alumnosviewmodel(
  Servicioalumno(
    Alumnosrepositorio(
      cliente: Conexionalumnosremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
Clasesviewmodel crearClasesViewModel() => Clasesviewmodel(
  Servicioclase(
    Claserepositorio(
      cliente: Conexionclasesremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
DetalleGrupoViewModel crearDetalleGrupoViewModel(Grupoentidad grupo) {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  return DetalleGrupoViewModel(
    grupo,
    ServicioCurso(
      CursoRepositorio(
        cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)),
      ),
    ),
    Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
    Servicioalumno(Alumnosrepositorio(cliente: Conexionalumnosremoto(dio))),
    Servicioclase(Claserepositorio(cliente: Conexionclasesremoto(dio))),
  );
}
InstructoresViewModel crearInstructoresViewModel() => InstructoresViewModel(
  ServicioInstructor(
    Instructoresrepositorio(
      conexion: Conexioninstructoresremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
probarViewModelModuloGrupo(){
  //categoria, curso y deporte solo arman los datos de apoyo
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  CategoriaViewModel vmCategoria = crearCategoriaViewModel(
    ConexionCategoriaRemota(dio, conexionImagen),
  );
  CursosViewModel crearVmCurso() => CursosViewModel(
    ServicioCurso(
      CursoRepositorio(cliente: ConexionCursoRemoto(dio, conexionImagen)),
    ),
  );
  group('Modulo grupo remoto:', () {
    VmModuloGrupoTest test = VmModuloGrupoTest();
    test.preparar(
      vmCategoria,
      crearDeporteViewModel,
      crearVmCurso,
      crearInstructoresViewModel,
    );
    test.prueba1ListarInstructores(crearInstructoresViewModel);
    test.prueba2InsertarGrupo201(crearGruposViewModel);
    test.prueba3HorariosGrupoNuevo(crearHorariosViewModel);
    test.prueba4AlumnosGrupoNuevo(crearAlumnosViewModel);
    test.prueba4bPantallaGrupoNuevo(crearDetalleGrupoViewModel);
    test.prueba5RegistrarClase201(
      crearClasesViewModel,
      crearDetalleGrupoViewModel,
    );
    test.prueba6EliminarClase200(crearDetalleGrupoViewModel);
  });
}
//misma cadena que la raiz, con el Dio de pruebas; un vm por caso, como
//la ruta formularioCurso
Deporteviewmodel crearDeporteViewModel() => Deporteviewmodel(
  Serviciodeporte(
    Deporterepositorio(
      cliente: Conexiondeporteremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
probarViewModelDeporte(){
  group('Listar deportes:', () {
    VmListarDeportesTest test = VmListarDeportesTest();
    test.prueba1codigo200(crearDeporteViewModel);
  });
}
probarViewModelCurso(){
  //el mismo cliente para cursos, categorias e imagenes, como en la raiz
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  CategoriaViewModel vmCategoria = crearCategoriaViewModel(
    ConexionCategoriaRemota(dio, conexionImagen),
  );
  CursosViewModel crearVm() => CursosViewModel(
    ServicioCurso(
      CursoRepositorio(cliente: ConexionCursoRemoto(dio, conexionImagen)),
    ),
  );
  group('Cursos remotos:', () {
    VmCursoTest test = VmCursoTest();
    test.preparar(vmCategoria, crearDeporteViewModel);
    test.prueba1Agregar201(crearVm);
    test.prueba2ListarCursosDe(crearVm);
    test.prueba3ObtenerCurso(crearVm);
  });
}
probarViewModelFacultades(){
  //misma cadena que la raiz, con el Dio de pruebas; un vm por caso, como
  //la ruta autenticacionRegistro
  Facultadesviewmodel crearVm() => Facultadesviewmodel(
    Serviciofacultades(
      Facultadesrepositorio(
        conexion: Conexionfacultadremoto(crearClienteHttp(baseUrlPruebas)),
      ),
    ),
  );
  group('Listar facultades:', () {
    VmListarFacultadesTest test = VmListarFacultadesTest();
    test.prueba1codigo200(crearVm);
  });
}
probarViewModelAutenticacion(){
  //el login por correo no usa Google: basta el doble, sin plugin nativo
  AutenticacionViewModel crearVm() => AutenticacionViewModel(
    Servicioautenticacion(
      Autenticacionrepositorio(
        conexion: Conexionautenticacionremoto(crearClienteHttp(baseUrlPruebas)),
      ),
    ),
    GoogleSignInFalso(),
  );
  group('Login por correo:', () {
    VmLoginTest test = VmLoginTest();
    test.prueba1NoRegistrado404(crearVm);
    test.prueba2SinCorreo(crearVm);
  });
}
probarViewModelGrupo(){
  //el caso hace una peticion real, pero solo comprueba el estado del vm,
  //no los datos de la bd
  group('Listar grupos de un curso:', () {
    VmListarGruposTest test = VmListarGruposTest();
    test.prueba1EstadoDuranteCarga(crearGruposViewModel);
  });
}
//misma cadena que la raiz, con el Dio de pruebas; un vm por caso, como la
//ruta clase
Atencionviewmodel crearAtencionViewModel() => Atencionviewmodel(
  Servicioatencion(
    Atencionesrepositorio(
      conexion: Conexionatencionesremoto(crearClienteHttp(baseUrlPruebas)),
    ),
  ),
);
probarViewModelAtencion(){
  //los tres primeros casos no llegan a hacer peticiones; el cuarto si
  group('Atenciones de clase:', () {
    VmAtencionTest test = VmAtencionTest();
    test.prueba1RegistrarSinCargar(crearAtencionViewModel);
    test.prueba2ClaseSinCodigo(crearAtencionViewModel);
    test.prueba3MarcarSinLista(crearAtencionViewModel);
    test.prueba4ClaseInexistente(crearAtencionViewModel);
  });
}
probarViewModelClase(){
  //el vm se construye con la conexion remota, aunque estos casos no llegan
  //a hacer peticiones
  Clasesviewmodel vm = crearClasesViewModel();
  group('Registrar clase (validaciones):', () {
    VmRegistrarClaseTest test = VmRegistrarClaseTest();
    test.prueba1SinFecha(vm);
    test.prueba2HorasVacias(vm);
    test.prueba3HorasNoNumericas(vm);
    test.prueba4HorasEnCero(vm);
    test.prueba5GrupoNoInicializado(vm);
  });
}
probarViewModelCategoriaLocal(){
  //el doble se inyecta directo: ya no depende de la fabrica ni del orden
  CategoriaViewModel vm = crearCategoriaViewModel(ConexionCategoriaLocal());
  group('Listar categorias locales:', () {
    VmListarCategoriaLocalTest test = VmListarCategoriaLocalTest();
    test.prueba1ListaVacia204(vm);
    test.prueba2EntradasVacias(vm);
  });
}
probarViewModelCategoria(){
  //el mismo cliente para categorias e imagenes, como en la raiz
  Dio dio = crearClienteHttp(baseUrlPruebas);
  CategoriaViewModel vm = crearCategoriaViewModel(
    ConexionCategoriaRemota(dio, Conexionimagenremoto(dio)),
  );
  grupoVMCategoriaRegistrar(vm);
}
grupoVMCategoriaRegistrar(CategoriaViewModel vm){
  group('Listar categorias remotas:', () {
    VmListarCategoriaTest test = VmListarCategoriaTest();
    test.prueba1codigo200(vm);
    test.prueba2ReflejaInsercion(vm);
    test.prueba3ListaEntradas(vm);
  });
  group('Guardar categoria remota:', () {
    VmGuardarCategoriaTest test = VmGuardarCategoriaTest();
    test.prueba1codigo201(vm);
    test.prueba2SinImagen(vm);
    test.prueba3SinTitulo(vm);
    test.prueba4SinDescripcion(vm);
  });
  group('Actualizar categoria remota:', () {
    VmActualizarCategoriaTest test = VmActualizarCategoriaTest();
    test.prueba1codigo200(vm);
    test.prueba2CambioImagen(vm);
    test.prueba3Inexistente(vm);
    test.prueba4DescripcionVacia(vm);
    test.prueba5TituloVacio(vm);
    test.prueba6SinImagen(vm);
  });
  group('Guardar categoria desde formulario:', () {
    VmGuardarFormularioCategoriaTest test = VmGuardarFormularioCategoriaTest();
    test.prueba1CrearExito(vm);
    test.prueba2CrearSinImagen(vm);
    test.prueba3CrearRecortaEspacios(vm);
    test.prueba4EditarSinImagenNueva(vm);
    test.prueba5EditarConImagenNueva(vm);
    test.prueba6EditarSinNingunaImagen(vm);
    test.prueba7EditarUsaTituloOriginal(vm);
    test.prueba8UrlImagen(vm);
  });
  group('Eliminar categoria remota:', () {
    VmEliminarCategoriaTest test = VmEliminarCategoriaTest();
    test.prueba1codigo200(vm);
    test.prueba2Inexistente(vm);
    test.prueba3TituloVacio(vm);
  });
}
//diagnostico del modulo 3 (plan-diagnostico-grupos.md): su propio juego de
//categorias, cursos y grupos por corrida
probarViewModelGrupoDiagnostico(){
  group('Grupos remotos (diagnostico):', () {
    VmGrupoDiagnosticoTest test = VmGrupoDiagnosticoTest();
    prepararVmGrupoDiagnostico(test);
    test.prueba1ListarGruposDelCurso(crearGruposViewModel);
    test.prueba2SegundoGrupo(crearGruposViewModel);
    test.prueba3ListasVacias(crearGruposViewModel);
    test.prueba4PantallaDelGrupo(crearDetalleGrupoViewModel);
    test.prueba5CuposEnCero(crearGruposViewModel);
    test.prueba6DatosInexistentes(crearGruposViewModel);
    test.prueba7FechaFinalizacion(crearGruposViewModel);
    //los casos rojos van en test/diagnostico/grupos/remoto_diagnostico_test.dart
  });
}
//datos de apoyo del diagnostico de grupos; tambien lo usa
//test/diagnostico/grupos/remoto_diagnostico_test.dart
void prepararVmGrupoDiagnostico(VmGrupoDiagnosticoTest test) {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  test.preparar(
    vmCategoria: crearCategoriaViewModel(
      ConexionCategoriaRemota(dio, conexionImagen),
    ),
    crearVmDeporte: crearDeporteViewModel,
    crearVmCurso: () => CursosViewModel(
      ServicioCurso(
        CursoRepositorio(cliente: ConexionCursoRemoto(dio, conexionImagen)),
      ),
    ),
    crearVmInstructores: crearInstructoresViewModel,
    crearVmGrupos: crearGruposViewModel,
    crearVmFacultades: () => Facultadesviewmodel(
      Serviciofacultades(
        Facultadesrepositorio(conexion: Conexionfacultadremoto(dio)),
      ),
    ),
    crearVmPeriodo: crearPeriodoInscripcionViewModel,
    crearVmInscripcion: crearInscripcionViewModel,
    crearVmClase: crearClasesViewModel,
    servicioAutenticacion: Servicioautenticacion(
      Autenticacionrepositorio(conexion: Conexionautenticacionremoto(dio)),
    ),
  );
}
//diagnostico del modulo 8 (plan-diagnostico-cursos.md): sus propias
//categorias por corrida
probarViewModelCursoDiagnostico(){
  group('Cursos remotos (diagnostico):', () {
    VmCursoDiagnosticoTest test = VmCursoDiagnosticoTest();
    prepararVmCursoDiagnostico(test);
    test.prueba1AgregarListarObtener(crearCursoViewModelRemoto);
    test.prueba2CursoRepetido(crearCursoViewModelRemoto);
    test.prueba3DatosInvalidos(crearCursoViewModelRemoto);
    test.prueba4CategoriaSinCursos(crearCursoViewModelRemoto);
    test.prueba5CursoInexistente(crearCursoViewModelRemoto);
    //el caso rojo va en test/diagnostico/cursos/remoto_diagnostico_test.dart
  });
}
//misma cadena que la raiz para cursos, con el Dio de pruebas; un vm por caso
CursosViewModel crearCursoViewModelRemoto() {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  return CursosViewModel(
    ServicioCurso(
      CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio))),
    ),
  );
}
//datos de apoyo del diagnostico de cursos; tambien lo usa
//test/diagnostico/cursos/remoto_diagnostico_test.dart
void prepararVmCursoDiagnostico(VmCursoDiagnosticoTest test) {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  test.preparar(
    vmCategoria: crearCategoriaViewModel(
      ConexionCategoriaRemota(dio, Conexionimagenremoto(dio)),
    ),
    crearVmDeporte: crearDeporteViewModel,
    crearVmCurso: crearCursoViewModelRemoto,
  );
}
//diagnostico del modulo 7 (plan-diagnostico-categorias.md): cada caso crea
//sus propias categorias
probarViewModelCategoriaDiagnostico(){
  group('Categorias remotas (diagnostico):', () {
    VmCategoriaDiagnosticoTest test = VmCategoriaDiagnosticoTest();
    test.preparar(crearCategoriaViewModelRemoto);
    test.prueba1TituloRepetido(crearCategoriaViewModelRemoto);
    test.prueba2EliminarSaleDeLaLista(crearCategoriaViewModelRemoto);
    test.prueba3ObservacionBorradoLogico(
      crearCategoriaViewModelRemoto,
      crearCursoViewModelRemoto,
      crearDeporteViewModel,
    );
    //el caso rojo va en test/diagnostico/categorias/remoto_diagnostico_test.dart
  });
}
//misma cadena que la raiz para categorias, con el Dio de pruebas; un vm por
//caso, como la ruta
CategoriaViewModel crearCategoriaViewModelRemoto() {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  return crearCategoriaViewModel(
    ConexionCategoriaRemota(dio, Conexionimagenremoto(dio)),
  );
}
//diagnostico del modulo 2 (plan-diagnostico-clases.md): su propio grupo por
//corrida
probarViewModelClaseDiagnostico(){
  group('Clases remotas (diagnostico):', () {
    VmClaseDiagnosticoTest test = VmClaseDiagnosticoTest();
    prepararVmClaseDiagnostico(test);
    test.prueba1RegistrarAyer(crearClasesViewModel, crearDetalleGrupoViewModel);
    test.prueba2RegistrarHoy(crearClasesViewModel, crearDetalleGrupoViewModel);
    test.prueba3FechaSinCorrimiento(crearClasesViewModel, crearDetalleGrupoViewModel);
    test.prueba4ObservacionFuturaYLarga(crearClasesViewModel);
    test.prueba5EliminarInexistente(crearDetalleGrupoViewModel);
    //los casos rojos van en test/diagnostico/clases/remoto_diagnostico_test.dart
  });
}
//datos de apoyo del diagnostico de clases; tambien lo usa
//test/diagnostico/clases/remoto_diagnostico_test.dart
void prepararVmClaseDiagnostico(VmClaseDiagnosticoTest test) {
  Dio dio = crearClienteHttp(baseUrlPruebas);
  Conexionimagenremoto conexionImagen = Conexionimagenremoto(dio);
  test.preparar(
    vmCategoria: crearCategoriaViewModel(
      ConexionCategoriaRemota(dio, conexionImagen),
    ),
    crearVmDeporte: crearDeporteViewModel,
    crearVmCurso: crearCursoViewModelRemoto,
    crearVmInstructores: crearInstructoresViewModel,
    crearVmGrupos: crearGruposViewModel,
    crearVmPeriodo: crearPeriodoInscripcionViewModel,
  );
}
//diagnostico del modulo 6 (plan-diagnostico-horarios.md y plan-diagnostico-
//horarios-escritura.md): su propio grupo por corrida; los horarios de las
//pruebas 4 a 6 se siembran con el Dio porque la app no los crea
probarViewModelHorarioDiagnostico(){
  group('Horarios remotos (diagnostico):', () {
    VmHorarioDiagnosticoTest test = VmHorarioDiagnosticoTest();
    Dio dio = crearClienteHttp(baseUrlPruebas);
    test.preparar(
      dio: dio,
      vmCategoria: crearCategoriaViewModel(
        ConexionCategoriaRemota(dio, Conexionimagenremoto(dio)),
      ),
      crearVmDeporte: crearDeporteViewModel,
      crearVmCurso: crearCursoViewModelRemoto,
      crearVmInstructores: crearInstructoresViewModel,
      crearVmGrupos: crearGruposViewModel,
      crearVmPeriodo: crearPeriodoInscripcionViewModel,
    );
    test.prueba1TarjetaSinHorarios(crearHorariosViewModel);
    test.prueba2PantallaSinHorarios(crearDetalleGrupoViewModel);
    test.prueba3GrupoInexistente(crearHorariosViewModel);
    test.prueba4HorariosCreados(crearHorariosViewModel, crearDetalleGrupoViewModel);
    test.prueba5HorarioEditado(crearDetalleGrupoViewModel);
    test.prueba6HorarioEliminado(crearDetalleGrupoViewModel);
  });
}
//diagnostico del modulo 9a (plan-diagnostico-alumnos.md): tres grupos y tres
//alumnos propios por corrida
probarViewModelAlumnoDiagnostico(){
  group('Alumnos del grupo remotos (diagnostico):', () {
    VmAlumnoDiagnosticoTest test = VmAlumnoDiagnosticoTest();
    Dio dio = crearClienteHttp(baseUrlPruebas);
    test.preparar(
      vmCategoria: crearCategoriaViewModel(
        ConexionCategoriaRemota(dio, Conexionimagenremoto(dio)),
      ),
      crearVmDeporte: crearDeporteViewModel,
      crearVmCurso: crearCursoViewModelRemoto,
      crearVmInstructores: crearInstructoresViewModel,
      crearVmGrupos: crearGruposViewModel,
      crearVmFacultades: () => Facultadesviewmodel(
        Serviciofacultades(
          Facultadesrepositorio(conexion: Conexionfacultadremoto(dio)),
        ),
      ),
      crearVmPeriodo: crearPeriodoInscripcionViewModel,
      crearVmInscripcion: crearInscripcionViewModel,
      servicioAutenticacion: Servicioautenticacion(
        Autenticacionrepositorio(conexion: Conexionautenticacionremoto(dio)),
      ),
    );
    test.prueba1AlumnosDelGrupo(crearDetalleGrupoViewModel);
    test.prueba2GrupoSinAlumnos(crearDetalleGrupoViewModel);
    test.prueba3GrupoInexistente(crearDetalleGrupoViewModel);
  });
}

probarViewModelInstructorDiagnostico(){
  group('Instructores remotos (diagnostico):', () {
    VmInstructorDiagnosticoTest test = VmInstructorDiagnosticoTest();
    Dio dio = crearClienteHttp(baseUrlPruebas);
    test.preparar(
      crearVmFacultades: () => Facultadesviewmodel(
        Serviciofacultades(
          Facultadesrepositorio(conexion: Conexionfacultadremoto(dio)),
        ),
      ),
      servicioAutenticacion: Servicioautenticacion(
        Autenticacionrepositorio(conexion: Conexionautenticacionremoto(dio)),
      ),
    );
    test.prueba1CamposDelDesplegable(crearInstructoresViewModel);
    test.prueba2AlumnoNoEsInstructor(crearInstructoresViewModel);
  });
}
