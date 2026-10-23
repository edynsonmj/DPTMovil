import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexiongruposFalsa.dart';
import '../../dobles/conexioninscripcionFalsa.dart';

//vms de las pantallas Grupos asignados y Grupos de inscripcion, con su
//servicio por constructor desde la fase 6 y los dobles en lugar de la
//conexion remota. Solo rutas criticas
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  Inscripcionentidad inscripcion() => Inscripcionentidad(
    alumnoId: 'alu1',
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
  );

  group('Inscripcion (vm con doble):', () {
    late ConexioninscripcionFalsa conexion;
    late Inscripcionviewmodel vm;

    setUp(() {
      conexion = ConexioninscripcionFalsa();
      vm = Inscripcionviewmodel(
        Servicioinscripcion(Inscripcionrepositorio(conexion: conexion)),
      );
    });

    test('$capa - $tipo - Inscribir - 201 es Exito y notifica', () async {
      conexion.respuestaAgregar = RespuestaModelo(codigoHttp: 201);
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Exito>());
      expect(conexion.ultimaAgregada?.alumnoId, 'alu1');
      //la tarjeta se entera y vuelve a validar para cambiar el boton
      expect(notificaciones, 1);
    });

    test('$capa - $tipo - Inscribir - error del backend es Fallo con su mensaje', () async {
      conexion.respuestaAgregar = RespuestaModelo(
        codigoHttp: 400,
        error: ErrorModelo(
          codigoHttp: 400,
          mensaje: 'el grupo no tiene cupos',
          url: '/inscripcion',
          metodo: 'POST',
        ),
      );
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect(resultado.mensaje, 'el grupo no tiene cupos');
      expect(notificaciones, 0);
    });

    test('$capa - $tipo - Desvincular - 200 es Exito', () async {
      conexion.respuestaEliminar = RespuestaModelo(codigoHttp: 200);

      final resultado = await vm.desvincularInscripcion(inscripcion());

      expect(resultado, isA<Exito>());
      expect(conexion.ultimaEliminada?.alumnoId, 'alu1');
    });

    test('$capa - $tipo - Validar - un error cuenta como no inscrito', () async {
      conexion.respuestaValidar = RespuestaModelo(codigoHttp: 500);

      expect(await vm.validarInscripcion(inscripcion()), isFalse);
    });
  });

  group('Grupos del instructor (vm con doble):', () {
    test('$capa - $tipo - Listar grupos del instructor - 200 carga la lista', () async {
      final conexion = ConexiongruposFalsa()
        ..respuestaInstructor = RespuestaModelo(
          codigoHttp: 200,
          datos: [
            GrupoModelo(
              cat_titulo: 'Deportes',
              cur_nombre: 'Iniciacion',
              anio: 2026,
              iterable: 1,
              cupos: 20,
              fechaCreacion: '2026-10-23',
              idInstructor: 'ins1',
            ),
          ],
        );
      final vm = Gruposviewmodel(
        Serviciogrupo(Gruporepositorio(conexion: conexion)),
      );

      await vm.listarGruposInstructor('ins1');

      expect(conexion.ultimoInstructor, 'ins1');
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.getListaGrupos!.single.curso, 'Iniciacion');
    });
  });
}
