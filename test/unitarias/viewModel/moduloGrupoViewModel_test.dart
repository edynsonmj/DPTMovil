import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexiongruposFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/conexioninstructoresFalsa.dart';

//los vms del modulo grupo reciben su servicio por constructor desde la fase
//4: se arma la misma cadena que la raiz, con el doble en lugar de la conexion
//remota. Solo rutas criticas; los casos contra el backend siguen en test/remoto
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  group('Modulo grupo (vms con doble):', () {
    test('$capa - $tipo - Listar instructores - 200 carga la lista', () async {
      final conexion = ConexioninstructoresFalsa();
      conexion.respuestaInstructores = RespuestaModelo(
        codigoHttp: 200,
        datos: [Instructormodelo(id: 'ins1', nombre: 'Luis')],
      );
      final vm = InstructoresViewModel(
        ServicioInstructor(Instructoresrepositorio(conexion: conexion)),
      );

      await vm.listarYNotificarInstructores();

      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.instructores.map((i) => i.id), ['ins1']);
    });

    test('$capa - $tipo - Insertar grupo - 201 sin recargar la lista', () async {
      final conexion = ConexiongruposFalsa();
      conexion.respuestaInsertar = RespuestaModelo(codigoHttp: 201);
      final vm = Gruposviewmodel(
        Serviciogrupo(Gruporepositorio(conexion: conexion)),
      );

      final respuesta = await vm.insertarGrupo(
        Grupoentidad(
          categoria: 'Deportes',
          curso: 'Iniciacion',
          anio: 2026,
          iterable: 0,
          idInstructor: 'ins1',
          cupos: 20,
          fechaCreacion: '2026-10-23',
        ),
      );

      expect(respuesta.codigoHttp, 201);
      expect(conexion.ultimoInsertado?.idInstructor, 'ins1');
      //el formulario tiene su propio vm: la lista la recarga la pantalla
      //del curso al volver, no este insert
      expect(conexion.llamadasGruposDe, 0);
    });

    //reglas del formulario de alta, que antes vivian en GrupoFormulario
    group('Registrar grupo:', () {
      late ConexiongruposFalsa conexion;
      late Gruposviewmodel vm;
      final curso = CursoEntidad(
        nombreCurso: 'Iniciacion',
        nombreDeporte: 'Futbol',
        tituloCategoria: 'Deportes',
        descripcion: 'x',
        imagen: 7,
      );
      //fecha fija: el anio y la fecha de creacion salen de aqui
      final hoy = DateTime(2026, 3, 9);

      setUp(() {
        conexion = ConexiongruposFalsa();
        vm = Gruposviewmodel(Serviciogrupo(Gruporepositorio(conexion: conexion)));
      });

      test('$capa - $tipo - Registrar grupo - 201 arma el grupo del curso con la fecha dada', () async {
        final resultado = await vm.registrarGrupo(
          curso: curso,
          cupos: ' 25 ',
          idInstructor: 'ins1',
          aperturaInscripcion: DateTime(2026, 3, 10),
          cierreInscripcion: DateTime(2026, 3, 20),
          hoy: hoy,
        );

        expect(resultado, isA<Exito<Grupoentidad>>());
        final enviado = conexion.ultimoInsertado!;
        expect(
          (enviado.cat_titulo, enviado.cur_nombre, enviado.cupos, enviado.idInstructor, enviado.anio, enviado.fechaCreacion),
          ('Deportes', 'Iniciacion', 25, 'ins1', 2026, '2026-03-09'),
        );
        expect(enviado.fechaInscripcionApertura, '2026-03-10');
        expect(enviado.fechaInscripcionCierre, '2026-03-20');
      });

      test('$capa - $tipo - Registrar grupo - la apertura es opcional', () async {
        await vm.registrarGrupo(
          curso: curso,
          cupos: '25',
          idInstructor: 'ins1',
          cierreInscripcion: DateTime(2026, 3, 20),
          hoy: hoy,
        );

        expect(conexion.ultimoInsertado!.fechaInscripcionApertura, isNull);
        expect(conexion.ultimoInsertado!.fechaInscripcionCierre, '2026-03-20');
      });

      test('$capa - $tipo - Registrar grupo - sin cierre o con el cierre antes de la apertura no envia nada', () async {
        final sinCierre = await vm.registrarGrupo(
          curso: curso,
          cupos: '25',
          idInstructor: 'ins1',
          hoy: hoy,
        );
        final alReves = await vm.registrarGrupo(
          curso: curso,
          cupos: '25',
          idInstructor: 'ins1',
          aperturaInscripcion: DateTime(2026, 3, 20),
          cierreInscripcion: DateTime(2026, 3, 10),
          hoy: hoy,
        );

        expect(
          [sinCierre, alReves].map((r) => (r as Fallo).mensaje),
          [
            'Seleccione la fecha de cierre de inscripciones',
            'La fecha de cierre no puede ser anterior a la de apertura',
          ],
        );
        expect(conexion.llamadasInsertar, 0);
      });

      test('$capa - $tipo - Registrar grupo - sin instructor o con cupos que no son un int no envia nada', () async {
        final sinInstructor = await vm.registrarGrupo(curso: curso, cupos: '25', hoy: hoy);
        final cuposEnormes = await vm.registrarGrupo(
          curso: curso,
          cupos: '99999999999999999999999',
          idInstructor: 'ins1',
          hoy: hoy,
        );

        expect(
          [sinInstructor, cuposEnormes].map((r) => (r as Fallo).mensaje),
          ['Seleccione un instructor', 'Los cupos deben ser un numero valido'],
        );
        expect(conexion.llamadasInsertar, 0);
      });

      test('$capa - $tipo - Registrar grupo - un error del backend vuelve como Fallo con su codigo', () async {
        conexion.respuestaInsertar = RespuestaModelo(
          codigoHttp: 400,
          error: ErrorModelo(codigoHttp: 400, mensaje: 'cupos', url: '/grupo', metodo: 'POST'),
        );

        final resultado = await vm.registrarGrupo(
          curso: curso,
          cupos: '25',
          idInstructor: 'ins1',
          cierreInscripcion: DateTime(2026, 3, 20),
          hoy: hoy,
        );

        expect(
          resultado,
          isA<Fallo<Grupoentidad>>()
              .having((f) => f.codigo, 'codigo', 400)
              .having((f) => f.mensaje, 'mensaje', 'cupos'),
        );
      });
    });

    test('$capa - $tipo - Url de imagen de grupo - la arma la conexion', () {
      final vm = Gruposviewmodel(
        Serviciogrupo(Gruporepositorio(conexion: ConexiongruposFalsa())),
      );

      //la vista ya no conoce el servidor: la url baja desde la conexion
      expect(vm.urlImagen(5), 'http://falso/imagenStream?idImagen=5');
    });

    test('$capa - $tipo - Registrar clase - 201 con el grupo inicializado', () async {
      final conexion = ConexionclasesFalsa();
      conexion.respuestaAgregar = RespuestaModelo(codigoHttp: 201);
      final vm = Clasesviewmodel(
        Servicioclase(Claserepositorio(cliente: conexion)),
        Serviciohorario(Horariorepositorio(conexion: ConexionhorariosFalsa())),
      );
      //como lo hace la ruta formularioClase con el grupo que recibe
      vm.inicializarGrupo('Deportes', 'Iniciacion', 2026, 1, 'ins1');

      final resultado = await vm.registrarClase(
        fecha: DateTime(2026, 10, 22),
        horasTexto: '2',
      );

      expect(resultado, isA<Exito>());
      //la clase se arma con el grupo inicializado
      expect(conexion.ultimaAgregada?.idGrupoIterable, 1);
      expect(conexion.ultimaAgregada?.idInstructor, 'ins1');
      //fase 4c: el formulario ya no recarga la lista; lo hace la pantalla
      //del grupo al volver con true
      expect(conexion.llamadasClases, 0);
    });
  });
}
