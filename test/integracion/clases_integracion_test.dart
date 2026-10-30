import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAlumnosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 2 (plan-diagnostico-clases.md): el formulario
//de clase (Clasesviewmodel) y la pantalla del grupo (DetalleGrupoViewModel)
//con sus cadenas reales hasta las conexiones remotas y el transporte falso
//debajo. Solo se programan las rutas de clases: las demas secciones de la
//pantalla del grupo no se miran aqui
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late Dio dio;

  final grupo = Grupoentidad(
    categoria: 'Categoria Fase 4',
    curso: 'Curso Categoria Fase 4',
    anio: 2026,
    iterable: 1,
    cupos: 10,
    idInstructor: '2',
    fechaCreacion: '2026-10-22',
  );

  Servicioclase servicioClase() =>
      Servicioclase(Claserepositorio(cliente: Conexionclasesremoto(dio)));

  DetalleGrupoViewModel pantallaGrupo() => DetalleGrupoViewModel(
    grupo,
    ServicioCurso(CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)))),
    Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
    Servicioalumno(Alumnosrepositorio(cliente: Conexionalumnosremoto(dio))),
    servicioClase(),
  );

  Clasesviewmodel formulario() =>
      Clasesviewmodel(servicioClase())
        ..inicializarGrupo(grupo.categoria, grupo.curso, grupo.anio, grupo.iterable, '2');

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    dio = crearDioFalso(adaptador);
  });

  group('Clases (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Cargar clases - 200 pide la llave del grupo y convierte fecha y horas', () async {
      adaptador.responder('GET', '/clasesGrupo', 200, leerContrato('clases', 'clasesGrupo_200'));
      final vm = pantallaGrupo();

      await vm.cargarClases();

      expect(adaptador.peticionesA('GET', '/clasesGrupo').single.uri.queryParameters, {
        'categoria': 'Categoria Fase 4',
        'curso': 'Curso Categoria Fase 4',
        'anio': '2026',
        'iterable': '1',
      });
      expect(vm.clases.cargando, isFalse);
      expect(vm.clases.error, isNull);
      final primera = vm.clases.datos.first;
      expect(primera.codigo, 207);
      expect(primera.fecha, DateTime(2026, 10, 22));
      expect(primera.horas, 10);
    });

    test('$capa - $tipo - Cargar clases - grupo sin clases (200 [] y el antiguo GC-0002) es lista vacia sin error', () async {
      adaptador.responder('GET', '/clasesGrupo', 200, leerContrato('clases', 'clasesGrupo_vacio'));
      final vm = pantallaGrupo();
      await vm.cargarClases();
      expect(vm.clases.error, isNull);
      expect(vm.clases.datos, isEmpty);

      adaptador.responder('GET', '/clasesGrupo', 200, {
        'codigoError': 'GC-0002',
        'mensaje': 'El listado se encuentra vacio',
      });
      await vm.cargarClases();
      expect(vm.clases.error, isNull);
      expect(vm.clases.datos, isEmpty);
    });

    test('$capa - $tipo - Registrar clase - envia la clase del grupo con la fecha elegida y 201 es Exito', () async {
      adaptador.responder('POST', '/claseGrupo', 201);
      final fecha = DateTime(2026, 10, 28, 9, 15);

      final resultado = await formulario().registrarClase(fecha: fecha, horasTexto: ' 2 ');

      expect(resultado, isA<Exito>());
      expect(adaptador.peticionesA('POST', '/claseGrupo').single.cuerpo, {
        'codigo': null,
        'idGrupoCategoria': 'Categoria Fase 4',
        'idGrupoCurso': 'Curso Categoria Fase 4',
        'idGrupoAnio': 2026,
        'idGrupoIterable': 1,
        'idInstructor': '2',
        //el instante con zona, no la hora local sin ella (CL-06)
        'fecha': fecha.toUtc().toIso8601String(),
        'horas': 2,
        'minutos': 0,
        'observacion': null,
        'eliminado': 0,
      });
    });

    test('$capa - $tipo - Registrar clase - un 400 del backend es Fallo con su codigo y sin red es 503', () async {
      adaptador.responder('POST', '/claseGrupo', 400, {'fecha': 'no puede ser futura'});
      final r400 = await formulario().registrarClase(fecha: DateTime(2026, 10, 28), horasTexto: '2');
      expect(r400, isA<Fallo>());
      expect((r400 as Fallo).codigo, 400);

      adaptador.fallar('POST', '/claseGrupo', DioExceptionType.connectionError);
      final r503 = await formulario().registrarClase(fecha: DateTime(2026, 10, 28), horasTexto: '2');
      expect((r503 as Fallo).codigo, 503);
    });

    test('$capa - $tipo - Eliminar clase - envia el id y recarga; un 500 es Fallo y no recarga', () async {
      adaptador.responder('GET', '/clasesGrupo', 200, leerContrato('clases', 'clasesGrupo_200'));
      adaptador.responder('DELETE', '/clase', 200);
      final vm = pantallaGrupo();
      await vm.cargarClases();

      expect(await vm.eliminarClase(207), isA<Exito>());
      expect(adaptador.peticionesA('DELETE', '/clase').single.uri.queryParameters, {'id': '207'});
      expect(adaptador.peticionesA('GET', '/clasesGrupo'), hasLength(2));

      adaptador.responder('DELETE', '/clase', 500, 'error interno');
      final fallo = await vm.eliminarClase(211);
      expect(fallo, isA<Fallo>());
      expect((fallo as Fallo).codigo, 500);
      expect(adaptador.peticionesA('GET', '/clasesGrupo'), hasLength(2));
    });
    //los casos rojos de este montaje estan en
    //test/diagnostico/clases/integracion_diagnostico_test.dart
  });
}
