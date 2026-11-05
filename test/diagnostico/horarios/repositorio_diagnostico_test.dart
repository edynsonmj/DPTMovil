@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionhorariosFalsa.dart';

//diagnostico del repositorio de horarios (plan-diagnostico-horarios.md):
//afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexionhorariosFalsa conexion;
  late Horariorepositorio repositorio;

  setUp(() {
    conexion = ConexionhorariosFalsa();
    repositorio = Horariorepositorio(conexion: conexion);
  });

  group('Horarios (diagnostico del repositorio):', () {
    //la llamada a la conexion esta fuera del try del repositorio
    test('$capa - $tipo - Listar horarios de grupo - BUG HO-02 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzar = TypeError();

      final respuesta = await repositorio.obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
    //la mitad de HO-01 que tocaba al repositorio (el id llega a la entidad)
    //paso a test/unitarias/repositorio/horarioRepositorio_test.dart
  });
}
