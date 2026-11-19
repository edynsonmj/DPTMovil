import 'dart:async';

import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionCursoFalsa.dart';
import '../../dobles/conexionalumnosFalsa.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//que ve cada rol en la pantalla del grupo: agregar y eliminar clases y abrir
//la toma de asistencia son de quien dicta la clase (coordinador e instructor).
//Nacio como diagnostico de AS-01 (fase 4), corregido el 2026-11-19; la ruta
//tambien lo comprueba (AccesoRutas, prueba en unitarias/rutas/accesoRutas_test.dart)
void main() {
  const String capa = "vista";
  const String tipo = "unitaria";

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    idInstructor: 'ins1',
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );

  late AutenticacionViewModel vmSesion;

  setUp(() {
    vmSesion = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken()),
      ),
      GoogleSignInFalso(),
    );
  });

  PerfilEntidad perfil(String id, String rol) => PerfilEntidad(
    id: id,
    nombre: 'Persona $id',
    correo: '$id@unicauca.edu.co',
    tipoId: 'CC',
    sexo: 'F',
    role: rol,
  );

  group('Pantalla del grupo (roles):', () {
    //rutas que la pantalla intento abrir: onGenerateRoute las anota y pinta
    //una pagina vacia, asi no hace falta montar las pantallas destino
    late List<String?> rutasAbiertas;

    Future<void> montarGrupo(WidgetTester tester) async {
      rutasAbiertas = [];
      final conexionClases =
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
            );
      final conexionCurso =
          ConexionCursoFalsa()
            ..respuestaObtener = RespuestaModelo(
              codigoHttp: 200,
              datos: CursoModelo(
                nombreCurso: 'Iniciacion',
                nombreDeporte: 'Futbol',
                tituloCategoria: 'Deportes',
                descripcion: 'Desc',
              ),
            );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AutenticacionViewModel>.value(
              value: vmSesion,
            ),
            ChangeNotifierProvider(
              create:
                  (_) => DetalleGrupoViewModel(
                    grupo,
                    ServicioCurso(CursoRepositorio(cliente: conexionCurso)),
                    Serviciohorario(
                      Horariorepositorio(
                        conexion:
                            ConexionhorariosFalsa()
                              ..respuestaHorarios = RespuestaModelo(
                                codigoHttp: 200,
                                datos: [],
                              ),
                      ),
                    ),
                    Servicioalumno(
                      Alumnosrepositorio(
                        cliente:
                            ConexionalumnosFalsa()
                              ..respuestaAlumnos = RespuestaModelo(
                                codigoHttp: 406,
                              ),
                      ),
                    ),
                    Servicioclase(Claserepositorio(cliente: conexionClases)),
                  )..cargar(),
            ),
          ],
          child: MaterialApp(
            home: Grupo(grupo: grupo),
            onGenerateRoute: (settings) {
              rutasAbiertas.add(settings.name);
              return MaterialPageRoute(
                builder: (_) => Text('ruta ${settings.name}'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    //la tarjeta de la clase queda debajo de las demas secciones, fuera de la
    //ventana de prueba: se desplaza hasta ella antes de tocarla
    Future<void> abrirClase(WidgetTester tester) async {
      final tarjeta = find.text('Fecha clase: 2026-10-20');
      expect(tarjeta, findsOneWidget);
      await tester.ensureVisible(tarjeta);
      await tester.pumpAndSettle();
      await tester.tap(tarjeta);
      await tester.pumpAndSettle();
    }

    //lo que nadie salvo el responsable del grupo deberia poder hacer
    Future<void> comprobarSinAccesoAAsistencia(WidgetTester tester) async {
      expect(find.text('Fecha clase: 2026-10-20'), findsOneWidget);
      //se anotan todas las faltas antes de afirmar: asi el rojo dice cuales
      //permisos sobran y no solo el primero
      final faltas = <String>[];
      if (find.text('AGREGAR CLASE').evaluate().isNotEmpty) {
        faltas.add('ve AGREGAR CLASE');
      }
      if (find.byIcon(Icons.close).evaluate().isNotEmpty) {
        faltas.add('ve el boton de eliminar clase');
      }
      await abrirClase(tester);
      if (rutasAbiertas.contains(AppRutas.clase)) {
        faltas.add('abre la toma de asistencia');
      }

      expect(faltas, isEmpty);
    }

    testWidgets('$capa - $tipo - Grupo - un alumno no accede a la toma de asistencia', (
      tester,
    ) async {
      vmSesion.perfilSesion = perfil('alu1', Roles.alumno);
      await montarGrupo(tester);

      await comprobarSinAccesoAAsistencia(tester);
    });

    testWidgets('$capa - $tipo - Grupo - sin sesion no se accede a la toma de asistencia', (
      tester,
    ) async {
      await montarGrupo(tester);

      await comprobarSinAccesoAAsistencia(tester);
    });

    //omitida: espera la regla 3.4-1 del cliente (que instructor toma la
    //asistencia de que grupo); sigue abierta como parte de AS-01.
    //testWidgets solo acepta skip booleano, el motivo va en este comentario
    testWidgets(
      '$capa - $tipo - Grupo - pendiente AS-01 - un instructor ajeno al grupo no accede a la toma de asistencia',
      (tester) async {
        vmSesion.perfilSesion = perfil('ins2', Roles.instructor);
        await montarGrupo(tester);

        await comprobarSinAccesoAAsistencia(tester);
      },
      skip: true,
    );

    testWidgets('$capa - $tipo - Grupo - el instructor del grupo si accede', (
      tester,
    ) async {
      //control positivo: si este caso falla, las pruebas de arriba estan mal
      //montadas y su rojo no prueba nada
      vmSesion.perfilSesion = perfil('ins1', Roles.instructor);
      await montarGrupo(tester);

      await abrirClase(tester);
      expect(rutasAbiertas, contains(AppRutas.clase));
    });

    testWidgets('$capa - $tipo - Grupo - el coordinador ve agregar y eliminar y abre la asistencia', (tester) async {
      vmSesion.perfilSesion = perfil('coo1', Roles.coordinador);
      await montarGrupo(tester);

      expect(find.text('AGREGAR CLASE'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsWidgets);
      await abrirClase(tester);
      expect(rutasAbiertas, contains(AppRutas.clase));
    });
  });
}
