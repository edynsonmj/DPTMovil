import 'package:dpt_movil/data/models/errorModelo.dart';
import 'dart:io';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCursoFalsa.dart';

//el vm recibe su servicio por constructor desde la fase 3: se arma la misma
//cadena que la raiz, pero con el doble en lugar de la conexion remota. Solo
//rutas criticas; los casos contra el backend real siguen en test/remoto
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionCursoFalsa conexion;
  late CursosViewModel vm;

  CursoModelo modelo(String nombre) => CursoModelo(
    nombreCurso: nombre,
    nombreDeporte: 'Futbol',
    tituloCategoria: 'Deportes',
    descripcion: 'Desc',
    imagen: 1,
  );

  setUp(() {
    conexion = ConexionCursoFalsa();
    vm = CursosViewModel(ServicioCurso(CursoRepositorio(cliente: conexion)));
  });

  group('Cursos (vm con doble):', () {
    test('$capa - $tipo - Listar cursos de - 200 carga la lista y notifica', () async {
      conexion.respuestaCursosDe = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo('Iniciacion'), modelo('Avanzado')],
      );
      int notificaciones = 0;
      vm.addListener(() => notificaciones++);

      final resultado = await vm.listarCursosDe(
        CategoriaEntidad(titulo: 'Deportes', descripcion: 'x'),
      );
      expect(resultado, isA<Exito<void>>());

      expect(conexion.ultimaCategoria, 'Deportes');
      expect(vm.getListaCursos?.map((c) => c.nombreCurso), [
        'Iniciacion',
        'Avanzado',
      ]);
      //el desplegable de cursos.dart sale de la misma lista
      expect(vm.nombresCursos, [
        'Iniciacion',
        'Avanzado',
      ]);
      //una al empezar (cargando) y otra al terminar
      expect(notificaciones, 2);
    });

    test('$capa - $tipo - Agregar curso - 201 devuelve la entidad', () async {
      conexion.respuestaAgregar = RespuestaModelo(
        codigoHttp: 201,
        datos: modelo('Iniciacion'),
      );

      final respuesta = await vm.agregarCurso(
        CursoEntidad(
          nombreCurso: 'Iniciacion',
          nombreDeporte: 'Futbol',
          tituloCategoria: 'Deportes',
          descripcion: 'Desc',
        ),
      );

      expect(conexion.llamadasAgregar, 1);
      expect(conexion.ultimoAgregado?.nombreCurso, 'Iniciacion');
      expect(respuesta.codigoHttp, 201);
      expect(respuesta.datos, isA<CursoEntidad>());
    });

    //reglas del formulario de alta, que antes vivian en FormularioCurso
    group('Guardar curso:', () {
      Future<Resultado<CursoEntidad>> guardar({
        String? deporte = 'Futbol',
        File? imagen,
        CursoEntidad? original,
      }) => vm.guardarCurso(
        nombre: '  Iniciacion ',
        descripcion: ' Desc ',
        categoria: 'Deportes',
        deporte: deporte,
        imagenNueva: imagen,
        original: original,
      );

      test('$capa - $tipo - Guardar curso - 201 arma la entidad y devuelve Exito', () async {
        conexion.respuestaAgregar = RespuestaModelo(
          codigoHttp: 201,
          datos: modelo('Iniciacion'),
        );

        final resultado = await guardar(imagen: File('assets/images/1.jpg'));

        expect(resultado, isA<Exito<CursoEntidad>>());
        final enviado = conexion.ultimoAgregado!;
        expect(
          (enviado.nombreCurso, enviado.descripcion, enviado.nombreDeporte, enviado.tituloCategoria),
          ('Iniciacion', 'Desc', 'Futbol', 'Deportes'),
        );
        expect(enviado.imagenFile?.path, 'assets/images/1.jpg');
      });

      test('$capa - $tipo - Guardar curso - sin deporte o sin imagen no envia nada', () async {
        final sinDeporte = await guardar(deporte: null, imagen: File('assets/images/1.jpg'));
        final sinImagen = await guardar();

        expect(
          [sinDeporte, sinImagen].map((r) => (r as Fallo).mensaje),
          ['Selecciona un deporte por favor', 'Carga una imagen por favor'],
        );
        expect(conexion.llamadasAgregar, 0);
      });

      test('$capa - $tipo - Guardar curso - en edicion avisa que no esta disponible', () async {
        final resultado = await guardar(
          imagen: File('assets/images/1.jpg'),
          original: CursoEntidad(
            nombreCurso: 'Iniciacion',
            nombreDeporte: 'Futbol',
            tituloCategoria: 'Deportes',
            descripcion: 'Desc',
          ),
        );

        expect(resultado, isA<Fallo<CursoEntidad>>());
        expect(conexion.llamadasAgregar, 0);
      });

      test('$capa - $tipo - Guardar curso - un error del backend vuelve como Fallo con su codigo', () async {
        conexion.respuestaAgregar = RespuestaModelo(
          codigoHttp: 409,
          error: ErrorModelo(codigoHttp: 409, mensaje: 'ya existe', url: '/curso', metodo: 'POST'),
        );

        final resultado = await guardar(imagen: File('assets/images/1.jpg'));

        expect(
          resultado,
          isA<Fallo<CursoEntidad>>()
              .having((f) => f.codigo, 'codigo', 409)
              .having((f) => f.mensaje, 'mensaje', 'ya existe'),
        );
      });
    });

    test('$capa - $tipo - Url de imagen - la arma la conexion', () {
      //la vista ya no conoce el servidor: la url baja desde la conexion
      expect(vm.urlImagen(5), 'http://falso/imagenStream?idImagen=5');
    });
  });
}
