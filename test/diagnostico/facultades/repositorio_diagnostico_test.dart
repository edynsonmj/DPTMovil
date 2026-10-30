@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionfacultadesFalsa.dart';

//diagnostico del repositorio de facultades (plan-diagnostico-instructores-
//facultades.md): afirma el comportamiento CORRECTO y se espera que salga rojo
//mientras el bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  group('Facultades (diagnostico del repositorio):', () {
    //listarFacultades no tiene try
    test('$capa - $tipo - Listar facultades - BUG FA-02 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      final conexion = ConexionfacultadesFalsa()..lanzar = TypeError();
      final repositorio = Facultadesrepositorio(conexion: conexion);

      final respuesta = await repositorio.listarFacultades();

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
