import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexiongruposFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/conexioninscripcionFalsa.dart';

//vms de las pantallas Grupos asignados y Grupos de inscripcion, con su
//servicio por constructor desde la fase 6 y los dobles en lugar de la
//conexion remota. Solo rutas criticas
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  //el grupo de la tarjeta y la inscripcion del alumno en ese grupo
  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );

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

    //fase 6c: antes se contaba una sola notificacion; ahora el vm tambien
    //notifica al entrar y salir de "procesando" (J4), asi que se comprueba
    //el estado del grupo, que es lo que pinta la tarjeta
    test('$capa - $tipo - Inscribir - 201 es Exito y revalida solo ese grupo', () async {
      conexion.respuestaAgregar = RespuestaModelo(codigoHttp: 201);
      conexion.respuestaValidar = RespuestaModelo(codigoHttp: 200, datos: true);

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Exito>());
      expect(conexion.ultimaAgregada?.alumnoId, 'alu1');
      //J3: el backend dice si quedo inscrito, con una sola validacion
      expect(conexion.llamadasValidar, 1);
      expect(vm.estadoDe(grupo).datos, isTrue);
      expect(vm.procesando(grupo), isFalse);
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

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect(resultado.mensaje, 'el grupo no tiene cupos');
      //un fallo no revalida ni deja el boton deshabilitado
      expect(conexion.llamadasValidar, 0);
      expect(vm.procesando(grupo), isFalse);
    });

    test('$capa - $tipo - Inscribir - el grupo queda procesando mientras tanto', () async {
      final operacion = vm.agregarIncripcion(inscripcion());

      //J4: el boton de ese grupo se deshabilita hasta que termine
      expect(vm.procesando(grupo), isTrue);
      await operacion;
      expect(vm.procesando(grupo), isFalse);
    });

    test('$capa - $tipo - Cargar estados - una validacion por grupo', () async {
      conexion.respuestaValidar = RespuestaModelo(codigoHttp: 200, datos: true);
      final otro = Grupoentidad(
        categoria: 'Deportes',
        curso: 'Iniciacion',
        anio: 2026,
        iterable: 2,
        cupos: 20,
        fechaCreacion: '2026-10-23',
      );

      //antes de cargar, la tarjeta se pinta cargando
      expect(vm.estadoDe(grupo).cargando, isTrue);
      await vm.cargarEstados('alu1', [grupo, otro]);

      expect(conexion.llamadasValidar, 2);
      expect(conexion.iterablesValidados, unorderedEquals([1, 2]));
      expect(vm.estadoDe(grupo).datos, isTrue);
      expect(vm.estadoDe(otro).cargando, isFalse);
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

  group('Horarios por grupo (vm con doble, fase 6c):', () {
    late ConexionhorariosFalsa conexion;
    late Horariosviewmodel vm;
    final otro = Grupoentidad(
      categoria: 'Deportes',
      curso: 'Iniciacion',
      anio: 2026,
      iterable: 2,
      cupos: 20,
      fechaCreacion: '2026-10-23',
    );

    setUp(() {
      conexion = ConexionhorariosFalsa()
        ..respuestaHorarios = RespuestaModelo(
          codigoHttp: 200,
          datos: [
            HorarioModelo(
              categoria: 'Deportes',
              curso: 'Iniciacion',
              anio: 2026,
              iterable: 1,
              dia: 'Lunes',
              horaInicio: '08:00',
              horaFin: '10:00',
              escenario: 'Coliseo',
            ),
          ],
        );
      vm = Horariosviewmodel(
        Serviciohorario(Horariorepositorio(conexion: conexion)),
      );
    });

    test('$capa - $tipo - Cargar horarios de - una peticion por grupo', () async {
      //antes de cargar, la tarjeta se pinta cargando
      expect(vm.horariosDe(grupo).cargando, isTrue);

      await vm.cargarHorariosDe([grupo, otro]);

      expect(conexion.llamadasHorarios, 2);
      expect(
        conexion.gruposPedidos,
        unorderedEquals([grupo.clave, otro.clave]),
      );
      for (final g in [grupo, otro]) {
        expect(vm.horariosDe(g).cargando, isFalse);
        expect(vm.horariosDe(g).datos.single.dia, 'Lunes');
      }
    });

    test('$capa - $tipo - Cargar horarios de - un error queda en su grupo', () async {
      conexion.respuestaHorarios = RespuestaModelo(codigoHttp: 500);

      await vm.cargarHorariosDe([grupo]);

      //I3: la tarjeta se pinta sin horarios, no revienta
      expect(vm.horariosDe(grupo).cargando, isFalse);
      expect(vm.horariosDe(grupo).error, contains('500'));
      expect(vm.horariosDe(grupo).datos, isEmpty);
      //otro grupo no se toco: sigue esperando su carga
      expect(vm.horariosDe(otro).cargando, isTrue);
    });
  });
}
