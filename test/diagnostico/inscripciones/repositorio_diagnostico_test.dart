@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexioninscripcionFalsa.dart';

//diagnostico del repositorio de inscripciones (plan-diagnostico-
//inscripciones.md, 4.1): afirman el comportamiento CORRECTO y se espera que
//salgan rojas mientras el bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexioninscripcionFalsa conexion;
  late Inscripcionrepositorio repositorio;

  Inscripcionentidad inscripcion() => Inscripcionentidad(
    alumnoId: 'alu1',
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
  );

  setUp(() {
    conexion = ConexioninscripcionFalsa();
    repositorio = Inscripcionrepositorio(conexion: conexion);
  });

  group('Inscripciones (diagnostico del repositorio):', () {
    //los errores no se lanzan entre capas, se devuelven. El repositorio
    //solo captura Exception; la conexion real tambien, asi que un TypeError
    //suyo (p. ej. un 2xx distinto del esperado y sin cuerpo, como en AS-07)
    //llega hasta el vm
    test('$capa - $tipo - Agregar inscripcion - BUG IN-12 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzarAlAgregar = TypeError();

      final respuesta = await repositorio.agregarInscripcion(inscripcion());

      expect(respuesta.codigoHttp, isNot(201));
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Eliminar inscripcion - BUG IN-12 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzarAlEliminar = TypeError();

      final respuesta = await repositorio.eliminarInscripcion(inscripcion());

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
