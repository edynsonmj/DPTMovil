import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/conexiongruposFalsa.dart';

//vm de la pantalla del coordinador para abrir y cerrar inscripciones (plan
//de abrir inscripciones, fase 3). Misma cadena que la ruta, con el doble de
//grupos debajo y las respuestas observadas del backend
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexiongruposFalsa conexion;
  late PeriodoInscripcionViewModel vm;

  //dia de la captura del contrato
  final hoy = DateTime(2026, 10, 29);

  GrupoModelo delContrato(String nombre) =>
      GrupoModelo.fromJson(leerContrato('inscripciones', nombre));

  List<GrupoModelo> gruposDelContrato() =>
      (leerContrato('inscripciones', 'gruposNoEliminados_200') as List)
          .map((json) => GrupoModelo.fromJson(json))
          .toList();

  RespuestaModelo error(int codigo, String mensaje) => RespuestaModelo(
    codigoHttp: codigo,
    error: ErrorModelo(
      codigoHttp: codigo,
      mensaje: mensaje,
      url: '/grupo/periodo',
      metodo: 'PATCH',
    ),
  );

  setUp(() {
    conexion =
        ConexiongruposFalsa()
          ..respuestaNoEliminados = RespuestaModelo(
            codigoHttp: 200,
            datos: gruposDelContrato(),
          );
    vm = PeriodoInscripcionViewModel(
      Serviciogrupo(Gruporepositorio(conexion: conexion)),
      hoy: () => hoy,
    );
  });

  //el grupo cerrado del contrato (prueba_.../2), el que abre abrir_200.json
  Grupoentidad grupoCerrado() => vm.grupos.datos[2];

  group('Periodo de inscripcion (vm con doble):', () {
    test('$capa - $tipo - Cargar grupos - 200 carga los grupos con su estado', () async {
      await vm.cargar();

      expect(conexion.llamadasNoEliminados, 1);
      expect(vm.grupos.cargando, isFalse);
      expect(vm.grupos.error, isNull);
      expect(vm.grupos.datos.map(vm.estadoDe), [
        EstadoInscripcion.abierta,
        EstadoInscripcion.sinPeriodo,
        EstadoInscripcion.cerrada,
      ]);
    });

    test('$capa - $tipo - Cargar grupos - un error queda con su codigo y la lista vacia', () async {
      conexion.respuestaNoEliminados = error(503, 'No hay conexion a internet');

      await vm.cargar();

      expect(vm.grupos.cargando, isFalse);
      expect(vm.grupos.error, contains('503'));
      expect(vm.grupos.error, contains('No hay conexion a internet'));
      expect(vm.grupos.datos, isEmpty);
    });

    test('$capa - $tipo - Filtrar - por categoria y de vuelta a todas', () async {
      await vm.cargar();

      vm.filtrar('Categoria Fase 4');
      expect(vm.gruposFiltrados.map((g) => g.iterable), [1, 2]);

      vm.filtrar(null);
      expect(vm.gruposFiltrados, hasLength(3));
    });

    test('$capa - $tipo - Abrir inscripciones - reemplaza solo ese grupo con el que devuelve el backend', () async {
      await vm.cargar();
      final otros = [vm.grupos.datos[0], vm.grupos.datos[1]];
      conexion.respuestaAbrir = RespuestaModelo(
        codigoHttp: 200,
        datos: delContrato('abrir_200'),
      );

      final resultado = await vm.abrir(
        grupoCerrado(),
        apertura: DateTime(2026, 10, 29),
        cierre: DateTime(2026, 11, 30),
      );

      expect(resultado, isA<Exito<Grupoentidad>>());
      expect(conexion.ultimoPeriodo?.apertura, '2026-10-29');
      expect(conexion.ultimoPeriodo?.cierre, '2026-11-30');
      expect(vm.estadoDe(grupoCerrado()), EstadoInscripcion.abierta);
      expect(grupoCerrado().fechaInscripcionCierre, '2026-11-30');
      //los demas grupos son los mismos objetos y no se recargo la lista
      expect(vm.grupos.datos[0], same(otros[0]));
      expect(vm.grupos.datos[1], same(otros[1]));
      expect(conexion.llamadasNoEliminados, 1);
    });

    test('$capa - $tipo - Cerrar inscripciones - el grupo queda cerrado', () async {
      await vm.cargar();
      final abierto = vm.grupos.datos[0];
      //el doble devuelve ese mismo grupo ya cerrado
      conexion.respuestaCerrar = RespuestaModelo(
        codigoHttp: 200,
        datos: GrupoModelo.fromJson({
          ...leerContrato('inscripciones', 'gruposNoEliminados_200')[0],
          //el cierre manual no toca las fechas: manda sobre ellas
          'inscripcionesCerradasManual': true,
        }),
      );

      final resultado = await vm.cerrar(abierto);

      expect(resultado, isA<Exito<Grupoentidad>>());
      expect(conexion.ultimoGrupoCerrado, 'Categoria Fase 4/Curso Categoria Fase 4/2026/1');
      expect(vm.estadoDe(vm.grupos.datos[0]), EstadoInscripcion.cerrada);
    });

    test('$capa - $tipo - Abrir inscripciones - un 400 es Fallo con el mensaje y no toca la lista', () async {
      await vm.cargar();
      final antes = vm.grupos.datos;
      conexion.respuestaAbrir = error(
        422,
        '{"codigoError":"GC-0015","mensaje":"Las fechas del grupo no son validas"}',
      );

      final resultado = await vm.abrir(
        grupoCerrado(),
        apertura: DateTime(2026, 11, 10),
        cierre: DateTime(2026, 11, 1),
      );

      expect(resultado, isA<Fallo>());
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 422);
      expect(fallo.mensaje, contains('GC-0015'));
      expect(fallo.origen, 'PATCH /grupo/periodo');
      expect(vm.grupos.datos, same(antes));
    });

    test('$capa - $tipo - Cerrar inscripciones - un 404 es Fallo', () async {
      await vm.cargar();
      conexion.respuestaCerrar = error(404, 'GC-0003 el grupo buscado no existe');

      final resultado = await vm.cerrar(grupoCerrado());

      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 404);
    });

    test('$capa - $tipo - Abrir inscripciones - sin cierre no llama al backend', () async {
      await vm.cargar();

      final resultado = await vm.abrir(grupoCerrado());

      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).mensaje, contains('fecha de cierre'));
      expect(conexion.llamadasAbrir, 0);
    });

    test('$capa - $tipo - Abrir inscripciones - sin apertura abre desde hoy', () async {
      await vm.cargar();
      conexion.respuestaAbrir = RespuestaModelo(codigoHttp: 200, datos: delContrato('abrir_200'));

      await vm.abrir(grupoCerrado(), cierre: DateTime(2026, 11, 30));

      expect(conexion.ultimoPeriodo?.apertura, FormatDate.fechaACadena(hoy, '-'));
    });

    test('$capa - $tipo - Abrir inscripciones - mientras esta en camino el grupo no admite otra operacion', () async {
      await vm.cargar();
      conexion.respuestaAbrir = RespuestaModelo(
        codigoHttp: 200,
        datos: delContrato('abrir_200'),
      );
      final grupo = grupoCerrado();

      final primera = vm.abrir(grupo, cierre: DateTime(2026, 11, 30));
      //la marca se pone antes de esperar al backend
      expect(vm.procesando(grupo), isTrue);
      final segunda = await vm.cerrar(grupo);
      await primera;

      expect(segunda, isA<Fallo>());
      expect((segunda as Fallo).codigo, 0);
      expect(conexion.llamadasAbrir, 1);
      expect(conexion.llamadasCerrar, 0);
      expect(vm.procesando(grupoCerrado()), isFalse);
    });

    test('$capa - $tipo - Cargar grupos - salir antes de que llegue no revienta', () async {
      final carga = vm.cargar();
      vm.dispose();

      await expectLater(carga, completes);
    });
  });
}
