import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAlumnosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionDeporteRemoto.dart';
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
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicioImagen.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
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
  //unica conexion compartida: la usan categoria, curso y Servicioimagen
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
  Provider<ServicioCurso>(
    create:
        (c) => ServicioCurso(
          CursoRepositorio(
            cliente: ConexionCursoRemoto(
              c.read<Dio>(),
              c.read<Conexionimagen>(),
            ),
          ),
        ),
  ),
  Provider<Serviciodeporte>(
    create:
        (c) => Serviciodeporte(
          Deporterepositorio(cliente: Conexiondeporteremoto(c.read<Dio>())),
        ),
  ),
  //sin consumidores por ahora: provider es perezoso y no lo crea hasta que
  //alguien lo lea
  Provider<Servicioimagen>(
    create:
        (c) => Servicioimagen(
          Imagenrepositorio(conexion: c.read<Conexionimagen>()),
        ),
  ),
  Provider<Serviciogrupo>(
    create:
        (c) => Serviciogrupo(
          Gruporepositorio(conexion: Conexiongruposremoto(c.read<Dio>())),
        ),
  ),
  Provider<Serviciohorario>(
    create:
        (c) => Serviciohorario(
          Horariorepositorio(conexion: Conexionhorariosremoto(c.read<Dio>())),
        ),
  ),
  Provider<Servicioalumno>(
    create:
        (c) => Servicioalumno(
          Alumnosrepositorio(cliente: Conexionalumnosremoto(c.read<Dio>())),
        ),
  ),
  Provider<Servicioclase>(
    create:
        (c) => Servicioclase(
          Claserepositorio(cliente: Conexionclasesremoto(c.read<Dio>())),
        ),
  ),
  Provider<ServicioInstructor>(
    create:
        (c) => ServicioInstructor(
          Instructoresrepositorio(
            conexion: Conexioninstructoresremoto(c.read<Dio>()),
          ),
        ),
  ),
  Provider<Servicioatencion>(
    create:
        (c) => Servicioatencion(
          Atencionesrepositorio(
            conexion: Conexionatencionesremoto(c.read<Dio>()),
          ),
        ),
  ),
  Provider<Servicioinscripcion>(
    create:
        (c) => Servicioinscripcion(
          Inscripcionrepositorio(
            conexion: Conexioninscripcionremoto(c.read<Dio>()),
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
  //se queda: la sesion la leen el menu lateral y casi todas las pantallas
  ChangeNotifierProvider(
    create:
        (c) => AutenticacionViewModel(
          c.read<Servicioautenticacion>(),
          GoogleSignIn(scopes: ['email', 'profile']),
        ),
  ),
];
