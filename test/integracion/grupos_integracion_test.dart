import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 3 (plan-diagnostico-grupos.md): Gruposviewmodel
//con su cadena real hasta Conexiongruposremoto y el transporte falso debajo.
//Los grupos tienen la forma real del backend (contrato observado de
//inscripciones, /gruposNoEliminados: mismo GrupoDto)
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late Gruposviewmodel vm;

  List gruposDelContrato() =>
      leerContrato('inscripciones', 'gruposNoEliminados_200') as List;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = Gruposviewmodel(
      Serviciogrupo(
        Gruporepositorio(
          conexion: Conexiongruposremoto(crearDioFalso(adaptador)),
        ),
      ),
    );
  });

  group('Grupos (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Listar grupos de - 200 pide el curso y deja la lista con sus datos', () async {
      adaptador.responder('GET', '/gruposCurso', 200, gruposDelContrato().take(2).toList());

      final lista = await vm.listarGruposDe('Categoria Fase 4', 'Curso Categoria Fase 4');

      final peticion = adaptador.peticionesA('GET', '/gruposCurso').single;
      expect(peticion.uri.queryParameters, {
        'prmCategoria': 'Categoria Fase 4',
        'prmCurso': 'Curso Categoria Fase 4',
      });
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(lista.map((g) => g.iterable), [1, 2]);
      expect(vm.getListaGrupos!.first.cupos, 10);
      expect(vm.getListaGrupos!.first.fechaInscripcionCierre, '2026-12-31');
    });

    test('$capa - $tipo - Listar grupos de - 200 [] es lista vacia sin error', () async {
      adaptador.responder('GET', '/gruposCurso', 200, []);

      await vm.listarGruposDe('Categoria Fase 4', 'Sin grupos');

      expect(vm.error, isNull);
      expect(vm.getListaGrupos, isEmpty);
    });

    test('$capa - $tipo - Listar grupos del instructor - pide su id y sin red deja el 503 en el error', () async {
      adaptador.fallar('GET', '/gruposInstructor', DioExceptionType.connectionError);

      await vm.listarGruposInstructor('2');

      expect(
        adaptador.peticionesA('GET', '/gruposInstructor').single.uri.queryParameters,
        {'idInstructor': '2'},
      );
      expect(vm.cargando, isFalse);
      expect(vm.error, contains('503'));
      expect(vm.getListaGrupos, isEmpty);
    });

    test('$capa - $tipo - Insertar grupo - envia el GrupoDto y 201 vuelve como 201', () async {
      adaptador.responder('POST', '/grupo', 201, gruposDelContrato().first);

      final respuesta = await vm.insertarGrupo(
        Grupoentidad(
          categoria: 'Categoria Fase 4',
          curso: 'Curso Categoria Fase 4',
          anio: 0,
          iterable: 0,
          imagen: 1197,
          cupos: 10,
          idInstructor: '2',
          fechaCreacion: '2026-10-29',
        ),
      );

      expect(respuesta.codigoHttp, 201);
      final cuerpo = adaptador.peticionesA('POST', '/grupo').single.cuerpo as Map;
      expect(cuerpo['categoria'], 'Categoria Fase 4');
      expect(cuerpo['curso'], 'Curso Categoria Fase 4');
      expect(cuerpo['cupos'], 10);
      expect(cuerpo['idInstructor'], '2');
      expect(cuerpo['imagenGrupo'], 1197);
      expect(cuerpo['fechaCreacion'], '2026-10-29');
      //sin fecha de finalizacion la clave no viaja
      expect(cuerpo.containsKey('fechaFinalizacion'), isFalse);
    });

    //antes GR-02: el POST perdia la fecha de finalizacion
    test('$capa - $tipo - Insertar grupo - el POST lleva la fecha de finalizacion', () async {
      adaptador.responder('POST', '/grupo', 201);

      await vm.insertarGrupo(
        Grupoentidad(
          categoria: 'Categoria Fase 4',
          curso: 'Curso Categoria Fase 4',
          anio: 0,
          iterable: 0,
          cupos: 10,
          idInstructor: '2',
          fechaCreacion: '2026-10-29',
          fechaFinalizacion: '2026-12-15',
        ),
      );

      final cuerpo = adaptador.peticionesA('POST', '/grupo').single.cuerpo as Map;
      expect(cuerpo['fechaFinalizacion'], '2026-12-15');
    });

    test('$capa - $tipo - Insertar grupo - un 400 del backend llega con su codigo', () async {
      adaptador.responder('POST', '/grupo', 400, {'cupos': 'must not be null'});

      final respuesta = await vm.insertarGrupo(
        Grupoentidad(
          categoria: 'Categoria Fase 4',
          curso: 'Curso Categoria Fase 4',
          anio: 0,
          iterable: 0,
          cupos: 10,
          fechaCreacion: '2026-10-29',
        ),
      );

      expect(respuesta.codigoHttp, 400);
      expect(respuesta.error, isNotNull);
    });
    //los casos rojos de este montaje (GR-02 a GR-04) estan en
    //test/diagnostico/grupos/integracion_diagnostico_test.dart
  });
}
