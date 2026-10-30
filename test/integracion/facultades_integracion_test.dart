import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionFacultadRemoto.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 9b (plan-diagnostico-instructores-facultades
//.md): el vm del desplegable del registro con su cadena real hasta
//Conexionfacultadremoto y el transporte falso debajo, con la respuesta del
//contrato observado
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late Facultadesviewmodel vm;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = Facultadesviewmodel(
      Serviciofacultades(
        Facultadesrepositorio(conexion: Conexionfacultadremoto(crearDioFalso(adaptador))),
      ),
    );
  });

  group('Facultades (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Listar facultades - 200 real llega como lista de nombres', () async {
      adaptador.responder('GET', '/facultades', 200, leerContrato('facultades', 'facultades_200'));

      await vm.listarYNotificarFacultades();

      expect(adaptador.peticionesA('GET', '/facultades'), hasLength(1));
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.facultades, ['fiet']);
    });

    test('$capa - $tipo - Listar facultades - sin red el registro muestra el 503', () async {
      adaptador.fallar('GET', '/facultades', DioExceptionType.connectionError);

      await vm.listarYNotificarFacultades();

      expect(vm.cargando, isFalse);
      expect(vm.error, startsWith('Código: 503'));
      expect(vm.facultades, isEmpty);
    });

    test('$capa - $tipo - Listar facultades - 200 con un objeto es 406', () async {
      adaptador.responder('GET', '/facultades', 200, {'mensaje': 'no es una lista'});

      await vm.listarYNotificarFacultades();

      expect(vm.error, startsWith('Código: 406'));
      expect(vm.facultades, isEmpty);
    });
    //los casos rojos de este montaje (FA-01, FA-03, FA-04) estan en
    //test/diagnostico/facultades/integracion_diagnostico_test.dart
  });
}
