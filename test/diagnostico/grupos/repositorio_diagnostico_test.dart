@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexiongruposFalsa.dart';

//diagnostico del repositorio de grupos (plan-diagnostico-grupos.md): afirman
//el comportamiento CORRECTO y se espera que salgan rojas mientras el bug
//exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexiongruposFalsa conexion;
  late Gruporepositorio repositorio;

  setUp(() {
    conexion = ConexiongruposFalsa();
    repositorio = Gruporepositorio(conexion: conexion);
  });

  group('Grupos (diagnostico del repositorio):', () {
    //los errores no se lanzan entre capas, se devuelven. El repositorio no
    //tiene ningun try en las listas
    test('$capa - $tipo - Listar grupos (curso, instructor, disponibles) - BUG GR-01 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzarAlListar = TypeError();

      for (final pedir in <Future Function()>[
        () => repositorio.listarGruposDe('Deportes', 'Iniciacion'),
        () => repositorio.listarGruposInstructores('ins1'),
        () => repositorio.listarGruposDisponiblesInscripcion(),
      ]) {
        final respuesta = await pedir();
        expect(respuesta.codigoHttp, isNot(200));
        expect(respuesta.error, isNotNull);
      }
    });
    //la mitad de GR-02 que tocaba al repositorio (la fecha llega al modelo)
    //paso a test/unitarias/repositorio/grupoRepositorio_test.dart
  });
}
