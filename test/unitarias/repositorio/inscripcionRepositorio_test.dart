import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexioninscripcionFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 6
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexioninscripcionFalsa conexion;
  late Inscripcionrepositorio repositorio;

  Inscripcionentidad inscripcion() => Inscripcionentidad(
    alumnoId: 'alu1',
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
  );

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexioninscripcionFalsa();
    repositorio = Inscripcionrepositorio(conexion: conexion);
  });

  group('Inscripciones (repositorio con doble):', () {
    test('$capa - $tipo - Agregar inscripcion - envia el modelo armado', () async {
      conexion.respuestaAgregar = RespuestaModelo(codigoHttp: 201);

      final respuesta = await repositorio.agregarInscripcion(inscripcion());

      expect(conexion.llamadasAgregar, 1);
      final enviada = conexion.ultimaAgregada!;
      expect(enviada.alumnoId, 'alu1');
      expect(enviada.categoria, 'Deportes');
      expect(enviada.curso, 'Iniciacion');
      expect(enviada.anio, 2026);
      expect(enviada.iterable, 1);
      expect(respuesta.codigoHttp, 201);
    });

    test('$capa - $tipo - Validar inscripcion - el bool llega sin cambios', () async {
      final inscrito = RespuestaModelo(codigoHttp: 200, datos: true);
      conexion.respuestaValidar = inscrito;

      final respuesta = await repositorio.validarInscripcion(inscripcion());

      expect(conexion.ultimaValidada?.alumnoId, 'alu1');
      expect(respuesta, same(inscrito));
      expect(respuesta.datos, isTrue);
    });

    test('$capa - $tipo - Eliminar inscripcion - envia el modelo armado', () async {
      conexion.respuestaEliminar = RespuestaModelo(codigoHttp: 200);

      final respuesta = await repositorio.eliminarInscripcion(inscripcion());

      expect(conexion.llamadasEliminar, 1);
      expect(conexion.ultimaEliminada?.alumnoId, 'alu1');
      expect(conexion.ultimaEliminada?.iterable, 1);
      expect(respuesta.codigoHttp, 200);
    });
  });
}
