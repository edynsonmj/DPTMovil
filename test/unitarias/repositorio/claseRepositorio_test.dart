import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionclasesFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 4
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionclasesFalsa conexion;
  late Claserepositorio repositorio;

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexionclasesFalsa();
    repositorio = Claserepositorio(cliente: conexion);
  });

  group('Clases (repositorio con doble):', () {
    test('$capa - $tipo - Listar clases de grupo - 200 convierte a entidades', () async {
      conexion.respuestaClases = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Clasemodelo(
            codigo: 5,
            idGrupoCategoria: 'Deportes',
            idGrupoCurso: 'Iniciacion',
            idGrupoAnio: 2026,
            idGrupoIterable: 1,
            idInstructor: 'ins1',
            fecha: DateTime(2026, 10, 20),
            horas: 2,
            minutos: 0,
            eliminado: 0,
          ),
        ],
      );

      final respuesta = await repositorio.listarClaseGrupo(
        'Deportes',
        'Iniciacion',
        2026,
        1,
      );

      expect(conexion.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Claseentidad>>());
      final clase = (respuesta.datos as List<Claseentidad>).single;
      //el codigo es el que usa eliminarClase
      expect(clase.codigo, 5);
      expect(clase.fecha, DateTime(2026, 10, 20));
      expect(clase.horas, 2);
    });

    test('$capa - $tipo - Agregar clase - envia el modelo armado', () async {
      conexion.respuestaAgregar = RespuestaModelo(codigoHttp: 201);

      final respuesta = await repositorio.agregarClase(
        Claseentidad(
          idGrupoCategoria: 'Deportes',
          idGrupoCurso: 'Iniciacion',
          idGrupoAnio: 2026,
          idGrupoIterable: 1,
          idInstructor: 'ins1',
          fecha: DateTime(2026, 10, 20),
          horas: 2,
          minutos: 0,
          eliminado: 0,
        ),
      );

      expect(conexion.llamadasAgregar, 1);
      final enviada = conexion.ultimaAgregada!;
      expect(enviada.idGrupoCategoria, 'Deportes');
      expect(enviada.idGrupoIterable, 1);
      expect(enviada.idInstructor, 'ins1');
      expect(enviada.fecha, DateTime(2026, 10, 20));
      expect(enviada.horas, 2);
      expect(respuesta.codigoHttp, 201);
    });
  });
}
