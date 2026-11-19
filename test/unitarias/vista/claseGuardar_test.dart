import 'dart:async';

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
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//guardar la asistencia en la pantalla de la clase (AS-02, AS-03)
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
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken()),
      ),
      GoogleSignInFalso(),
    );
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

    testWidgets('$capa - $tipo - Clase - dos toques a Guardar envian un solo registro', (
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

    testWidgets('$capa - $tipo - Clase - tras una carga fallida no se ofrece un mensaje enganoso', (
      tester,
    ) async {
      conexion.respuestaAtenciones = RespuestaModelo(
        codigoHttp: 500,
        error: ErrorModelo(
          codigoHttp: 500,
          mensaje: 'fallo interno',
          url: '/alumnosGrupo',
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
