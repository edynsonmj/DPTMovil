import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCategoriaFalsa.dart';

//el vm recibe su servicio por constructor desde la fase 1: se arma la misma
//cadena que la raiz, pero con el doble en lugar de la conexion remota. Solo
//rutas criticas; los casos contra el backend real siguen en test/remoto
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionCategoriaFalsa conexion;
  late CategoriaViewModel vm;

  setUp(() {
    conexion = ConexionCategoriaFalsa();
    vm = CategoriaViewModel(
      ServicioCategoria(CategoriaRepositorio(cliente: conexion)),
    );
  });

  group('Categorias (vm con doble):', () {
    test('$capa - $tipo - Listar categorias - 200 carga la lista', () async {
      conexion.respuestaListar = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          categoriaModelo(titulo: 'Futbol', descripcion: 'Desc', imagenId: 1),
        ],
      );

      await vm.listarYNotificarCategorias();

      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.categorias?.map((c) => c.titulo), ['Futbol']);
      //las entradas del filtro de inscripciones salen de la misma lista
      expect(vm.titulos.length, 1);
    });

    test('$capa - $tipo - Guardar categoria - 201 refresca la lista', () async {
      conexion.respuestaGuardar = RespuestaModelo(
        codigoHttp: 201,
        datos: categoriaModelo(titulo: 'Futbol', descripcion: 'Desc', imagenId: 1),
      );
      conexion.respuestaListar = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          categoriaModelo(titulo: 'Futbol', descripcion: 'Desc', imagenId: 1),
        ],
      );

      final resultado = await vm.insertarCategoria(
        CategoriaEntidad(titulo: 'Futbol', descripcion: 'Desc', idImagen: 1),
      );

      expect(resultado, isA<Exito<CategoriaEntidad>>());
      //el vm vuelve a pedir la lista tras el exito
      expect(conexion.llamadasListar, 1);
      expect(vm.categorias?.map((c) => c.titulo), ['Futbol']);
    });

    test('$capa - $tipo - Eliminar categoria - 200 refresca la lista', () async {
      conexion.respuestaEliminar = RespuestaModelo(codigoHttp: 200);
      conexion.respuestaListar = RespuestaModelo(codigoHttp: 204);

      final resultado = await vm.eliminarCategoria('Futbol');

      expect(resultado, isA<Exito>());
      expect(conexion.ultimoTituloEliminado, 'Futbol');
      expect(conexion.llamadasListar, 1);
      //tras borrar la ultima, el 204 deja la lista vacia sin error
      expect(vm.categorias, isEmpty);
      expect(vm.error, isNull);
    });
  });
}
