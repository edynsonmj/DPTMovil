import 'package:dpt_movil/data/models/errorModelo.dart';
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

  //el doble responde la lista del contrato (listar_200.json): Ana y Luis
  //sin marcar, Marta ya marcada
  setUp(() {
    conexion = ConexionatencionesFalsa();
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
      expect(vm.atenciones?.map((a) => a.alumno.nombre), [
        'Ana Gomez',
        'Luis Perez',
        'Marta Ruiz',
      ]);
      expect(vm.atenciones?.map((a) => a.estaAtendido), [false, false, true]);
    });

    test('$capa - $tipo - Marcar asistencia - cambia la atencion y notifica', () async {
      await vm.cargarAtenciones(grupo, clase);
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      vm.marcarAsistencia(1, true);

      //solo cambia el indice pedido; los demas conservan lo que trajo la carga
      expect(vm.atenciones!.map((a) => a.estaAtendido), [false, true, true]);
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
        [true, false, true],
      );
      expect(
        conexion.ultimasRegistradas!.map((a) => a.alumno.id),
        ['1061001', '1061002', '1061003'],
      );
    });

    test('$capa - $tipo - Cargar atenciones - salir antes de que llegue no revienta', () async {
      //como la ruta: empieza a cargar al crearse y provider llama a dispose
      //al salir, aunque la respuesta siga en camino
      final carga = vm.cargarAtenciones(grupo, clase);
      vm.dispose();

      await expectLater(carga, completes);
    });

    test('$capa - $tipo - Cargar atenciones - 404, 500 y 503 quedan como error', () async {
      for (final codigo in [404, 500, 503]) {
        conexion.respuestaAtenciones = error(codigo, 'GET');

        await vm.cargarAtenciones(grupo, clase);

        expect(vm.cargando, isFalse, reason: 'codigo $codigo');
        expect(vm.error, contains('$codigo'));
        expect(vm.error, contains('detalle $codigo'));
        expect(vm.atenciones, isEmpty);
      }
    });

    test('$capa - $tipo - Cargar atenciones - 200 vacia no es error', () async {
      conexion.respuestaAtenciones = RespuestaModelo(
        codigoHttp: 200,
        datos: atencionesDelContrato('listar_vacia'),
      );

      await vm.cargarAtenciones(grupo, clase);

      expect(vm.error, isNull);
      expect(vm.atenciones, isEmpty);
    });

    test('$capa - $tipo - Cargar atenciones - un 200 tras un error limpia el error', () async {
      conexion.respuestaAtenciones = error(500, 'GET');
      await vm.cargarAtenciones(grupo, clase);
      expect(vm.error, isNotNull);

      conexion.respuestaAtenciones = RespuestaModelo(
        codigoHttp: 200,
        datos: atencionesDelContrato('listar_200'),
      );
      await vm.cargarAtenciones(grupo, clase);

      expect(vm.error, isNull);
      expect(vm.atenciones?.length, 3);
    });

    test('$capa - $tipo - Registrar atenciones - 400 y 500 son Fallo con su mensaje', () async {
      await vm.cargarAtenciones(grupo, clase);
      for (final codigo in [400, 500]) {
        conexion.respuestaRegistrar = error(codigo, 'POST');

        final resultado = await vm.registrarAtenciones();

        expect(resultado, isA<Fallo>(), reason: 'codigo $codigo');
        final fallo = resultado as Fallo;
        expect(fallo.codigo, codigo);
        expect(fallo.mensaje, 'detalle $codigo');
        expect(fallo.origen, 'POST /asistenciasClase');
      }
    });

    test('$capa - $tipo - Registrar atenciones - sin alumnos no llega a la red', () async {
      conexion.respuestaAtenciones = RespuestaModelo(
        codigoHttp: 200,
        datos: atencionesDelContrato('listar_vacia'),
      );
      await vm.cargarAtenciones(grupo, clase);

      final resultado = await vm.registrarAtenciones();

      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 0);
      expect(resultado.mensaje, 'No hay alumnos para registrar');
      expect(conexion.llamadasRegistrar, 0);
    });

    test('$capa - $tipo - Registrar atenciones - envia la ultima marca de cada alumno', () async {
      await vm.cargarAtenciones(grupo, clase);
      //el usuario duda: marca, desmarca y vuelve a marcar a Ana
      vm.marcarAsistencia(0, true);
      vm.marcarAsistencia(0, false);
      vm.marcarAsistencia(0, true);
      //y desmarca a Marta, que venia marcada
      vm.marcarAsistencia(2, false);

      await vm.registrarAtenciones();

      expect(
        conexion.ultimasRegistradas!.map((a) => a.estaAtendido),
        [true, false, false],
      );
    });
  });
}

//respuesta de error como la arman las conexiones: el vm lee mensaje, metodo
//y url del ErrorModelo
RespuestaModelo error(int codigo, String metodo) => RespuestaModelo(
  codigoHttp: codigo,
  error: ErrorModelo(
    codigoHttp: codigo,
    mensaje: 'detalle $codigo',
    url: metodo == 'GET' ? '/asistenciasClase' : '/asistenciasClase',
    metodo: metodo,
  ),
);
