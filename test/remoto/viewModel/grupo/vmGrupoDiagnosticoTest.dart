import 'dart:io';

import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

//diagnostico del modulo 3 contra el backend real (plan-diagnostico-
//grupos.md): Gruposviewmodel y DetalleGrupoViewModel con su cadena real. El
//setUpAll crea por corrida:
//- categoria N "prueba_X" con el curso A (un grupo G de 20 cupos, alumnos
//  A y B inscritos y B desvinculado) y el curso B, sin grupos;
//- categoria E "prueba_X Fútbol & Voleibol" con el curso "curso & co X",
//  un grupo GE con una clase de ayer y el alumno A inscrito.
//Los casos dependen del orden: los que insertan grupos van al final
class VmGrupoDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late String _marca;
  late String _idInstructor;
  late String _alumnoA;
  late String _alumnoB;
  late CursoEntidad _cursoA;
  late CursoEntidad _cursoB;
  late CursoEntidad _cursoE;
  Grupoentidad? _grupo;
  Grupoentidad? _grupoE;

  void preparar({
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
    required InstructoresViewModel Function() crearVmInstructores,
    required Gruposviewmodel Function() crearVmGrupos,
    required Facultadesviewmodel Function() crearVmFacultades,
    required PeriodoInscripcionViewModel Function() crearVmPeriodo,
    required Inscripcionviewmodel Function() crearVmInscripcion,
    required Clasesviewmodel Function() crearVmClase,
    required Servicioautenticacion servicioAutenticacion,
  }) {
    setUpAll(() async {
      _marca = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');
      final deporte =
          ((await crearVmDeporte().obtenerDeportes()).datos as List<String>).first;

      Future<void> categoria(String titulo) async {
        final r = await vmCategoria.insertarCategoria(
          CategoriaEntidad(
            titulo: titulo,
            descripcion: 'categoria para el diagnostico de grupos',
            imagenFile: _imagenPrueba(),
          ),
        );
        expect(r, isA<Exito>(), reason: 'no se creo la categoria $titulo');
      }

      Future<CursoEntidad> curso(String categoria, String nombre) async {
        final r = await crearVmCurso().agregarCurso(
          CursoEntidad(
            nombreCurso: nombre,
            nombreDeporte: deporte,
            tituloCategoria: categoria,
            descripcion: 'curso para el diagnostico de grupos',
            imagenFile: _imagenPrueba(),
          ),
        );
        expect(r.codigoHttp, 201, reason: 'no se creo el curso $nombre');
        return r.datos as CursoEntidad;
      }

      final vmInstructores = crearVmInstructores();
      await vmInstructores.listarYNotificarInstructores();
      _idInstructor = vmInstructores.instructores.first.id;

      Future<Grupoentidad> grupo(CursoEntidad c) async {
        final r = await crearVmGrupos().insertarGrupo(_nuevoGrupo(c));
        expect(r.codigoHttp, 201, reason: 'no se creo el grupo de ${c.nombreCurso}');
        //se busca con la lista de gruposNoEliminados, que codifica bien, para
        //no depender de /gruposCurso (que es lo que se prueba)
        final vm = crearVmPeriodo();
        await vm.cargar();
        final g = vm.grupos.datos.firstWhere(
          (x) => x.categoria == c.tituloCategoria && x.curso == c.nombreCurso,
        );
        expect(await crearVmPeriodo().abrir(g), isA<Exito>());
        return g;
      }

      final n = 'prueba_$_marca';
      final e = 'prueba_$_marca Fútbol & Voleibol';
      await categoria(n);
      await categoria(e);
      _cursoA = await curso(n, 'curso_$_marca');
      _cursoB = await curso(n, 'cursoB_$_marca');
      _cursoE = await curso(e, 'curso & co $_marca');
      _grupo = await grupo(_cursoA);
      _grupoE = await grupo(_cursoE);

      final vmFacultades = crearVmFacultades();
      await vmFacultades.listarYNotificarFacultades();
      final digitos = DateTime.now().millisecondsSinceEpoch.toString();
      final base = digitos.substring(digitos.length - 8);
      _alumnoA = '${base}1';
      _alumnoB = '${base}2';
      for (final id in [_alumnoA, _alumnoB]) {
        final RespuestaModelo registro = await servicioAutenticacion.registro(
          PerfilEntidad(
            id: id,
            nombre: 'Alumno prueba $id',
            correo: 'prueba_$id@unicauca.edu.co',
            tipoId: 'CC',
            sexo: 'F',
            facultad: vmFacultades.facultades.first,
            tipoAlumno: 'Estudiante',
          ),
        );
        expect(registro.codigoHttp, 201, reason: 'no se registro $id');
      }
      final vmInscripcion = crearVmInscripcion();
      for (final ins in [
        _inscripcion(_alumnoA, _grupo!),
        _inscripcion(_alumnoB, _grupo!),
        _inscripcion(_alumnoA, _grupoE!),
      ]) {
        expect(await vmInscripcion.agregarIncripcion(ins), isA<Exito>());
      }
      expect(
        await vmInscripcion.desvincularInscripcion(_inscripcion(_alumnoB, _grupo!)),
        isA<Exito>(),
      );

      final vmClase = crearVmClase();
      final ge = _grupoE!;
      vmClase.inicializarGrupo(ge.categoria, ge.curso, ge.anio, ge.iterable, _idInstructor);
      expect(
        await vmClase.registrarClase(
          fecha: DateTime.now().subtract(const Duration(days: 1)),
          horasTexto: '2',
        ),
        isA<Exito>(),
        reason: 'no se registro la clase del grupo especial',
      );
    });
  }

  void prueba1ListarGruposDelCurso(Gruposviewmodel Function() crearVm) {
    String metodo = "Listar grupos de";
    String caso = "el curso trae su grupo con los datos enviados";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.listarGruposDe(_cursoA.tituloCategoria, _cursoA.nombreCurso);

      expect(vm.error, isNull);
      final g = vm.getListaGrupos!.single;
      expect(g.cupos, 20);
      expect(g.idInstructor, _idInstructor);
      expect(g.anio, DateTime.now().year);
      expect(g.iterable, _grupoCreado().iterable);
      expect(g.fechaCreacion, FormatDate.fechaACadena(DateTime.now(), '-'));
    });
  }

  //H-08
  void prueba2SegundoGrupo(Gruposviewmodel Function() crearVm) {
    String metodo = "Insertar grupo";
    String caso = "el segundo grupo del curso recibe otro iterable";
    test('$capa - $tipo - $metodo - $caso', () async {
      final r = await crearVm().insertarGrupo(_nuevoGrupo(_cursoA));
      expect(r.codigoHttp, 201);

      final vm = crearVm();
      await vm.listarGruposDe(_cursoA.tituloCategoria, _cursoA.nombreCurso);
      final iterables = vm.getListaGrupos!.map((g) => g.iterable).toList();
      expect(iterables, hasLength(2));
      expect(iterables.toSet(), hasLength(2), reason: '$iterables');
    });
  }

  //H-09
  void prueba3ListasVacias(Gruposviewmodel Function() crearVm) {
    String metodo = "Listar grupos de y del instructor";
    String caso = "un curso o un instructor sin grupos dan lista vacia sin error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.listarGruposDe(_cursoB.tituloCategoria, _cursoB.nombreCurso);
      expect(vm.error, isNull);
      expect(vm.getListaGrupos, isEmpty);

      final vmInstructor = crearVm();
      await vmInstructor.listarGruposInstructor('noexiste$_marca');
      expect(vmInstructor.error, isNull);
      expect(vmInstructor.getListaGrupos, isEmpty);
    });
  }

  void prueba4PantallaDelGrupo(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "carga su curso, sin clases no hay error y su alumno inscrito aparece";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm(_grupoCreado());
      await vm.cargar();

      expect(vm.curso.error, isNull);
      expect(vm.curso.datos?.nombreCurso, _cursoA.nombreCurso);
      expect(vm.clases.error, isNull);
      expect(vm.clases.datos, isEmpty);
      expect(vm.alumnos.error, isNull);
      expect(vm.alumnos.datos.map((a) => a.id), contains(_alumnoA));
    });
  }

  //los tres siguientes salen rojos: son de diagnostico y solo los llama
  //test/diagnostico/grupos/remoto_diagnostico_test.dart, no main_test.dart.
  //No cambian datos

  //H-10: es la lista a la que se toma asistencia
  void diagnosticoAlumnoDesvinculado(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "BUG GR-06 - los alumnos del grupo no incluyen al desvinculado";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final vm = crearVm(_grupoCreado());
      await vm.cargar();

      expect(vm.alumnos.error, isNull);
      expect(vm.alumnos.datos.map((a) => a.id), [_alumnoA]);
    });
  }

  //H-01 contra el backend
  void diagnosticoGruposConAmpersand(Gruposviewmodel Function() crearVm) {
    String metodo = "Listar grupos de";
    String caso = "BUG GR-03 - una categoria y un curso con & traen su grupo";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.listarGruposDe(_cursoE.tituloCategoria, _cursoE.nombreCurso);

      expect(vm.error, isNull);
      expect(vm.getListaGrupos, hasLength(1), reason: 'grupos: ${vm.getListaGrupos?.length}');
    });
  }

  //H-02 contra el backend
  void diagnosticoPantallaConAmpersand(DetalleGrupoViewModel Function(Grupoentidad) crearVm) {
    String metodo = "Pantalla del grupo";
    String caso = "BUG GR-05 - un grupo con & en el nombre ve su curso, su clase y su alumno";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final vm = crearVm(_grupoE!);
      await vm.cargar();

      final estado =
          'curso: ${vm.curso.datos?.nombreCurso} (${vm.curso.error}); '
          'clases: ${vm.clases.datos.length} (${vm.clases.error}); '
          'alumnos: ${vm.alumnos.datos.length} (${vm.alumnos.error}); '
          'horarios: (${vm.horarios.error})';
      expect(vm.curso.datos?.nombreCurso, _cursoE.nombreCurso, reason: estado);
      expect(vm.clases.datos, hasLength(1), reason: estado);
      expect(vm.alumnos.datos.map((a) => a.id), [_alumnoA], reason: estado);
      expect(vm.horarios.error, isNull, reason: estado);
    });
  }

  //H-06: el formulario deja escribir 0
  void prueba5CuposEnCero(Gruposviewmodel Function() crearVm) {
    String metodo = "Insertar grupo";
    String caso = "un grupo con 0 cupos no se crea";
    test('$capa - $tipo - $metodo - $caso', () async {
      final r = await crearVm().insertarGrupo(_nuevoGrupo(_cursoB, cupos: 0));
      expect(r.codigoHttp, isNot(201), reason: 'codigo ${r.codigoHttp}');
    });
  }

  //H-07
  void prueba6DatosInexistentes(Gruposviewmodel Function() crearVm) {
    String metodo = "Insertar grupo";
    String caso = "un curso o un instructor inexistentes no crean grupo";
    test('$capa - $tipo - $metodo - $caso', () async {
      final sinCurso = await crearVm().insertarGrupo(
        Grupoentidad(
          categoria: _cursoB.tituloCategoria,
          curso: 'noexiste_$_marca',
          anio: 0,
          iterable: 0,
          imagen: _cursoB.imagen,
          cupos: 10,
          idInstructor: _idInstructor,
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
        ),
      );
      expect(sinCurso.codigoHttp, isNot(201), reason: 'curso: ${sinCurso.codigoHttp}');

      final sinInstructor = await crearVm().insertarGrupo(
        Grupoentidad(
          categoria: _cursoB.tituloCategoria,
          curso: _cursoB.nombreCurso,
          anio: 0,
          iterable: 0,
          imagen: _cursoB.imagen,
          cupos: 10,
          idInstructor: 'noexiste$_marca',
          fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
        ),
      );
      expect(
        sinInstructor.codigoHttp,
        isNot(201),
        reason: 'instructor: ${sinInstructor.codigoHttp}',
      );
    });
  }

  //mismo armado que GrupoFormulario: anio e iterable los calcula el backend
  Grupoentidad _nuevoGrupo(CursoEntidad c, {int cupos = 20}) => Grupoentidad(
    categoria: c.tituloCategoria,
    curso: c.nombreCurso,
    anio: DateTime.now().year,
    iterable: 0,
    imagen: c.imagen,
    cupos: cupos,
    idInstructor: _idInstructor,
    fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
  );

  Inscripcionentidad _inscripcion(String alumnoId, Grupoentidad g) =>
      Inscripcionentidad(
        alumnoId: alumnoId,
        categoria: g.categoria,
        curso: g.curso,
        anio: g.anio,
        iterable: g.iterable,
      );

  Grupoentidad _grupoCreado() {
    expect(_grupo, isNotNull, reason: 'el setUpAll no creo el grupo');
    return _grupo!;
  }

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
