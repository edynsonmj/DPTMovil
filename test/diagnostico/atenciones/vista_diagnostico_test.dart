@Tags(['diagnostico'])
library;

import 'dart:async';

import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionCursoFalsa.dart';
import '../../dobles/conexionalumnosFalsa.dart';
import '../../dobles/conexionatencionesFalsa.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//pruebas de diagnostico (fase 4) de las pantallas del flujo de asistencia:
//afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "vista";
  const String tipo = "diagnostico";

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    idInstructor: 'ins1',
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );
  final clase = Claseentidad(
    codigo: 210,
    idGrupoCategoria: 'Deportes',
    idGrupoCurso: 'Iniciacion',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'ins1',
    eliminado: 0,
  );

  late AutenticacionViewModel vmSesion;

  setUp(() {
    vmSesion = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa()),
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

  group('Pantalla del grupo (AS-01, roles):', () {
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

    testWidgets('$capa - $tipo - Grupo - BUG AS-01 - un alumno no accede a la toma de asistencia', (
      tester,
    ) async {
      vmSesion.perfilSesion = perfil('alu1', Roles.alumno);
      await montarGrupo(tester);

      await comprobarSinAccesoAAsistencia(tester);
    });

    testWidgets('$capa - $tipo - Grupo - BUG AS-01 - sin sesion no se accede a la toma de asistencia', (
      tester,
    ) async {
      await montarGrupo(tester);

      await comprobarSinAccesoAAsistencia(tester);
    });

    //omitida: espera la regla 3.4-1 del cliente (quien toma asistencia).
    //testWidgets solo acepta skip booleano, el motivo va en este comentario
    testWidgets(
      '$capa - $tipo - Grupo - BUG AS-01 - un instructor ajeno al grupo no accede a la toma de asistencia',
      (tester) async {
        vmSesion.perfilSesion = perfil('ins2', Roles.instructor);
        await montarGrupo(tester);

        await comprobarSinAccesoAAsistencia(tester);
      },
      skip: true,
    );

    testWidgets('$capa - $tipo - Grupo - control AS-01 - el instructor del grupo si accede', (
      tester,
    ) async {
      //control positivo: si este caso falla, las pruebas de arriba estan mal
      //montadas y su rojo no prueba nada
      vmSesion.perfilSesion = perfil('ins1', Roles.instructor);
      await montarGrupo(tester);

      await abrirClase(tester);
      expect(rutasAbiertas, contains(AppRutas.clase));
    });
  });

  group('Pantalla de la clase (AS-02, AS-03):', () {
    late ConexionatencionesFalsa conexion;

    setUp(() {
      conexion = ConexionatencionesFalsa();
    });

    Future<void> montarClase(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AutenticacionViewModel>.value(
              value: vmSesion,
            ),
            ChangeNotifierProvider(
              create:
                  (_) => Atencionviewmodel(
                    Servicioatencion(Atencionesrepositorio(conexion: conexion)),
                  )..cargarAtenciones(grupo, clase),
            ),
          ],
          child: MaterialApp(home: Claseview(grupo: grupo, clase: clase)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('$capa - $tipo - Clase - BUG AS-02 - dos toques a Guardar envian un solo registro', (
      tester,
    ) async {
      final pausa = Completer<void>();
      conexion.antesDeRegistrar = () => pausa.future;
      await montarClase(tester);

      await tester.tap(find.text('Guardar'));
      await tester.pump();
      //el primer envio sigue en camino: el usuario no ve nada y vuelve a tocar
      await tester.tap(find.text('Guardar'), warnIfMissed: false);
      await tester.pump();
      pausa.complete();
      await tester.pumpAndSettle();

      expect(conexion.llamadasRegistrar, 1);
    });

    testWidgets('$capa - $tipo - Clase - BUG AS-03 - tras una carga fallida no se ofrece un mensaje enganoso', (
      tester,
    ) async {
      conexion.respuestaAtenciones = RespuestaModelo(
        codigoHttp: 500,
        error: ErrorModelo(
          codigoHttp: 500,
          mensaje: 'fallo interno',
          url: '/atencionesporclase',
          metodo: 'GET',
        ),
      );
      await montarClase(tester);

      final guardar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar'),
      );
      if (guardar.onPressed != null) {
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        //la clase si puede tener alumnos: lo que fallo fue la carga
        expect(find.text('No hay alumnos para registrar'), findsNothing);
      }
    });
  });
}
