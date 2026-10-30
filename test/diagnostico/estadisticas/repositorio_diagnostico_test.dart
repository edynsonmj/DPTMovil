@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionEstadisticasFalsa.dart';

//diagnostico del repositorio de estadisticas (plan-diagnostico-
//estadisticas.md, 4.1): afirma el comportamiento CORRECTO y se espera que
//salga rojo mientras el bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexionEstadisticasFalsa conexion;
  late EstadisticasRespositorio repositorio;

  setUp(() {
    conexion = ConexionEstadisticasFalsa();
    repositorio = EstadisticasRespositorio(conexion: conexion);
  });

  group('Estadisticas (diagnostico del repositorio):', () {
    //los errores no se lanzan entre capas, se devuelven. El repositorio no
    //tiene ningun try; la conexion real deja pasar el TypeError de fromJson
    //(ES-02), asi que este camino existe en uso real
    test('$capa - $tipo - Estadisticas de las tres rutas - BUG ES-01 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
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
