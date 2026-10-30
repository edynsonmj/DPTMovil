import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionfacultadesFalsa.dart';

//el repositorio ya recibe su conexion por constructor: se prueba con el
//doble y sin backend, antes y despues de migrar facultades (fase 2)
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  test('$capa - $tipo - Listar facultades - 200 devuelve los nombres', () async {
    final conexion = ConexionfacultadesFalsa()
      ..respuestaListar = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Facultadmodelo(nombre: 'Ingenieria'),
          Facultadmodelo(nombre: 'Salud'),
        ],
      );
    final repositorio = Facultadesrepositorio(conexion: conexion);

    final respuesta = await repositorio.listarFacultades();

    expect(respuesta.codigoHttp, 200);
    //el desplegable del registro solo necesita los nombres
    expect(respuesta.datos, isA<List<String>>());
    expect(respuesta.datos, ['Ingenieria', 'Salud']);
  });

  //modulo 9b (plan-diagnostico-instructores-facultades.md); el caso rojo
  //(FA-02) esta en test/diagnostico/facultades/repositorio_diagnostico_test.dart
  test('$capa - $tipo - Listar facultades - un error y el 406 pasan sin cambios', () async {
    final e503 = RespuestaModelo(
      codigoHttp: 503,
      error: ErrorModelo(codigoHttp: 503, mensaje: 'sin red', url: '/facultades', metodo: 'GET'),
    );
    final conexion = ConexionfacultadesFalsa()..respuestaListar = e503;
    final repositorio = Facultadesrepositorio(conexion: conexion);
    expect(await repositorio.listarFacultades(), same(e503));

    final e406 = RespuestaModelo(codigoHttp: 406);
    conexion.respuestaListar = e406;
    expect(await repositorio.listarFacultades(), same(e406));
  });
}
