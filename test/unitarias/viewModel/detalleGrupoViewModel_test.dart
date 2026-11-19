import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCursoFalsa.dart';
import '../../dobles/conexionalumnosFalsa.dart';
import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';

//el vm de la pantalla de grupo (fase 4c) con sus cuatro servicios armados
//sobre dobles: se prueba la carga de cada seccion sin backend ni widgets
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionCursoFalsa conexionCurso;
  late ConexionhorariosFalsa conexionHorarios;
  late ConexionalumnosFalsa conexionAlumnos;
  late ConexionclasesFalsa conexionClases;
  late DetalleGrupoViewModel vm;

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    idInstructor: 'ins1',
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );

  Clasemodelo clase(int codigo) => Clasemodelo(
    codigo: codigo,
    idGrupoCategoria: 'Deportes',
    idGrupoCurso: 'Iniciacion',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'ins1',
    fecha: DateTime(2026, 10, 22),
    horas: 2,
    minutos: 0,
    eliminado: 0,
  );

  //respuestas de un grupo con datos en las cuatro secciones
  void responderConDatos() {
    conexionCurso.respuestaObtener = RespuestaModelo(
      codigoHttp: 200,
      datos: CursoModelo(
        nombreCurso: 'Iniciacion',
        nombreDeporte: 'Futbol',
        tituloCategoria: 'Deportes',
        descripcion: 'Desc',
      ),
    );
    conexionHorarios.respuestaHorarios = RespuestaModelo(
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
    conexionAlumnos.respuestaAlumnos = RespuestaModelo(
      codigoHttp: 200,
      datos: [
        Alumnomodelo(
          id: 'alu1',
          tipo: 'Estudiante',
          nombre: 'Ana',
          correo: 'ana@x.co',
          sexo: 'F',
          tipoid: 'CC',
        ),
      ],
    );
    conexionClases.respuestaClases = RespuestaModelo(
      codigoHttp: 200,
      datos: [clase(9)],
    );
  }

  //un doble nuevo por caso, misma cadena que la raiz y la ruta grupo
  setUp(() {
    conexionCurso = ConexionCursoFalsa();
    conexionHorarios = ConexionhorariosFalsa();
    conexionAlumnos = ConexionalumnosFalsa();
    conexionClases = ConexionclasesFalsa();
    vm = DetalleGrupoViewModel(
      grupo,
      ServicioCurso(CursoRepositorio(cliente: conexionCurso)),
      Serviciohorario(Horariorepositorio(conexion: conexionHorarios)),
      Servicioalumno(Alumnosrepositorio(cliente: conexionAlumnos)),
      Servicioclase(Claserepositorio(cliente: conexionClases)),
    );
  });

  group('Detalle de grupo (vm con dobles):', () {
    test('$capa - $tipo - Cargar grupo - 200 llena las cuatro secciones', () async {
      responderConDatos();

      await vm.cargar();

      //cada peticion va al grupo de la pantalla
      expect(conexionCurso.ultimaCategoria, 'Deportes');
      expect(conexionCurso.ultimoCurso, 'Iniciacion');
      expect(conexionHorarios.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(conexionAlumnos.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(conexionClases.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(vm.curso.datos?.nombreDeporte, 'Futbol');
      expect(vm.horarios.datos.single.dia, 'Lunes');
      expect(vm.alumnos.datos.single.nombre, 'Ana');
      expect(vm.clases.datos.single.codigo, 9);
      for (final seccion in [vm.curso, vm.horarios, vm.alumnos, vm.clases]) {
        expect(seccion.cargando, isFalse);
        expect(seccion.error, isNull);
      }
    });

    test('$capa - $tipo - Cargar grupo - todo cargando mientras llega', () async {
      responderConDatos();

      final carga = vm.cargar();
      //antes de la primera respuesta la pantalla muestra los spinners
      for (final seccion in [vm.curso, vm.horarios, vm.alumnos, vm.clases]) {
        expect(seccion.cargando, isTrue);
      }
      await carga;
      expect(vm.clases.cargando, isFalse);
    });

    test('$capa - $tipo - Cargar grupo - 406 de alumnos y clases es lista vacia', () async {
      responderConDatos();
      //lo que devuelve la conexion cuando el backend manda GC-0002
      conexionAlumnos.respuestaAlumnos = RespuestaModelo(codigoHttp: 406);
      conexionClases.respuestaClases = RespuestaModelo(codigoHttp: 406);

      await vm.cargar();

      expect(vm.alumnos.datos, isEmpty);
      expect(vm.alumnos.error, isNull);
      expect(vm.clases.datos, isEmpty);
      expect(vm.clases.error, isNull);
    });

    test('$capa - $tipo - Cargar grupo - un error solo afecta su seccion', () async {
      responderConDatos();
      conexionHorarios.respuestaHorarios = RespuestaModelo(codigoHttp: 500);

      await vm.cargar();

      expect(vm.horarios.error, contains('500'));
      expect(vm.horarios.datos, isEmpty);
      //las demas secciones se pintan igual
      expect(vm.curso.error, isNull);
      expect(vm.alumnos.error, isNull);
      expect(vm.clases.datos, hasLength(1));
    });

    test('$capa - $tipo - Eliminar clase - 200 recarga la lista', () async {
      conexionClases.respuestaEliminar = RespuestaModelo(codigoHttp: 200);
      conexionClases.respuestaClases = RespuestaModelo(codigoHttp: 406);

      final resultado = await vm.eliminarClase(9);

      expect(resultado, isA<Exito>());
      expect(conexionClases.ultimoIdEliminado, 9);
      expect(conexionClases.llamadasClases, 1);
      expect(vm.clases.datos, isEmpty);
    });

    test('$capa - $tipo - Eliminar clase - fallo no recarga', () async {
      conexionClases.respuestaEliminar = RespuestaModelo(codigoHttp: 400);

      final resultado = await vm.eliminarClase(9);

      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect(conexionClases.llamadasClases, 0);
    });

    test('$capa - $tipo - Agregar horario - 201 envia el grupo de la pantalla y recarga', () async {
      final resultado = await vm.agregarHorario(
        dia: 'Lunes',
        horaInicio: '08:00',
        horaFin: '10:00',
        escenario: ' Coliseo ',
      );

      expect(resultado, isA<Exito>());
      final enviado = conexionHorarios.ultimoAgregado!;
      expect([enviado.categoria, enviado.curso, enviado.anio, enviado.iterable],
          ['Deportes', 'Iniciacion', 2026, 1]);
      //el dia sale como lo nombra el backend (HO-06)
      expect([enviado.dia, enviado.horaInicio, enviado.horaFin, enviado.escenario],
          ['LUNES', '08:00', '10:00', 'Coliseo']);
      expect(conexionHorarios.llamadasHorarios, 1);
    });

    //HO-06: el backend compara el dia con equalsIgnoreCase contra MIERCOLES y
    //SABADO; con tilde el horario no contaba
    test('$capa - $tipo - Agregar horario - los dias con tilde salen sin tilde y en mayusculas', () async {
      for (final (dia, esperado) in [('Miércoles', 'MIERCOLES'), ('sábado', 'SABADO'), (' Domingo ', 'DOMINGO')]) {
        final resultado = await vm.agregarHorario(dia: dia, horaInicio: '08:00', horaFin: '10:00', escenario: 'X');
        expect(resultado, isA<Exito>());
        expect(conexionHorarios.ultimoAgregado!.dia, esperado);
      }
    });

    test('$capa - $tipo - Agregar horario - un dia que no existe no se envia', () async {
      final resultado = await vm.agregarHorario(dia: 'Xyz', horaInicio: '08:00', horaFin: '10:00', escenario: 'X');

      expect((resultado as Fallo).mensaje, 'El dia "Xyz" no es valido');
      expect(conexionHorarios.llamadasAgregar, 0);
    });

    test('$capa - $tipo - Agregar horario - reglas del cliente: no envia nada', () async {
      final casos = <Future<Resultado<void>>>[
        vm.agregarHorario(dia: null, horaInicio: '08:00', horaFin: '10:00', escenario: 'X'),
        vm.agregarHorario(dia: 'Lunes', horaInicio: null, horaFin: '10:00', escenario: 'X'),
        vm.agregarHorario(dia: 'Lunes', horaInicio: '10:00', horaFin: '10:00', escenario: 'X'),
        vm.agregarHorario(dia: 'Lunes', horaInicio: '08:00', horaFin: '10:00', escenario: '  '),
      ];
      for (final resultado in await Future.wait(casos)) {
        expect(resultado, isA<Fallo>());
      }
      expect(conexionHorarios.llamadasAgregar, 0);
    });

    test('$capa - $tipo - Agregar horario - 404 devuelve Fallo y no recarga', () async {
      conexionHorarios.respuestaAgregar = RespuestaModelo(codigoHttp: 404);

      final resultado = await vm.agregarHorario(
        dia: 'Lunes',
        horaInicio: '08:00',
        horaFin: '10:00',
        escenario: 'Coliseo',
      );

      expect((resultado as Fallo).codigo, 404);
      expect(conexionHorarios.llamadasHorarios, 0);
    });

    test('$capa - $tipo - Eliminar horario - 200 elimina por id y recarga', () async {
      final resultado = await vm.eliminarHorario(15);

      expect(resultado, isA<Exito>());
      expect(conexionHorarios.ultimoEliminado, 15);
      expect(conexionHorarios.llamadasHorarios, 1);
    });

    test('$capa - $tipo - Eliminar horario - 404 devuelve Fallo y no recarga', () async {
      conexionHorarios.respuestaEliminar = RespuestaModelo(codigoHttp: 404);

      final resultado = await vm.eliminarHorario(15);

      expect((resultado as Fallo).codigo, 404);
      expect(conexionHorarios.llamadasHorarios, 0);
    });
  });
}
