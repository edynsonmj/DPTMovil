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
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 9a (plan-diagnostico-alumnos.md): la seccion
//de alumnos de la pantalla del grupo (DetalleGrupoViewModel) con su cadena
//real hasta Conexionalumnosremoto y el transporte falso debajo, con las
//respuestas del contrato observado. Las demas secciones no se miran
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late DetalleGrupoViewModel vm;

  final grupo = Grupoentidad(
    categoria: 'Categoria Fase 4',
    curso: 'Curso Categoria Fase 4',
    anio: 2026,
    iterable: 1,
    cupos: 10,
    fechaCreacion: '2026-10-22',
  );

  Map<String, dynamic> alumnoDelContrato() => Map<String, dynamic>.from(
    (leerContrato('alumnos', 'alumnosGrupo_200') as List).first,
  );

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    final dio = crearDioFalso(adaptador);
    vm = DetalleGrupoViewModel(
      grupo,
      ServicioCurso(CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)))),
      Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
      Servicioalumno(Alumnosrepositorio(cliente: Conexionalumnosremoto(dio))),
      Servicioclase(Claserepositorio(cliente: Conexionclasesremoto(dio))),
    );
  });

  group('Alumnos del grupo (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Cargar alumnos - 200 pide la llave del grupo y lista a sus alumnos con sus datos', () async {
      adaptador.responder('GET', '/alumnosGrupo', 200, leerContrato('alumnos', 'alumnosGrupo_200'));

      await vm.cargar();

      expect(adaptador.peticionesA('GET', '/alumnosGrupo').single.uri.queryParameters, {
        'categoria': 'Categoria Fase 4',
        'curso': 'Curso Categoria Fase 4',
        'anio': '2026',
        'iterable': '1',
      });
      expect(vm.alumnos.cargando, isFalse);
      expect(vm.alumnos.error, isNull);
      final primero = vm.alumnos.datos.first;
      expect(vm.alumnos.datos.map((a) => a.id), ['1111111', '2222222']);
      expect([primero.nombre, primero.tipo, primero.sexo, primero.tipoid], [
        'Daniel Antonio Tucanes', 'Estudiante', 'M', 'CC',
      ]);
    });

    test('$capa - $tipo - Cargar alumnos - el GC-0002 de grupo sin alumnos es lista vacia sin error', () async {
      adaptador.responder('GET', '/alumnosGrupo', 200, leerContrato('alumnos', 'alumnosGrupo_vacio'));

      await vm.cargar();

      expect(vm.alumnos.error, isNull);
      expect(vm.alumnos.datos, isEmpty);
    });

    test('$capa - $tipo - Cargar alumnos - sin red la seccion muestra el 503', () async {
      adaptador.fallar('GET', '/alumnosGrupo', DioExceptionType.connectionError);

      await vm.cargar();

      expect(vm.alumnos.cargando, isFalse);
      expect(vm.alumnos.error, startsWith('Código: 503'));
      expect(vm.alumnos.datos, isEmpty);
    });

    //AL-01, AL-03 y AL-04 (corregidos el 2026-11-19) salieron del diagnostico
    test('$capa - $tipo - Cargar alumnos - el codigo y la imagen del alumno llegan a la pantalla', () async {
      adaptador.responder('GET', '/alumnosGrupo', 200, [
        alumnoDelContrato()
          ..['codigo'] = '104619011001'
          ..['imagen'] = 33,
      ]);

      await vm.cargar();

      final a = vm.alumnos.datos.single;
      expect([a.codigo, a.imagen], ['104619011001', 33]);
    });

    ///v3/api-docs documenta 404 "No existen alumnos para el grupo consultado"
    test('$capa - $tipo - Cargar alumnos - el 404 documentado de grupo sin alumnos es lista vacia sin error', () async {
      adaptador.responder('GET', '/alumnosGrupo', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No existen alumnos para el grupo consultado',
      });

      await vm.cargar();

      expect(vm.alumnos.error, isNull, reason: '${vm.alumnos.error}');
      expect(vm.alumnos.datos, isEmpty);
    });

    test('$capa - $tipo - Cargar alumnos - un alumno incompleto llega como error con codigo, no como excepcion', () async {
      adaptador.responder('GET', '/alumnosGrupo', 200, [alumnoDelContrato()..['nombre'] = null]);

      await vm.cargar();

      expect(vm.alumnos.error, startsWith('Código: '));
      expect(vm.alumnos.datos, isEmpty);
    });
  });
}
