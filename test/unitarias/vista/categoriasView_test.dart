import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
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

import '../../dobles/conexionCategoriaFalsa.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

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
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa()),
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
    expect(find.text('Agregar categoria'), findsNothing);

    vmSesion.perfilSesion = perfil(Roles.coordinador);
    //perfilSesion es un campo: la vista se entera cuando el vm notifica
    vmSesion.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Agregar categoria'), findsOneWidget);
  });
}
