@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionclasesFalsa.dart';

//diagnostico del repositorio de clases (plan-diagnostico-clases.md): afirman
//el comportamiento CORRECTO y se espera que salgan rojas mientras el bug
//exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexionclasesFalsa conexion;
  late Claserepositorio repositorio;

  Claseentidad clase({DateTime? fecha, int? horas = 2}) => Claseentidad(
    idGrupoCategoria: 'Deportes',
    idGrupoCurso: 'Iniciacion',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'ins1',
    fecha: fecha,
    horas: horas,
    minutos: 0,
    eliminado: 0,
  );

  setUp(() {
    conexion = ConexionclasesFalsa();
    repositorio = Claserepositorio(cliente: conexion);
  });

  group('Clases (diagnostico del repositorio):', () {
    //los errores no se lanzan entre capas, se devuelven. listarClaseGrupo
    //protege la conversion pero no la llamada a la conexion, y eliminarClase
    //solo captura Exception; la conexion real deja pasar el TypeError de
    //Clasemodelo.fromJson (CL-05)
    test('$capa - $tipo - Listar, agregar y eliminar - BUG CL-03 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzar = TypeError();

      for (final pedir in <Future<dynamic> Function()>[
        () => repositorio.listarClaseGrupo('Deportes', 'Iniciacion', 2026, 1),
        () => repositorio.agregarClase(clase(fecha: DateTime(2026, 10, 28))),
        () => repositorio.eliminarClase(210),
      ]) {
        final respuesta = await pedir();
        expect(respuesta.codigoHttp, isNot(200));
        expect(respuesta.error, isNotNull);
      }
    });

    //Clasemodelo.fromEntidad hace fecha!, horas! y minutos!; agregarClase solo
    //captura Exception
    test('$capa - $tipo - Agregar clase - BUG CL-04 - una entidad sin fecha u horas devuelve un error, sin lanzar', () async {
      for (final incompleta in [clase(fecha: null), clase(fecha: DateTime(2026, 10, 28), horas: null)]) {
        Object? lanzado;
        dynamic respuesta;
        try {
          respuesta = await repositorio.agregarClase(incompleta);
        } catch (e) {
          lanzado = e;
        }
        expect(lanzado, isNull, reason: 'lanzo: $lanzado');
        expect(respuesta.codigoHttp, isNot(201));
      }
      expect(conexion.llamadasAgregar, 0);
    });
  });
}
