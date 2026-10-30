@Tags(['diagnostico'])
library;

import 'dart:io';

import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCursoFalsa.dart';

//diagnostico del repositorio de cursos (plan-diagnostico-cursos.md): afirma
//el comportamiento CORRECTO y se espera que salga rojo mientras el bug
//exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexionCursoFalsa conexion;
  late CursoRepositorio repositorio;

  setUp(() {
    conexion = ConexionCursoFalsa();
    repositorio = CursoRepositorio(cliente: conexion);
  });

  group('Cursos (diagnostico del repositorio):', () {
    //los errores no se lanzan entre capas, se devuelven. El repositorio no
    //tiene ningun try; la conexion real deja pasar el TypeError de fromJson y
    //el de imagenFile! (CU-03, CU-04)
    test('$capa - $tipo - Listar, obtener y guardar curso - BUG CU-01 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzar = TypeError();

      for (final pedir in <Future<dynamic> Function()>[
        () => repositorio.listarCursosDe(
          CategoriaEntidad(titulo: 'Deportes', descripcion: 'x'),
        ),
        () => repositorio.obtenerCurso('Deportes', 'Iniciacion'),
        () => repositorio.guardaCurso(
          CursoEntidad(
            nombreCurso: 'Iniciacion',
            nombreDeporte: 'Futbol',
            tituloCategoria: 'Deportes',
            descripcion: 'Desc',
            imagenFile: File('assets/images/1.jpg'),
          ),
        ),
      ]) {
        final respuesta = await pedir();
        expect(respuesta.codigoHttp, isNot(200));
        expect(respuesta.error, isNotNull);
      }
    });
  });
}
