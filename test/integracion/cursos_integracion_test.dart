import 'dart:io';

import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 8 (plan-diagnostico-cursos.md): CursosViewModel
//con su cadena real hasta ConexionCursoRemoto y Conexionimagenremoto (el alta
//sube la imagen y despues el curso), con el transporte falso debajo y las
//respuestas del contrato observado
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late CursosViewModel vm;

  final categoria = CategoriaEntidad(titulo: 'Categoria Fase 4', descripcion: 'x');

  CursoEntidad nuevo() => CursoEntidad(
    nombreCurso: 'Curso nuevo',
    nombreDeporte: 'Atletismo',
    tituloCategoria: 'Categoria Fase 4',
    descripcion: 'Curso creado en la prueba',
    //relativa al directorio de trabajo: correr desde la raiz
    imagenFile: File('assets/images/1.jpg'),
  );

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    final dio = crearDioFalso(adaptador);
    vm = CursosViewModel(
      ServicioCurso(
        CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio))),
      ),
    );
  });

  group('Cursos (vm → conexion real → transporte falso):', () {
    //sin error el vm no usa el context (solo lo usa para sus dialogos)
    test('$capa - $tipo - Listar cursos de - 200 pide la categoria y llena la lista y el desplegable', () async {
      adaptador.responder('GET', '/cursosbycategoria', 200, leerContrato('cursos', 'cursosbycategoria_200'));

      await vm.listarCursosDe(null, categoria);

      expect(
        adaptador.peticionesA('GET', '/cursosbycategoria').single.uri.queryParameters,
        {'prmCategoria': 'Categoria Fase 4'},
      );
      expect(vm.getListaCursos!.map((c) => c.nombreCurso), [
        'Curso Categoria Fase 4',
        'Curso 2 Fase 4',
      ]);
      expect(vm.getListaCursos!.first.imagen, 1197);
      expect(vm.getListaEntradas.map((e) => e.label), [
        'Curso Categoria Fase 4',
        'Curso 2 Fase 4',
      ]);
    });

    test('$capa - $tipo - Listar cursos de - 200 [] deja la lista y el desplegable vacios', () async {
      adaptador.responder('GET', '/cursosbycategoria', 200, []);

      await vm.listarCursosDe(null, categoria);

      expect(vm.getListaCursos, isEmpty);
      expect(vm.getListaEntradas, isEmpty);
    });

    test('$capa - $tipo - Agregar curso - sube la imagen, envia el CursoDto con su id y 201 devuelve la entidad', () async {
      adaptador.responder('POST', '/imagenMultipart', 201, leerContrato('cursos', 'imagenMultipart_201'));
      adaptador.responder('POST', '/curso', 201, leerContrato('cursos', 'curso_201'));

      final respuesta = await vm.agregarCurso(nuevo());

      expect(
        adaptador.peticiones.map((p) => '${p.metodo} ${p.ruta}'),
        ['POST /imagenMultipart', 'POST /curso'],
      );
      expect(adaptador.peticionesA('POST', '/curso').single.cuerpo, {
        'nombre': 'Curso nuevo',
        'deporte': 'Atletismo',
        'categoriaCurso': 'Categoria Fase 4',
        'descripcion': 'Curso creado en la prueba',
        'idImagen': 1300,
      });
      expect(respuesta.codigoHttp, 201);
      expect((respuesta.datos as CursoEntidad).imagen, 1300);
    });

    test('$capa - $tipo - Agregar curso - si la imagen falla no se envia el curso', () async {
      adaptador.responder('POST', '/imagenMultipart', 500, 'error al guardar la imagen');

      final respuesta = await vm.agregarCurso(nuevo());

      expect(respuesta.codigoHttp, 500);
      expect(adaptador.peticionesA('POST', '/curso'), isEmpty);
    });

    test('$capa - $tipo - Agregar curso - un 400 del curso llega con su codigo', () async {
      adaptador.responder('POST', '/imagenMultipart', 201, leerContrato('cursos', 'imagenMultipart_201'));
      adaptador.responder('POST', '/curso', 400, {'nombre': 'no debe estar vacio'});

      final respuesta = await vm.agregarCurso(nuevo());

      expect(respuesta.codigoHttp, 400);
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Obtener curso - 200 devuelve la entidad y 404 el error del backend', () async {
      adaptador.responder('GET', '/curso', 200, leerContrato('cursos', 'curso_200'));
      final encontrado = await vm.obtenerCurso('Categoria Fase 4', 'Curso Categoria Fase 4');
      expect((encontrado.datos as CursoEntidad).nombreDeporte, 'Atletismo');

      adaptador.responder('GET', '/curso', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No se encuentra registrado el elemento: null',
      });
      final ausente = await vm.obtenerCurso('Categoria Fase 4', 'No existe');
      expect(ausente.codigoHttp, 404);
      expect(ausente.error?.mensaje, contains('GC-0003'));
    });
    //los casos rojos de este montaje (CU-02 a CU-05) estan en
    //test/diagnostico/cursos/integracion_diagnostico_test.dart
  });
}
