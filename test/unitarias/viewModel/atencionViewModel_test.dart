import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionatencionesFalsa.dart';

//el vm de la pantalla de una clase recibe su servicio por constructor desde
//la fase 5. El backend aun no tiene los endpoints de atenciones, asi que
//estos casos con el doble son la unica prueba del camino de exito
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionatencionesFalsa conexion;
  late Atencionviewmodel vm;

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

  Atencionmodelo atencion(String id, String nombre) => Atencionmodelo(
    alumno: Alumnomodelo(
      id: id,
      tipo: 'Estudiante',
      nombre: nombre,
      correo: '$id@x.co',
      sexo: 'F',
      tipoid: 'CC',
    ),
    idClase: 210,
    estaAtendido: false,
  );

  setUp(() {
    conexion = ConexionatencionesFalsa()
      ..respuestaAtenciones = RespuestaModelo(
        codigoHttp: 200,
        datos: [atencion('alu1', 'Ana'), atencion('alu2', 'Luis')],
      );
    vm = Atencionviewmodel(
      Servicioatencion(Atencionesrepositorio(conexion: conexion)),
    );
  });

  group('Atenciones (vm con doble):', () {
    test('$capa - $tipo - Cargar atenciones - 200 carga la lista', () async {
      await vm.cargarAtenciones(grupo, clase);

      expect(conexion.ultimaClase, 'Deportes/Iniciacion/2026/1/210');
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.atenciones?.map((a) => a.alumno.nombre), ['Ana', 'Luis']);
    });

    test('$capa - $tipo - Marcar asistencia - cambia la atencion y notifica', () async {
      await vm.cargarAtenciones(grupo, clase);
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      vm.marcarAsistencia(1, true);

      expect(vm.atenciones![0].estaAtendido, isFalse);
      expect(vm.atenciones![1].estaAtendido, isTrue);
      expect(notificaciones, 1);
    });

    test('$capa - $tipo - Registrar atenciones - 200 envia lo marcado', () async {
      await vm.cargarAtenciones(grupo, clase);
      vm.marcarAsistencia(0, true);

      final resultado = await vm.registrarAtenciones();

      expect(resultado, isA<Exito>());
      expect(conexion.ultimoIdClaseRegistro, 210);
      expect(
        conexion.ultimasRegistradas!.map((a) => a.estaAtendido),
        [true, false],
      );
    });

    test('$capa - $tipo - Cargar atenciones - salir antes de que llegue no revienta', () async {
      //como la ruta: empieza a cargar al crearse y provider llama a dispose
      //al salir, aunque la respuesta siga en camino
      final carga = vm.cargarAtenciones(grupo, clase);
      vm.dispose();

      await expectLater(carga, completes);
    });
  });
}
