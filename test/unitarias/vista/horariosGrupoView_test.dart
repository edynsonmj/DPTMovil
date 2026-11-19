
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
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
import '../../contratos/leerContrato.dart';
import '../../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//diagnostico de la escritura de horarios en la pantalla del grupo (plan-
//diagnostico-horarios-escritura.md): el backend ya tiene POST, PUT y DELETE
///horario (2026-11-04). Mismo montaje que test/unitarias/vista/
//grupoView_test.dart, con un observador del Navigator: crear o eliminar un
//horario tiene que abrir algo (formulario o confirmacion). Afirman el
//comportamiento CORRECTO y se espera que salgan rojas mientras el bug exista
void main() {
  const String capa = "vista";
  const String tipo = "unitaria";

  late _Observador observador;

  final grupo = Grupoentidad(
    categoria: 'Categoria Fase 4',
    curso: 'Curso Categoria Fase 4',
    anio: 2026,
    iterable: 1,
    idInstructor: '2',
    cupos: 20,
    fechaCreacion: '2026-10-22',
  );

  Future<void> montar(WidgetTester tester) async {
    observador = _Observador();
    final conexionHorarios = ConexionhorariosFalsa()
      ..respuestaHorarios = RespuestaModelo(
        codigoHttp: 200,
        datos: (leerContrato('horarios', 'horarios_200') as List).map(HorarioModelo.fromJson).toList(),
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AutenticacionViewModel(
              Servicioautenticacion(
                Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken()),
              ),
              GoogleSignInFalso(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => DetalleGrupoViewModel(
              grupo,
              ServicioCurso(
                CursoRepositorio(
                  cliente: ConexionCursoFalsa()
                    ..respuestaObtener = RespuestaModelo(
                      codigoHttp: 200,
                      datos: CursoModelo(
                        nombreCurso: 'Curso Categoria Fase 4',
                        nombreDeporte: 'Futbol',
                        tituloCategoria: 'Categoria Fase 4',
                        descripcion: 'Desc',
                      ),
                    ),
                ),
              ),
              Serviciohorario(Horariorepositorio(conexion: conexionHorarios)),
              Servicioalumno(
                Alumnosrepositorio(
                  cliente: ConexionalumnosFalsa()..respuestaAlumnos = RespuestaModelo(codigoHttp: 406),
                ),
              ),
              Servicioclase(
                Claserepositorio(
                  cliente: ConexionclasesFalsa()..respuestaClases = RespuestaModelo(codigoHttp: 406),
                ),
              ),
            )..cargar(),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [observador],
          home: Grupo(grupo: grupo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //la ruta de home ya conto como un push
    observador.empujes = 0;
  }

  group('Horarios en la pantalla del grupo (escritura):', () {
    //el montaje es valido: la seccion pinta los dos horarios del contrato y
    //el boton de agregar
    testWidgets('$capa - $tipo - Pantalla del grupo - pinta los horarios y el boton de agregar', (tester) async {
      await montar(tester);

      expect(find.text('Lunes - Coliseo'), findsOneWidget);
      expect(find.text('Miércoles - Piscina'), findsOneWidget);
      expect(find.text('AGREGAR HORARIO'), findsOneWidget);
    });

    //widgetListaHorarios.dart: onPressed: () {}
    testWidgets('$capa - $tipo - Pantalla del grupo - agregar horario abre el formulario', (tester) async {
      await montar(tester);

      await tester.ensureVisible(find.text('AGREGAR HORARIO'));
      await tester.tap(find.text('AGREGAR HORARIO'));
      await tester.pumpAndSettle();

      expect(observador.empujes, greaterThan(0), reason: 'tocar el boton no abrio ninguna pantalla ni dialogo');
    });

    //MiniTarjeta.iconoAccion: onPressed solo hace print('hola')
    testWidgets('$capa - $tipo - Pantalla del grupo - cerrar la tarjeta de un horario pide confirmacion para eliminarlo', (tester) async {
      await montar(tester);
      final cerrar = find.descendant(
        of: find.ancestor(of: find.text('Lunes - Coliseo'), matching: find.byType(MiniTarjeta)),
        matching: find.byIcon(Icons.close),
      );
      expect(cerrar, findsOneWidget);

      await tester.ensureVisible(cerrar);
      await tester.tap(cerrar);
      await tester.pumpAndSettle();

      expect(observador.empujes, greaterThan(0), reason: 'tocar cerrar no abrio ninguna confirmacion');
    });
  });
}

//cuenta las rutas y dialogos que se abren sobre la pantalla
class _Observador extends NavigatorObserver {
  int empujes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    empujes++;
  }
}
