@Tags(['diagnostico'])
library;

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

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de la lista de alumnos del grupo de punta a punta sin backend
//(plan-diagnostico-alumnos.md): el mismo montaje que
//test/integracion/alumnos_integracion_test.dart. Afirman el comportamiento
//CORRECTO y se espera que salgan rojas mientras el bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late DetalleGrupoViewModel vm;

  Map<String, dynamic> alumnoDelContrato() => Map<String, dynamic>.from(
    (leerContrato('alumnos', 'alumnosGrupo_200') as List).first,
  );

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    final dio = crearDioFalso(adaptador);
    vm = DetalleGrupoViewModel(
      Grupoentidad(
        categoria: 'Categoria Fase 4',
        curso: 'Curso Categoria Fase 4',
        anio: 2026,
        iterable: 1,
        cupos: 10,
        fechaCreacion: '2026-10-22',
      ),
      ServicioCurso(CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)))),
      Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
      Servicioalumno(Alumnosrepositorio(cliente: Conexionalumnosremoto(dio))),
      Servicioclase(Claserepositorio(cliente: Conexionclasesremoto(dio))),
    );
  });

  group('Alumnos del grupo (diagnostico de punta a punta):', () {
    //Alumnomodelo.fromJson no lee codigo ni imagen (causa de AS-05)
    test('$capa - $tipo - Cargar alumnos - BUG AL-01 - el codigo y la imagen del alumno llegan a la pantalla', () async {
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
    test('$capa - $tipo - Cargar alumnos - BUG AL-03 - el 404 documentado de grupo sin alumnos es lista vacia sin error', () async {
      adaptador.responder('GET', '/alumnosGrupo', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No existen alumnos para el grupo consultado',
      });

      await vm.cargar();

      expect(vm.alumnos.error, isNull, reason: '${vm.alumnos.error}');
      expect(vm.alumnos.datos, isEmpty);
    });

    //un alumno sin nombre: fromJson lanza un TypeError que atraviesa la
    //conexion (solo captura Exception) y el repositorio (llamada fuera del try)
    test('$capa - $tipo - Cargar alumnos - BUG AL-04 - un alumno incompleto llega como error con codigo, no como excepcion', () async {
      adaptador.responder('GET', '/alumnosGrupo', 200, [alumnoDelContrato()..['nombre'] = null]);

      await vm.cargar();

      expect(vm.alumnos.error, isNotNull);
      expect(vm.alumnos.error, startsWith('Código: '));
    });
  });
}
