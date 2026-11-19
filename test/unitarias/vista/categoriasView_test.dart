import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/presentation/view/views/categorias/CategoriasView.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dpt_movil/data/models/tokenModelo.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/conexionCategoriaFalsa.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//widget test de la pantalla de categorias: con la inyeccion se le pueden dar
//vms armados con dobles, sin backend ni plugin de Google. Comprueba lo que
//la vista hace con el estado del vm: pintar la lista y mostrar o no las
//opciones de coordinador segun el rol de la sesion
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  late ConexionCategoriaFalsa conexionCategoria;
  late AutenticacionViewModel vmSesion;

  setUp(() {
    conexionCategoria = ConexionCategoriaFalsa()
      ..respuestaListar = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          categoriaModelo(titulo: 'Futbol', descripcion: 'Desc 1'),
          categoriaModelo(titulo: 'Natacion', descripcion: 'Desc 2'),
        ],
      );
    vmSesion = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken()),
      ),
      GoogleSignInFalso(),
    );
  });

  //mismo arbol que en la app: la sesion global y el vm de categorias que
  //route_generator crea para la ruta
  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: vmSesion),
          ChangeNotifierProvider(
            create:
                (_) => CategoriaViewModel(
                  ServicioCategoria(
                    CategoriaRepositorio(cliente: conexionCategoria),
                  ),
                ),
          ),
        ],
        child: const MaterialApp(home: CategoriasView()),
      ),
    );
    //primer frame: la vista pide la sesion y la lista; luego se pintan
    await tester.pumpAndSettle();
  }

  PerfilEntidad perfil(String? rol) => PerfilEntidad(
    id: '1',
    nombre: 'Ana',
    correo: 'ana@unicauca.edu.co',
    tipoId: 'CC',
    sexo: 'F',
    role: rol,
  );

  testWidgets('$capa - $tipo - Categorias - pinta la lista del vm', (
    tester,
  ) async {
    await montar(tester);

    expect(conexionCategoria.llamadasListar, 1);
    expect(find.text('Futbol'), findsOneWidget);
    expect(find.text('Natacion'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Categorias - solo el coordinador puede agregar', (
    tester,
  ) async {
    vmSesion.perfilSesion = perfil(Roles.alumno);
    await montar(tester);
    expect(find.text('Nueva categoría'), findsNothing);

    vmSesion.perfilSesion = perfil(Roles.coordinador);
    //perfilSesion es un campo: la vista se entera cuando el vm notifica
    vmSesion.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  //CAT-12 / T-04 (descartado 2026-11-05): iniciar sesion por el vm, sin
  //notificar a mano, basta para que aparezca la opcion del coordinador
  testWidgets('$capa - $tipo - Categorias - iniciar sesion de coordinador muestra agregar sin recargar', (
    tester,
  ) async {
    final conexion =
        ConexionautenticacionFalsa()
          ..respuestaLogin = RespuestaModelo(
            codigoHttp: 200,
            datos: Perfilmodelo(
              id: '1',
              nombre: 'Ana',
              correo: 'ana@unicauca.edu.co',
              tipoId: 'CC',
              sexo: 'F',
              role: Roles.coordinador,
            ),
          );
    vmSesion = AutenticacionViewModel(
      Servicioautenticacion(Autenticacionrepositorio(conexion: conexion, almacenToken: AlmacenToken())),
      GoogleSignInFalso(),
    );
    await montar(tester);
    expect(find.text('Nueva categoría'), findsNothing);

    vmSesion.prepararLoginConCorreo('ana@unicauca.edu.co');
    await vmSesion.login();
    await tester.pumpAndSettle();

    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  //con el backend que exige JWT: la lista salia a la vez que verificarSesion,
  //sin token, y la pantalla mostraba el 401 hasta volver a cargarla
  testWidgets('$capa - $tipo - Categorias - con sesion de Google guardada la lista se pide despues de obtener el JWT', (
    tester,
  ) async {
    final almacen = AlmacenToken();
    final conexionSesion =
        ConexionautenticacionFalsa()
          ..respuestaToken = RespuestaModelo(
            codigoHttp: 200,
            datos: Tokenmodelo.fromJson(leerContrato('autenticacion', 'token_200')),
          );
    vmSesion = AutenticacionViewModel(
      Servicioautenticacion(Autenticacionrepositorio(conexion: conexionSesion, almacenToken: almacen)),
      GoogleSignInFalso()..cuenta = CuentaGoogleFalsa(email: 'ana@unicauca.edu.co', idToken: 'id-token-de-google'),
    );
    conexionCategoria = _CategoriasQueVenElToken(almacen)
      ..respuestaListar = conexionCategoria.respuestaListar;

    await montar(tester);

    expect(conexionSesion.llamadasToken, 1);
    expect(conexionCategoria.llamadasListar, 1);
    expect((conexionCategoria as _CategoriasQueVenElToken).tokenAlListar, ['jwt-del-sistema']);
    expect(find.text('Futbol'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Categorias - iniciar sesion estando en la pantalla vuelve a pedir la lista', (
    tester,
  ) async {
    final conexion =
        ConexionautenticacionFalsa()
          ..respuestaLogin = RespuestaModelo(
            codigoHttp: 200,
            datos: Perfilmodelo(
              id: '1',
              nombre: 'Ana',
              correo: 'ana@unicauca.edu.co',
              tipoId: 'CC',
              sexo: 'F',
              role: Roles.coordinador,
            ),
          );
    vmSesion = AutenticacionViewModel(
      Servicioautenticacion(Autenticacionrepositorio(conexion: conexion, almacenToken: AlmacenToken())),
      GoogleSignInFalso(),
    );
    await montar(tester);
    expect(conexionCategoria.llamadasListar, 1);

    vmSesion.prepararLoginConCorreo('ana@unicauca.edu.co');
    await vmSesion.login();
    await tester.pumpAndSettle();
    expect(conexionCategoria.llamadasListar, 2);

    //cerrar sesion tambien cambia el token: se vuelve a pedir
    await vmSesion.logout();
    await tester.pumpAndSettle();
    expect(conexionCategoria.llamadasListar, 3);
  });
}

//anota el JWT que habia en el almacen cuando la pantalla pidio la lista
class _CategoriasQueVenElToken extends ConexionCategoriaFalsa {
  final AlmacenToken almacen;
  final List<String?> tokenAlListar = [];
  _CategoriasQueVenElToken(this.almacen);

  @override
  Future<RespuestaModelo> encontrarCategorias() {
    tokenAlListar.add(almacen.token);
    return super.encontrarCategorias();
  }
}
