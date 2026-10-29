import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';
import '../dobles/conexionCategoriaFalsa.dart';
import '../dobles/conexionautenticacionFalsa.dart';
import '../dobles/googleSignInFalso.dart';

//montaje compartido de las pantallas de inscripciones del coordinador (plan
//de abrir inscripciones, fase 1 en adelante). No es un test: lo usan
//test/diagnostico/inscripciones y, desde la fase 5, test/integracion.
//
//Rutas reales de route_generator (InscripcionesGenerales y
//InscripcionesParticulares). Debajo, el Serviciogrupo real hasta
//Conexiongruposremoto sobre el transporte falso, con las respuestas
//observadas del backend (test/contratos/inscripciones). Las categorias del
//filtro van con su doble: no son el objeto de este plan
class MontajeInscripciones {
  final AdaptadorHttpFalso adaptador = AdaptadorHttpFalso();

  //categorias de los grupos del contrato, para el desplegable del filtro
  final ConexionCategoriaFalsa conexionCategorias =
      ConexionCategoriaFalsa()
        ..respuestaListar = RespuestaModelo(
          codigoHttp: 200,
          datos: [
            categoriaModelo(titulo: 'Categoria Fase 4', descripcion: 'Desc'),
            categoriaModelo(
              titulo: 'prueba_actualizar_20260817183250444203',
              descripcion: 'Desc',
            ),
          ],
        );

  late final AutenticacionViewModel sesion = AutenticacionViewModel(
    Servicioautenticacion(
      Autenticacionrepositorio(conexion: ConexionautenticacionFalsa()),
    ),
    GoogleSignInFalso(),
  )..perfilSesion = PerfilEntidad(
    id: 'coo1',
    nombre: 'Coordinacion',
    correo: 'coordinacion@unicauca.edu.co',
    tipoId: 'CC',
    sexo: 'F',
    role: Roles.coordinador,
  );

  MontajeInscripciones() {
    adaptador.responder(
      'GET',
      '/gruposNoEliminados',
      200,
      leerContrato('inscripciones', 'gruposNoEliminados_200'),
    );
    adaptador.responder(
      'PUT',
      '/abrirInscripcionesGrupo',
      200,
      leerContrato('inscripciones', 'abrir_200'),
    );
    adaptador.responder(
      'PUT',
      '/cerrarInscripcionesGrupo',
      200,
      leerContrato('inscripciones', 'cerrar_200'),
    );
  }

  //categorias de los tres grupos de gruposNoEliminados_200.json
  static const Set<String> categoriasDelContrato = {
    'Categoria Fase 4',
    'prueba_actualizar_20260817183250444203',
  };

  //app con las rutas reales; arranca en una pantalla con un boton que abre
  //la ruta pedida, como el menu lateral del coordinador
  Future<void> abrir(WidgetTester tester, String ruta) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ServicioCategoria>(
            create:
                (_) => ServicioCategoria(
                  CategoriaRepositorio(cliente: conexionCategorias),
                ),
          ),
          Provider<Serviciogrupo>(
            create:
                (_) => Serviciogrupo(
                  Gruporepositorio(
                    conexion: Conexiongruposremoto(crearDioFalso(adaptador)),
                  ),
                ),
          ),
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: sesion),
        ],
        child: MaterialApp(
          onGenerateRoute: generateRoute,
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () => Navigator.pushNamed(context, ruta),
                  child: const Text('Abrir pantalla'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir pantalla'));
    await tester.pumpAndSettle();
  }

  Future<void> abrirParticulares(WidgetTester tester) =>
      abrir(tester, AppRutas.InscripcionesParticulares);

  Future<void> abrirGenerales(WidgetTester tester) =>
      abrir(tester, AppRutas.InscripcionesGenerales);
}
