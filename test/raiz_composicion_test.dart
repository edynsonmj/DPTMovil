import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/config/inyeccion/dependencias.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioDeporte.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicioImagen.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/widgets.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/api/sesion/interceptorToken.dart';
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
    //el JWT de la sesion: el Dio compartido lo envia con su interceptor
    expect(contexto.read<AlmacenToken>(), isNotNull);
    expect(
      contexto.read<Dio>().interceptors.whereType<InterceptorToken>(),
      hasLength(1),
    );
    expect(contexto.read<Conexionimagen>(), isA<Conexionimagenremoto>());
    expect(contexto.read<ServicioCategoria>(), isNotNull);
    expect(contexto.read<ServicioCurso>(), isNotNull);
    expect(contexto.read<Serviciodeporte>(), isNotNull);
    expect(contexto.read<Servicioimagen>(), isNotNull);
    expect(contexto.read<Serviciogrupo>(), isNotNull);
    expect(contexto.read<Serviciohorario>(), isNotNull);
    expect(contexto.read<Servicioalumno>(), isNotNull);
    expect(contexto.read<Servicioclase>(), isNotNull);
    expect(contexto.read<ServicioInstructor>(), isNotNull);
    expect(contexto.read<Servicioatencion>(), isNotNull);
    expect(contexto.read<Servicioinscripcion>(), isNotNull);
    expect(contexto.read<Servicioautenticacion>(), isNotNull);
    expect(contexto.read<Serviciofacultades>(), isNotNull);
    expect(contexto.read<ServicioEstadisticas>(), isNotNull);

    //vms globales: desde la fase 7 solo la sesion
    expect(contexto.read<AutenticacionViewModel>(), isNotNull);
  });
}
