// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/local/ConexionCategoriaLocal.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'local/categorias/insertarCategoriaLocal.dart';
import 'local/categorias/obtenerCategoriasLocal.dart';
import 'remoto/categorias/insertarCategoriaTest.dart';
import 'remoto/categorias/listarCategoriaTest.dart';

void main() {
  probarRepositorioCategoriaLocal();
}

probarRepositorioCategoriaLocal() {
  String ip = '192.168.100.66';
  CategoriaRepositorio repositorio = configuracionCategoriaRepositorio(
    true,
    ip,
  );
  group('Obtener categorias:', () {
    Obtenercategoriaslocal test = Obtenercategoriaslocal();
    test.prueba1ObtenerLista(repositorio);
    test.prueba2ListaTipo(repositorio);
  });
  group('insertar Categoria: ', () {
    Insertarcategorialocal test = Insertarcategorialocal();
    test.prueba1InsercionExitosa(repositorio);
    test.prueba2InsercionRepetida(repositorio);
    test.prueba3InsercionIncompleta(repositorio);
  });
}

probarRepositorioCategoriaRemota() {
  String ip = '192.168.100.66';
  CategoriaRepositorio repositorio = configuracionCategoriaRepositorio(
    false,
    ip,
  );
  grupoInsercionCategoriaRemota(repositorio);
  grupoObtenerCateogoriaRemota(repositorio);
}

grupoInsercionCategoriaRemota(CategoriaRepositorio repositorio) {
  print("hola");
  group('Insertar Categoria:', () {
    Random random = Random();
    InsertarCategoriaTest test = InsertarCategoriaTest();
    test.prueba1(random, repositorio);
    test.prueba2Exito(random, repositorio);
    test.prueba3(random, repositorio);
    test.prueba4(random, repositorio);
    test.prueba5(random, repositorio);
  });
}

grupoObtenerCateogoriaRemota(CategoriaRepositorio repositorio) {
  group('Obtener Categoria:', () {
    ListarCategoriaTest test = ListarCategoriaTest();
    test.prueba1codigo200(repositorio);
    test.prueba2codigo204(repositorio);
  });
}

CategoriaRepositorio configuracionCategoriaRepositorio(bool local, String? ip) {
  CategoriaRepositorio repositorio;
  if (local) {
    ConfigServicio.tipoFabricaServicio =
        ConexionFabricaAbstracta.SERVICIO_LOCAL;
    repositorio = CategoriaRepositorio(cliente: ConexionCategoriaLocal());
  } else {
    ConfigServicio.tipoFabricaServicio =
        ConexionFabricaAbstracta.SERVICIO_REMOTO;
    ConfigServicio.ip = ip;
    repositorio = CategoriaRepositorio(cliente: ConexionCategoriaRemota());
  }
  return repositorio;
}
