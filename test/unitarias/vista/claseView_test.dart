import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionatencionesFalsa.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//widget test de la pantalla de una clase (fase 5): el backend aun no tiene
//los endpoints de atenciones, asi que esta es la unica forma de ver la
//pantalla con datos. Se monta con el mismo vm que crea la ruta clase
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  late ConexionatencionesFalsa conexion;

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
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

  //el doble responde la lista del contrato (listar_200.json): Ana y Luis
  //sin marcar, Marta ya marcada
  setUp(() {
    conexion = ConexionatencionesFalsa();
  });

  //mismo arbol que en la app: la sesion global y el vm que crea la ruta,
  //que ya empieza a cargar al crearse
  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create:
                (_) => AutenticacionViewModel(
                  Servicioautenticacion(
                    Autenticacionrepositorio(
                      conexion: ConexionautenticacionFalsa(),
                    ),
                  ),
                  GoogleSignInFalso(),
                ),
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

  testWidgets('$capa - $tipo - Clase - pinta los alumnos de la clase', (
    tester,
  ) async {
    await montar(tester);

    //la vista ya no carga en initState: lo hizo la ruta, una sola vez
    expect(conexion.llamadasAtenciones, 1);
    expect(find.text('Ana Gomez'), findsOneWidget);
    expect(find.text('Luis Perez'), findsOneWidget);
    expect(find.text('Marta Ruiz'), findsOneWidget);
    //cada checkbox refleja lo que trajo la carga
    final marcas = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .map((c) => c.value);
    expect(marcas, [false, false, true]);
  });

  testWidgets('$capa - $tipo - Clase - marcar y guardar envia la asistencia', (
    tester,
  ) async {
    await montar(tester);

    //se marca a Luis (segundo checkbox); Ana queda sin marcar y Marta ya venia
    //marcada
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(conexion.llamadasRegistrar, 1);
    expect(conexion.ultimoIdClaseRegistro, 210);
    expect(
      conexion.ultimasRegistradas!.map((a) => a.estaAtendido),
      [false, true, true],
    );
    expect(find.text('Atenciones registradas'), findsOneWidget);
  });

  //como en la app: la clase se abre encima de otra pantalla, asi se puede
  //ver si hace pop al terminar
  Future<void> montarEncima(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create:
                (_) => Atencionviewmodel(
                  Servicioatencion(Atencionesrepositorio(conexion: conexion)),
                )..cargarAtenciones(grupo, clase),
          ),
          ChangeNotifierProvider(
            create:
                (_) => AutenticacionViewModel(
                  Servicioautenticacion(
                    Autenticacionrepositorio(
                      conexion: ConexionautenticacionFalsa(),
                    ),
                  ),
                  GoogleSignInFalso(),
                ),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Claseview(grupo: grupo, clase: clase),
                        ),
                      ),
                  child: const Text('Abrir clase'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir clase'));
    await tester.pumpAndSettle();
  }

  testWidgets('$capa - $tipo - Clase - error de carga se pinta', (
    tester,
  ) async {
    conexion.respuestaAtenciones = RespuestaModelo(
      codigoHttp: 500,
      error: ErrorModelo(
        codigoHttp: 500,
        mensaje: 'fallo interno',
        url: '/asistenciasClase',
        metodo: 'GET',
      ),
    );

    await montar(tester);

    expect(find.text('Código: 500 - fallo interno'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('$capa - $tipo - Clase - clase sin alumnos lo dice', (
    tester,
  ) async {
    conexion.respuestaAtenciones = RespuestaModelo(
      codigoHttp: 200,
      datos: atencionesDelContrato('listar_vacia'),
    );

    await montar(tester);

    expect(find.text('¡No hay alumnos aún!'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('$capa - $tipo - Clase - registro fallido muestra el error y no sale', (
    tester,
  ) async {
    conexion.respuestaRegistrar = RespuestaModelo(
      codigoHttp: 500,
      error: ErrorModelo(
        codigoHttp: 500,
        mensaje: 'no se pudo guardar',
        url: '/asistenciasClase',
        metodo: 'POST',
      ),
    );
    await montarEncima(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Error al registrar atenciones'), findsOneWidget);
    expect(find.text('no se pudo guardar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    //el usuario sigue en la clase con sus marcas para reintentar
    expect(find.byType(Claseview), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));
  });

  testWidgets('$capa - $tipo - Clase - registro exitoso avisa y vuelve atras', (
    tester,
  ) async {
    await montarEncima(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Atenciones registradas'), findsOneWidget);
    //mientras el dialogo esta abierto la pantalla no se ha cerrado
    expect(find.byType(Claseview), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(Claseview), findsNothing);
    expect(find.text('Abrir clase'), findsOneWidget);
  });
}
