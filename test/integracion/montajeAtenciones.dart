import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';
import '../dobles/conexionCursoFalsa.dart';
import '../dobles/conexionalumnosFalsa.dart';
import '../dobles/conexionautenticacionFalsa.dart';
import '../dobles/conexionclasesFalsa.dart';
import '../dobles/conexiongruposFalsa.dart';
import '../dobles/conexionhorariosFalsa.dart';
import '../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//montaje compartido de la integracion local de la toma de asistencia (fase 5
//del diagnostico). No es un test: lo usan test/integracion y
//test/diagnostico.
//
//Lo que se integra de verdad: las rutas de route_generator (grupos
//asignados -> grupo -> clase, con los vms que crea cada ruta) y la cadena
//completa de atenciones Atencionviewmodel -> Servicio -> Repositorio ->
//Conexionatencionesremoto -> Dio, con el transporte falso debajo y las
//respuestas del contrato. Los demas modulos (grupos, horarios, curso,
//alumnos, clases) van con sus dobles: no son el objeto de esta fase
class MontajeAtenciones {
  final AdaptadorHttpFalso adaptador = AdaptadorHttpFalso();

  late final AutenticacionViewModel sesion = AutenticacionViewModel(
    Servicioautenticacion(
      Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken()),
    ),
    GoogleSignInFalso(),
  );

  MontajeAtenciones() {
    //el backend segun el contrato: alumnos del grupo, marcas de la clase y
    //confirmacion de la asistencia
    adaptador.responder('GET', '/alumnosGrupo', 200, leerContrato('atenciones', 'alumnosGrupo_200'));
    adaptador.responder('GET', '/atencionesporclase', 200, leerContrato('atenciones', 'atencionesporclase_200'));
    adaptador.responder('PUT', '/clase/210/asistencia', 200, leerContrato('atenciones', 'confirmar_200'));
    sesion.perfilSesion = PerfilEntidad(
      id: 'ins1',
      nombre: 'Instructor del grupo',
      correo: 'ins1@unicauca.edu.co',
      tipoId: 'CC',
      sexo: 'M',
      role: Roles.instructor,
    );
  }

  static const String textoClase = 'Fecha clase: 2026-10-20';
  static const String textoGrupo = 'Iniciacion-2026-1';

  List<SingleChildWidget> _servicios() => [
    Provider<Serviciogrupo>(
      create:
          (_) => Serviciogrupo(
            Gruporepositorio(
              conexion:
                  ConexiongruposFalsa()
                    ..respuestaInstructor = RespuestaModelo(
                      codigoHttp: 200,
                      datos: [
                        GrupoModelo(
                          cat_titulo: 'Deportes',
                          cur_nombre: 'Iniciacion',
                          anio: 2026,
                          iterable: 1,
                          cupos: 20,
                          fechaCreacion: '2026-10-23',
                          idInstructor: 'ins1',
                        ),
                      ],
                    ),
            ),
          ),
    ),
    Provider<Serviciohorario>(
      create:
          (_) => Serviciohorario(
            Horariorepositorio(
              conexion:
                  ConexionhorariosFalsa()
                    ..respuestaHorarios = RespuestaModelo(
                      codigoHttp: 200,
                      datos: [],
                    ),
            ),
          ),
    ),
    Provider<ServicioCurso>(
      create:
          (_) => ServicioCurso(
            CursoRepositorio(
              cliente:
                  ConexionCursoFalsa()
                    ..respuestaObtener = RespuestaModelo(
                      codigoHttp: 200,
                      datos: CursoModelo(
                        nombreCurso: 'Iniciacion',
                        nombreDeporte: 'Futbol',
                        tituloCategoria: 'Deportes',
                        descripcion: 'Desc',
                      ),
                    ),
            ),
          ),
    ),
    Provider<Servicioalumno>(
      create:
          (_) => Servicioalumno(
            Alumnosrepositorio(
              cliente:
                  ConexionalumnosFalsa()
                    ..respuestaAlumnos = RespuestaModelo(codigoHttp: 406),
            ),
          ),
    ),
    Provider<Servicioclase>(
      create:
          (_) => Servicioclase(
            Claserepositorio(
              cliente:
                  ConexionclasesFalsa()
                    ..respuestaClases = RespuestaModelo(
                      codigoHttp: 200,
                      datos: [
                        Clasemodelo(
                          codigo: 210,
                          idGrupoCategoria: 'Deportes',
                          idGrupoCurso: 'Iniciacion',
                          idGrupoAnio: 2026,
                          idGrupoIterable: 1,
                          idInstructor: 'ins1',
                          fecha: DateTime(2026, 10, 20),
                          horas: 2,
                          minutos: 0,
                          eliminado: 0,
                        ),
                      ],
                    ),
            ),
          ),
    ),
    //la cadena real de atenciones, como en dependencias.dart pero con el
    //transporte falso
    Provider<Servicioatencion>(
      create:
          (_) => Servicioatencion(
            Atencionesrepositorio(
              conexion: Conexionatencionesremoto(crearDioFalso(adaptador)),
            ),
          ),
    ),
  ];

  //app con las rutas reales; arranca en una pantalla con un boton que abre
  //los grupos asignados del instructor en sesion, como el menu lateral
  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ..._servicios(),
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: sesion),
        ],
        child: MaterialApp(
          onGenerateRoute: generateRoute,
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => Navigator.pushNamed(
                        context,
                        AppRutas.gruposAsignados,
                        arguments: 'ins1',
                      ),
                  child: const Text('Mis grupos'),
                ),
          ),
        ),
      ),
    );
  }

  //recorrido del instructor hasta la toma de asistencia de la clase 210
  Future<void> abrirClase(WidgetTester tester) async {
    await montar(tester);
    await tester.tap(find.text('Mis grupos'));
    await tester.pumpAndSettle();
    await _tocar(tester, find.text(textoGrupo));
    await _tocar(tester, find.text(textoClase));
  }

  Future<void> _tocar(WidgetTester tester, Finder destino) async {
    expect(destino, findsOneWidget);
    await tester.ensureVisible(destino);
    await tester.pumpAndSettle();
    await tester.tap(destino);
    await tester.pumpAndSettle();
  }
}
