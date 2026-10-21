import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

//raiz de composicion. El orden importa: en MultiProvider cada provider es
//ancestro de los siguientes, por eso los datos van antes que los vms y un
//vm puede leer sus servicios con context.read en su create

//capa de datos: cliente http y, desde la fase 1, la conexion de imagenes
//(la unica compartida) y los servicios de cada modulo migrado. Las
//conexiones y repositorios 1:1 se construyen dentro del create del servicio
List<SingleChildWidget> proveedoresDatos() => [
  //nadie lo lee aun, las conexiones lo recibiran al migrar cada modulo
  Provider<Dio>(create: (_) => Dio(BaseOptions(baseUrl: ConfigApi.baseUrl))),
];

//vms con estado que debe sobrevivir entre pantallas. Al final solo queda
//la sesion; los demas pasan a su ruta en route_generator al migrar su modulo
List<SingleChildWidget> vmsGlobales() => [
  ChangeNotifierProvider(create: (_) => CategoriaViewModel()), //fase 1
  ChangeNotifierProvider(create: (_) => EstadisticasViewModel()), //fase 7
  ChangeNotifierProvider(create: (_) => Gruposviewmodel()), //fases 4 y 6
  ChangeNotifierProvider(create: (_) => Horariosviewmodel()), //fases 4 y 6
  //nadie lo lee del arbol: widgetListaAlumnos crea su propia instancia
  ChangeNotifierProvider(create: (_) => Alumnosviewmodel()), //fase 4
  ChangeNotifierProvider(create: (_) => Clasesviewmodel()), //fase 4
  //nadie lo lee del arbol: FormularioCurso crea su propia instancia
  ChangeNotifierProvider(create: (_) => Deporteviewmodel()), //fase 3
  //se queda: la sesion la leen el menu lateral y casi todas las pantallas
  ChangeNotifierProvider(create: (_) => AutenticacionViewModel()),
  ChangeNotifierProvider(create: (_) => Facultadesviewmodel()), //fase 2
  ChangeNotifierProvider(create: (_) => Inscripcionviewmodel()), //fase 6
  ChangeNotifierProvider(create: (_) => InstructoresViewModel()), //fase 4
];
