import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionFacultadRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

//raiz de composicion. El orden importa: en MultiProvider cada provider es
//ancestro de los siguientes, por eso los datos van antes que los vms y un
//vm puede leer sus servicios con context.read en su create

//capa de datos: cliente http y, desde la fase 1, la conexion de imagenes
//(la unica compartida) y los servicios de cada modulo migrado. Las
//conexiones y repositorios 1:1 se construyen dentro del create del servicio
List<SingleChildWidget> proveedoresDatos() => [
  Provider<Dio>(create: (_) => crearClienteHttp()),
  //unica conexion compartida: la usan categoria y, desde la fase 3, curso
  Provider<Conexionimagen>(
    create: (c) => Conexionimagenremoto(c.read<Dio>()),
  ),
  Provider<ServicioCategoria>(
    create:
        (c) => ServicioCategoria(
          CategoriaRepositorio(
            cliente: ConexionCategoriaRemota(
              c.read<Dio>(),
              c.read<Conexionimagen>(),
            ),
          ),
        ),
  ),
  Provider<Servicioautenticacion>(
    create:
        (c) => Servicioautenticacion(
          Autenticacionrepositorio(
            conexion: Conexionautenticacionremoto(c.read<Dio>()),
          ),
        ),
  ),
  Provider<Serviciofacultades>(
    create:
        (c) => Serviciofacultades(
          Facultadesrepositorio(conexion: Conexionfacultadremoto(c.read<Dio>())),
        ),
  ),
];

//vms con estado que debe sobrevivir entre pantallas. Al final solo queda
//la sesion; los demas pasan a su ruta en route_generator al migrar su modulo
List<SingleChildWidget> vmsGlobales() => [
  ChangeNotifierProvider(create: (_) => EstadisticasViewModel()), //fase 7
  ChangeNotifierProvider(create: (_) => Gruposviewmodel()), //fases 4 y 6
  ChangeNotifierProvider(create: (_) => Horariosviewmodel()), //fases 4 y 6
  //nadie lo lee del arbol: widgetListaAlumnos crea su propia instancia
  ChangeNotifierProvider(create: (_) => Alumnosviewmodel()), //fase 4
  ChangeNotifierProvider(create: (_) => Clasesviewmodel()), //fase 4
  //nadie lo lee del arbol: FormularioCurso crea su propia instancia
  ChangeNotifierProvider(create: (_) => Deporteviewmodel()), //fase 3
  //se queda: la sesion la leen el menu lateral y casi todas las pantallas
  ChangeNotifierProvider(
    create:
        (c) => AutenticacionViewModel(
          c.read<Servicioautenticacion>(),
          GoogleSignIn(scopes: ['email', 'profile']),
        ),
  ),
  ChangeNotifierProvider(create: (_) => Inscripcionviewmodel()), //fase 6
  ChangeNotifierProvider(create: (_) => InstructoresViewModel()), //fase 4
];
