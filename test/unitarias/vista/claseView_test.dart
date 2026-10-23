import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
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

  setUp(() {
    conexion = ConexionatencionesFalsa()
      ..respuestaAtenciones = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Atencionmodelo(
            alumno: Alumnomodelo(
              id: 'alu1',
              tipo: 'Estudiante',
              nombre: 'Ana',
              correo: 'ana@x.co',
              sexo: 'F',
              tipoid: 'CC',
            ),
            idClase: 210,
            estaAtendido: false,
          ),
        ],
      );
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
    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Clase - marcar y guardar envia la asistencia', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(conexion.ultimoIdClaseRegistro, 210);
    expect(conexion.ultimasRegistradas!.single.estaAtendido, isTrue);
    expect(find.text('Atenciones registradas'), findsOneWidget);
  });
}
