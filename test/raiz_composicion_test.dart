import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/config/inyeccion/dependencias.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

//prueba de humo de la raiz de composicion: monta los mismos providers que
//main.dart y lee cada uno. Si al migrar un modulo se olvida registrar algo,
//falla aqui con ProviderNotFoundException en vez de al abrir la pantalla.
//No necesita backend: construir Dio y los vms no hace peticiones.
//Al migrar cada modulo: agregar sus servicios y quitar los vms que pasan a
//su ruta.
void main() {
  testWidgets('raiz - resuelve el cliente http y todos los vms globales', (
    tester,
  ) async {
    late BuildContext contexto;
    await tester.pumpWidget(
      MultiProvider(
        providers: [...proveedoresDatos(), ...vmsGlobales()],
        child: Builder(
          builder: (c) {
            contexto = c;
            return const SizedBox();
          },
        ),
      ),
    );

    //datos
    expect(contexto.read<Dio>().options.baseUrl, ConfigApi.baseUrl);
    expect(contexto.read<Conexionimagen>(), isA<Conexionimagenremoto>());
    expect(contexto.read<ServicioCategoria>(), isNotNull);
    expect(contexto.read<Servicioautenticacion>(), isNotNull);
    expect(contexto.read<Serviciofacultades>(), isNotNull);

    //vms globales (los que pasan a su ruta salen de esta lista)
    expect(contexto.read<EstadisticasViewModel>(), isNotNull);
    expect(contexto.read<Gruposviewmodel>(), isNotNull);
    expect(contexto.read<Horariosviewmodel>(), isNotNull);
    expect(contexto.read<Alumnosviewmodel>(), isNotNull);
    expect(contexto.read<Clasesviewmodel>(), isNotNull);
    expect(contexto.read<Deporteviewmodel>(), isNotNull);
    expect(contexto.read<AutenticacionViewModel>(), isNotNull);
    expect(contexto.read<Inscripcionviewmodel>(), isNotNull);
    expect(contexto.read<InstructoresViewModel>(), isNotNull);
  });
}
