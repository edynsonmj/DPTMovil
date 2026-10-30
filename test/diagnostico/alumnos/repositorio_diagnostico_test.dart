@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionalumnosFalsa.dart';

//diagnostico del repositorio de alumnos (plan-diagnostico-alumnos.md): afirma
//el comportamiento CORRECTO y se espera que salga rojo mientras el bug
//exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  group('Alumnos (diagnostico del repositorio):', () {
    //la llamada a la conexion esta fuera del try del repositorio
    test('$capa - $tipo - Listar alumnos de grupo - BUG AL-02 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      final conexion = ConexionalumnosFalsa()..lanzar = TypeError();
      final repositorio = Alumnosrepositorio(cliente: conexion);

      final respuesta = await repositorio.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
