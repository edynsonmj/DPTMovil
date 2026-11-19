import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionalumnosFalsa.dart';

//Alumnosviewmodel no tiene consumidores hoy y se conserva para uso futuro
//(PR-003.2b). Misma cadena que la raiz, con el doble de la conexion abajo
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionalumnosFalsa conexion;
  late Alumnosviewmodel vm;

  setUp(() {
    conexion = ConexionalumnosFalsa();
    vm = Alumnosviewmodel(
      Servicioalumno(Alumnosrepositorio(cliente: conexion)),
    );
  });

  group('Alumnos (vm → servicio → repositorio → doble):', () {
    test('$capa - $tipo - Listar alumnos de grupo - 200 devuelve las entidades del grupo pedido', () async {
      conexion.respuestaAlumnos = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Alumnomodelo(
            id: '104619011001',
            codigo: '104619011001',
            tipo: 'Estudiante',
            nombre: 'Ana Ruiz',
            correo: 'ana@unicauca.edu.co',
            sexo: 'F',
            tipoid: 'CC',
          ),
        ],
      );

      final respuesta = await vm.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(respuesta.codigoHttp, 200);
      final alumnos = respuesta.datos as List<Alumnoentidad>;
      expect(alumnos.single.nombre, 'Ana Ruiz');
      expect(conexion.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
    });

    test('$capa - $tipo - Listar alumnos de grupo - un error llega sin cambios', () async {
      final e503 = RespuestaModelo(
        codigoHttp: 503,
        error: ErrorModelo(codigoHttp: 503, mensaje: 'sin red', url: '/alumnosGrupo', metodo: 'GET'),
      );
      conexion.respuestaAlumnos = e503;

      final respuesta = await vm.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(respuesta, same(e503));
    });

    test('$capa - $tipo - Listar alumnos de grupo - un TypeError de la conexion llega como error, sin lanzar', () async {
      conexion.lanzar = TypeError();

      final respuesta = await vm.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
