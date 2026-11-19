import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionInstructoresRemoto.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 9b (plan-diagnostico-instructores-facultades
//.md): el vm del desplegable del formulario de grupo con su cadena real hasta
//Conexioninstructoresremoto y el transporte falso debajo, con la respuesta
//del contrato observado
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late InstructoresViewModel vm;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = InstructoresViewModel(
      ServicioInstructor(
        Instructoresrepositorio(conexion: Conexioninstructoresremoto(crearDioFalso(adaptador))),
      ),
    );
  });

  group('Instructores (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Listar instructores - 200 real llega con los 4 campos', () async {
      adaptador.responder('GET', '/instructores', 200, leerContrato('instructores', 'instructores_200'));

      await vm.listarYNotificarInstructores();

      expect(adaptador.peticionesA('GET', '/instructores'), hasLength(1));
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      final i = vm.instructores.single;
      expect([i.id, i.nombre, i.correo, i.sexo], [
        '2', 'edynson muñoz jimenez', 'edynsonmj@gmail.com', 'M',
      ]);
    });

    test('$capa - $tipo - Listar instructores - 200 [] es lista vacia sin error', () async {
      adaptador.responder('GET', '/instructores', 200, []);

      await vm.listarYNotificarInstructores();

      expect(vm.error, isNull);
      expect(vm.instructores, isEmpty);
    });

    test('$capa - $tipo - Listar instructores - sin red el formulario muestra el 503', () async {
      adaptador.fallar('GET', '/instructores', DioExceptionType.connectionError);

      await vm.listarYNotificarInstructores();

      expect(vm.cargando, isFalse);
      expect(vm.error, startsWith('Código: 503'));
      expect(vm.instructores, isEmpty);
    });

    test('$capa - $tipo - Listar instructores - 200 con un objeto es 406', () async {
      adaptador.responder('GET', '/instructores', 200, {'mensaje': 'no es una lista'});

      await vm.listarYNotificarInstructores();

      expect(vm.error, startsWith('Código: 406'));
      expect(vm.instructores, isEmpty);
    });

    //H-04: la conexion de instructores captura todo (catch (e)), asi que un
    //instructor incompleto llega como error con codigo y no como excepcion
    test('$capa - $tipo - Listar instructores - un instructor sin id llega como error con codigo', () async {
      final instructor = Map<String, dynamic>.from(
        (leerContrato('instructores', 'instructores_200') as List).first,
      )..['id'] = null;
      adaptador.responder('GET', '/instructores', 200, [instructor]);

      await vm.listarYNotificarInstructores();

      expect(vm.error, startsWith('Código: '));
      expect(vm.instructores, isEmpty);
    });

    //antes diagnostico de IT-02: las rutas grupoFormulario e instructores
    //crean el vm y lo desechan al salir; una carga que llega despues no
    //debe notificar
    test('$capa - $tipo - Listar instructores - una respuesta que llega despues de dispose no lanza', () async {
      adaptador.responder('GET', '/instructores', 200, leerContrato('instructores', 'instructores_200'));
      final retenida = adaptador.retener('GET', '/instructores');
      final carga = vm.listarYNotificarInstructores();
      await _hastaQue(() => adaptador.peticiones.length == 1);
      vm.dispose();
      retenida.complete();

      Object? lanzado;
      try {
        await carga;
      } catch (e) {
        lanzado = e;
      }
      expect(lanzado, isNull, reason: '$lanzado');
    });

    //IT-01 (corregido el 2026-11-19) salio del diagnostico.
    ///v3/api-docs documenta 404 "No existen instructores registrados"
    test('$capa - $tipo - Listar instructores - el 404 documentado de no hay instructores es lista vacia sin error', () async {
      adaptador.responder('GET', '/instructores', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No existen instructores registrados',
      });

      await vm.listarYNotificarInstructores();

      expect(vm.error, isNull, reason: '${vm.error}');
      expect(vm.instructores, isEmpty);
    });
  });
}

Future<void> _hastaQue(bool Function() condicion) async {
  for (var i = 0; i < 200 && !condicion(); i++) {
    await Future.delayed(const Duration(milliseconds: 5));
  }
  expect(condicion(), isTrue, reason: 'la peticion no llego al adaptador');
}
