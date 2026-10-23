// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/config/configServicio.dart';
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
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
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
import 'package:dpt_movil/data/repositories/imagenRepositorio.dart';
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
import 'package:flutter_test/flutter_test.dart';

import 'dobles/conexionCategoriaLocal.dart';
import 'dobles/googleSignInFalso.dart';
import 'local/categorias/insertarCategoriaLocal.dart';
import 'local/categorias/obtenerCategoriasLocal.dart';
import 'local/viewModel/categoria/vmListarCategoriaLocalTest.dart';
import 'remoto/categorias/insertarCategoriaTest.dart';
import 'remoto/categorias/listarCategoriaTest.dart';
import 'remoto/imagenes/obtenerImagenTest.dart';
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
import 'remoto/viewModel/estadisticas/vmEstadisticasTest.dart';
import 'remoto/viewModel/categoria/vmEliminarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmListarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmGuardarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmGuardarFormularioCategoriaTest.dart';

//direccion del backend de pruebas: cada vm recibe un Dio armado aqui, sin
//pasar por ConfigServicio. Desde la fase 7 no queda ningun modulo sin
//migrar; solo los tests inactivos probarRepositorio* fijan ConfigServicio.ip
const String baseUrlPruebas = 'http://localhost:8082/api/v2';

//misma cadena que arma la raiz de composicion, con la conexion indicada
CategoriaViewModel crearCategoriaViewModel(ConexionCategoria conexion) {
  return CategoriaViewModel(
    ServicioCategoria(CategoriaRepositorio(cliente: conexion)),
  );
}

void main() {
  //probarRepositorioCategoriaRemota();
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
  probarViewModelEstadisticas();
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
    test.prueba3CicloInscripcion(crearInscripcionViewModel);
  });
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
    test.prueba4BackendSinEndpoint(crearAtencionViewModel);
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

probarRepositorioCategoriaLocal() {
  String ip = '192.168.100.66';
  CategoriaRepositorio repositorio = configuracionCategoriaRepositorio(
    true,
    ip,
  );
  group('Obtener categorias:', () {
    Obtenercategoriaslocal test = Obtenercategoriaslocal();
    test.prueba1ObtenerLista(repositorio);
    test.prueba2ListaTipo(repositorio);
  });
  group('insertar Categoria: ', () {
    Insertarcategorialocal test = Insertarcategorialocal();
    test.prueba1InsercionExitosa(repositorio);
    test.prueba2InsercionRepetida(repositorio);
    test.prueba3InsercionIncompleta(repositorio);
  });
}

probarRepositorioImagenRemota() {
  String ip = "localhost";
  Imagenrepositorio repo = configuracionImagenRepositorio(ip);
  grupoObtenerImagenRemota(repo);
}

probarRepositorioCategoriaRemota() {
  String ip = 'localhost';
  CategoriaRepositorio repositorio = configuracionCategoriaRepositorio(
    false,
    ip,
  );
  grupoInsercionCategoriaRemota(repositorio);
  grupoObtenerCateogoriaRemota(repositorio);
}

grupoInsercionCategoriaRemota(CategoriaRepositorio repositorio) {
  print("hola");
  group('Insertar Categoria:', () {
    Random random = Random();
    InsertarCategoriaTest test = InsertarCategoriaTest();
    test.prueba1(random, repositorio);
    test.prueba2Exito(random, repositorio);
    test.prueba3(random, repositorio);
    test.prueba4(random, repositorio);
    test.prueba5(random, repositorio);
  });
}

grupoObtenerCateogoriaRemota(CategoriaRepositorio repositorio) {
  group('Obtener Categoria:', () {
    ListarCategoriaTest test = ListarCategoriaTest();
    test.prueba1codigo200(repositorio);
    test.prueba2codigo204(repositorio);
  });
}

grupoObtenerImagenRemota(Imagenrepositorio repositorio) {
  group('Obtener imagen remota:', () {
    Obtenerimagentest test = Obtenerimagentest();
    test.prueba1codigo200(repositorio);
  });
}

CategoriaRepositorio configuracionCategoriaRepositorio(bool local, String? ip) {
  CategoriaRepositorio repositorio;
  if (local) {
    repositorio = CategoriaRepositorio(cliente: ConexionCategoriaLocal());
  } else {
    Dio dio = crearClienteHttp('http://$ip:8082/api/v2');
    repositorio = CategoriaRepositorio(
      cliente: ConexionCategoriaRemota(dio, Conexionimagenremoto(dio)),
    );
  }
  return repositorio;
}

Imagenrepositorio configuracionImagenRepositorio(String? ip) {
  Imagenrepositorio repositorio;

  ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_REMOTO;
  ConfigServicio.ip = ip;
  repositorio = Imagenrepositorio(
    conexion: Conexionimagenremoto(crearClienteHttp('http://$ip:8082/api/v2')),
  );

  return repositorio;
}
