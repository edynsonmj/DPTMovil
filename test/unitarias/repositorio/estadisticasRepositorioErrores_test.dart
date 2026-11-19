import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionEstadisticasFalsa.dart';

//errores del repositorio de estadisticas (ES-01). Registro:
//auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionEstadisticasFalsa conexion;
  late EstadisticasRespositorio repositorio;

  setUp(() {
    conexion = ConexionEstadisticasFalsa();
    repositorio = EstadisticasRespositorio(conexion: conexion);
  });

  group('Estadisticas (errores del repositorio):', () {
    //los errores no se lanzan entre capas, se devuelven. El repositorio no
    //tiene ningun try; la conexion real deja pasar el TypeError de fromJson
    //(ES-02), asi que este camino existe en uso real
    test('$capa - $tipo - Estadisticas de las tres rutas - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzar = TypeError();

      for (final pedir in [
        repositorio.generalCategorias,
        repositorio.generalCursos,
        repositorio.generalGrupos,
      ]) {
        final respuesta = await pedir('2026-01-01', '2026-12-31');
        expect(respuesta.codigoHttp, isNot(200));
        expect(respuesta.error, isNotNull);
      }
    });
  });
}
