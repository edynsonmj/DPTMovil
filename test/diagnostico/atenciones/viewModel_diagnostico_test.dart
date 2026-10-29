@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionatencionesFalsa.dart';

//pruebas de diagnostico (fase 4) del repositorio y del vm de la toma de
//asistencia: afirman el comportamiento CORRECTO y se espera que salgan
//rojas mientras el bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String tipo = "diagnostico";

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

  group('Atenciones (diagnostico de repositorio y vm):', () {
    for (final codigo in [201, 204]) {
      test('viewModel - $tipo - Registrar atenciones - BUG AS-07 - $codigo es Exito', () async {
        conexion.respuestaRegistrar = RespuestaModelo(codigoHttp: codigo);
        await vm.cargarAtenciones(grupo, clase);

        final resultado = await vm.registrarAtenciones();

        //la asistencia se guardo: mostrar error invita a reintentar y duplicar
        expect(resultado, isA<Exito>(), reason: '$resultado');
      });
    }

    test('repositorio - $tipo - Registrar atenciones - BUG AS-08 - una atencion de otra clase se rechaza antes de la red', () async {
      final atenciones =
          atencionesDelContrato('listar_200')
              .map((m) => Atencionentidad.fromModelo(m))
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

    test('viewModel - $tipo - Registrar atenciones - BUG AS-09 - tras un fallo se sabe que hay cambios sin guardar', () async {
      conexion.respuestaRegistrar = RespuestaModelo(
        codigoHttp: 500,
        error: ErrorModelo(
          codigoHttp: 500,
          mensaje: 'fallo interno',
          url: '/atenciones',
          metodo: 'POST',
        ),
      );
      await vm.cargarAtenciones(grupo, clase);
      vm.marcarAsistencia(0, true);

      final resultado = await vm.registrarAtenciones();
      expect(resultado, isA<Fallo>());

      //la marca se ve en pantalla pero no esta guardada: el vm debe poder
      //decirlo. Hoy no existe esa propiedad; se pide por dynamic para que la
      //prueba compile y quede roja con NoSuchMethodError mientras falte
      final dynamic estado = vm;
      expect(estado.hayCambiosSinGuardar, isTrue);
    });
  });
}
