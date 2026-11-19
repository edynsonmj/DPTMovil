import 'package:dpt_movil/data/mappers/atencionMapper.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionatencionesFalsa.dart';

//errores del repositorio y del vm de la toma de asistencia (AS-07, AS-08)
void main() {
  const String tipo = "unitaria";

  late ConexionatencionesFalsa conexion;
  late Atencionesrepositorio repositorio;
  late Atencionviewmodel vm;

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );
  final clase = Claseentidad(
    codigo: 210,
    idGrupoCategoria: 'Deportes',
    idGrupoCurso: 'Iniciacion',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'ins1',
    eliminado: 0,
  );

  setUp(() {
    conexion = ConexionatencionesFalsa();
    repositorio = Atencionesrepositorio(conexion: conexion);
    vm = Atencionviewmodel(Servicioatencion(repositorio));
  });

  group('Atenciones (errores de repositorio y vm):', () {
    for (final codigo in [201, 204]) {
      test('viewModel - $tipo - Registrar atenciones - $codigo es Exito', () async {
        conexion.respuestaRegistrar = RespuestaModelo(codigoHttp: codigo);
        await vm.cargarAtenciones(grupo, clase);

        final resultado = await vm.registrarAtenciones();

        //la asistencia se guardo: mostrar error invita a reintentar y duplicar
        expect(resultado, isA<Exito>(), reason: '$resultado');
      });
    }

    test('repositorio - $tipo - Registrar atenciones - una atencion de otra clase se rechaza antes de la red', () async {
      final atenciones =
          atencionesDelContrato('listar_200')
              .map(AtencionMapper.aEntidad)
              .toList();
      atenciones[1].idClase = 999;

      final respuesta = await repositorio.registrarAtencionesClase(
        atenciones,
        210,
      );

      expect(conexion.llamadasRegistrar, 0);
      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
