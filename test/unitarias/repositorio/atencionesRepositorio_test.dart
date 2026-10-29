import 'package:dpt_movil/data/models/errorModelo.dart';
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
      //el doble responde la lista del contrato (listar_200.json) por defecto
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
      final lista = respuesta.datos as List<Atencionentidad>;
      expect(lista.map((a) => a.alumno.nombre), [
        'Ana Gomez',
        'Luis Perez',
        'Marta Ruiz',
      ]);
      //el alumno anidado tambien sale como entidad
      expect(lista[0].alumno, isA<Alumnoentidad>());
      expect(lista[0].alumno.id, '1061001');
      expect(lista.every((a) => a.idClase == 210), isTrue);
      expect(lista.map((a) => a.estaAtendido), [false, false, true]);
    });

    test('$capa - $tipo - Registrar atenciones - envia los modelos y la clase', () async {
      conexion.respuestaRegistrar = RespuestaModelo(codigoHttp: 200);

      final respuesta = await repositorio.registrarAtencionesClase([
        Atencionentidad(
          alumno: Alumnoentidad(
            id: 'alu1',
            codigo: '104619011001',
            tipo: 'Estudiante',
            nombre: 'Ana',
            correo: 'ana@x.co',
            sexo: 'F',
            tipoid: 'CC',
            imagen: 12,
          ),
          idClase: 210,
          estaAtendido: true,
        ),
      ], 210);

      expect(conexion.llamadasRegistrar, 1);
      expect(conexion.ultimoIdClaseRegistro, 210);
      final enviada = conexion.ultimasRegistradas!.single;
      //el alumno viaja completo: si el backend guarda el anidado, un campo
      //perdido aqui seria un dato borrado (hipotesis AS-05). eliminadoestado
      //no se puede afirmar en esta capa: Alumnoentidad no lo tiene
      expect(enviada.alumno.id, 'alu1');
      expect(enviada.alumno.codigo, '104619011001');
      expect(enviada.alumno.tipo, 'Estudiante');
      expect(enviada.alumno.nombre, 'Ana');
      expect(enviada.alumno.correo, 'ana@x.co');
      expect(enviada.alumno.sexo, 'F');
      expect(enviada.alumno.tipoid, 'CC');
      expect(enviada.alumno.imagen, 12);
      expect(enviada.idClase, 210);
      expect(enviada.estaAtendido, isTrue);
      expect(respuesta.codigoHttp, 200);
    });

    test('$capa - $tipo - Listar atenciones de clase - error pasa sin cambios', () async {
      final error = RespuestaModelo(
        codigoHttp: 404,
        error: ErrorModelo(
          codigoHttp: 404,
          mensaje: 'no existe la clase',
          url: '/atencionesporclase',
          metodo: 'GET',
        ),
      );
      conexion.respuestaAtenciones = error;

      final respuesta = await repositorio.listarAtencionesClase(
        'Deportes',
        'Iniciacion',
        2026,
        1,
        210,
      );

      expect(respuesta, same(error));
    });

    test('$capa - $tipo - Registrar atenciones - error pasa sin cambios', () async {
      final error = RespuestaModelo(
        codigoHttp: 500,
        error: ErrorModelo(
          codigoHttp: 500,
          mensaje: 'fallo interno',
          url: '/atenciones',
          metodo: 'POST',
        ),
      );
      conexion.respuestaRegistrar = error;

      final respuesta = await repositorio.registrarAtencionesClase(
        atencionesDelContrato('listar_200')
            .map((m) => Atencionentidad.fromModelo(m))
            .toList(),
        210,
      );

      expect(respuesta, same(error));
    });
  });
}
