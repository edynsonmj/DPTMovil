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

//widget test de la pantalla de un grupo (fase 4c): se monta con el mismo vm
//que crea la ruta, armado con dobles. Comprueba que cada seccion pinta lo
//que el vm cargo una sola vez, y que un grupo sin alumnos ni clases no
//muestra errores
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  late ConexionCursoFalsa conexionCurso;
  late ConexionhorariosFalsa conexionHorarios;
  late ConexionalumnosFalsa conexionAlumnos;
  late ConexionclasesFalsa conexionClases;

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    idInstructor: 'ins1',
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );

  setUp(() {
    conexionCurso = ConexionCursoFalsa()
      ..respuestaObtener = RespuestaModelo(
        codigoHttp: 200,
        datos: CursoModelo(
          nombreCurso: 'Iniciacion',
          nombreDeporte: 'Futbol',
          tituloCategoria: 'Deportes',
          descripcion: 'Desc',
        ),
      );
    conexionHorarios = ConexionhorariosFalsa()
      ..respuestaHorarios = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          HorarioModelo(
            categoria: 'Deportes',
            curso: 'Iniciacion',
            anio: 2026,
            iterable: 1,
            dia: 'Lunes',
            horaInicio: '08:00',
            horaFin: '10:00',
            escenario: 'Coliseo',
          ),
        ],
      );
    //grupo sin alumnos ni clases: lo que la conexion devuelve con GC-0002
    conexionAlumnos = ConexionalumnosFalsa()
      ..respuestaAlumnos = RespuestaModelo(codigoHttp: 406);
    conexionClases = ConexionclasesFalsa()
      ..respuestaClases = RespuestaModelo(codigoHttp: 406);
  });

  //mismo arbol que en la app: la sesion global y el vm que crea la ruta grupo
  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create:
                (_) => AutenticacionViewModel(
                  Servicioautenticacion(
                    Autenticacionrepositorio(
                      conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken(),
                    ),
                  ),
                  GoogleSignInFalso(),
                ),
          ),
          ChangeNotifierProvider(
            create:
                (_) => DetalleGrupoViewModel(
                  grupo,
                  ServicioCurso(CursoRepositorio(cliente: conexionCurso)),
                  Serviciohorario(
                    Horariorepositorio(conexion: conexionHorarios),
                  ),
                  Servicioalumno(Alumnosrepositorio(cliente: conexionAlumnos)),
                  Servicioclase(Claserepositorio(cliente: conexionClases)),
                )..cargar(),
          ),
        ],
        child: MaterialApp(home: Grupo(grupo: grupo)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('$capa - $tipo - Grupo - pinta las secciones del vm', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Iniciacion - Deportes'), findsOneWidget);
    expect(find.text('Lunes - Coliseo'), findsOneWidget);
    //sin alumnos ni clases: listas vacias, no "no se logro obtener"
    expect(find.text('No hay alumnos aun!'), findsOneWidget);
    expect(find.text('No hay clases aún!'), findsOneWidget);
    expect(find.textContaining('no se logro obtener'), findsNothing);
  });

  testWidgets('$capa - $tipo - Grupo - carga cada seccion una sola vez', (
    tester,
  ) async {
    await montar(tester);
    //un rebuild de la pantalla ya no repite las peticiones (antes cada
    //FutureBuilder creaba su future en build)
    await tester.pump();
    await tester.pumpAndSettle();

    expect(conexionCurso.llamadasObtener, 1);
    expect(conexionHorarios.llamadasHorarios, 1);
    expect(conexionAlumnos.llamadasAlumnos, 1);
    expect(conexionClases.llamadasClases, 1);
  });
}
