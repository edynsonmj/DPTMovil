import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionatencionesFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 5
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionatencionesFalsa conexion;
  late Atencionesrepositorio repositorio;

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexionatencionesFalsa();
    repositorio = Atencionesrepositorio(conexion: conexion);
  });

  group('Atenciones (repositorio con doble):', () {
    test('$capa - $tipo - Listar atenciones de clase - 200 convierte a entidades', () async {
      conexion.respuestaAtenciones = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Atencionmodelo(
            alumno: Alumnomodelo(
              id: 'alu1',
              tipo: 'Estudiante',
              nombre: 'Ana',
              correo: 'ana@x.co',
              sexo: 'F',
              tipoid: 'CC',
            ),
            idClase: 210,
            estaAtendido: true,
          ),
        ],
      );

      final respuesta = await repositorio.listarAtencionesClase(
        'Deportes',
        'Iniciacion',
        2026,
        1,
        210,
      );

      expect(conexion.ultimaClase, 'Deportes/Iniciacion/2026/1/210');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Atencionentidad>>());
      final atencion = (respuesta.datos as List<Atencionentidad>).single;
      //el alumno anidado tambien sale como entidad
      expect(atencion.alumno, isA<Alumnoentidad>());
      expect(atencion.alumno.nombre, 'Ana');
      expect(atencion.idClase, 210);
      expect(atencion.estaAtendido, isTrue);
    });

    test('$capa - $tipo - Registrar atenciones - envia los modelos y la clase', () async {
      conexion.respuestaRegistrar = RespuestaModelo(codigoHttp: 200);

      final respuesta = await repositorio.registrarAtencionesClase([
        Atencionentidad(
          alumno: Alumnoentidad(
            id: 'alu1',
            tipo: 'Estudiante',
            nombre: 'Ana',
            correo: 'ana@x.co',
            sexo: 'F',
            tipoid: 'CC',
          ),
          idClase: 210,
          estaAtendido: true,
        ),
      ], 210);

      expect(conexion.llamadasRegistrar, 1);
      expect(conexion.ultimoIdClaseRegistro, 210);
      final enviada = conexion.ultimasRegistradas!.single;
      expect(enviada.alumno.id, 'alu1');
      expect(enviada.alumno.correo, 'ana@x.co');
      expect(enviada.estaAtendido, isTrue);
      expect(respuesta.codigoHttp, 200);
    });
  });
}
