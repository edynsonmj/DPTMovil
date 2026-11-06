@Tags(['diagnostico'])
library;

import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/googleSignInFalso.dart';
import '../../main_test.dart'
    show
        baseUrlPruebas,
        crearAtencionViewModel,
        crearClasesViewModel,
        crearDetalleGrupoViewModel,
        crearHorariosViewModel,
        prepararVmEstadisticasAsistencia;
import '../../remoto/datosPruebas.dart';
import '../../remoto/jwtPruebas.dart';
import '../../remoto/viewModel/estadisticas/vmEstadisticasAsistenciaTest.dart';

//incompatibilidades con el backend nuevo que cruzan modulos (plan-diagnostico-
//backend-nuevo.md). Reusa la siembra de estadisticas: un grupo con horario, una
//clase de ayer y alumnos inscritos. Necesita el backend en localhost:8082: sin
//el, falla en el setUpAll y su rojo no demuestra nada
void main() {
  const String capa = "viewModel";
  const String tipo = "diagnostico";
  final DateTime ayer = DateTime.now().subtract(const Duration(days: 1));

  String texto(Resultado<void> r) => switch (r) {
    Exito() => 'Exito',
    Fallo(:final codigo, :final mensaje, :final origen) =>
      'Fallo $codigo $mensaje ($origen)',
  };

  group('Modulos restantes contra el backend nuevo (diagnostico):', () {
    final semilla = VmEstadisticasAsistenciaTest();
    prepararVmEstadisticasAsistencia(semilla);

    tearDown(actuarComoCoordinador);

    //un grupo sin horarios, clases ni alumnos
    Future<Grupoentidad> grupoVacio() async {
      final g = semilla.grupoSembrado;
      final r = await crearDioPruebas(baseUrlPruebas).post(
        '/grupo',
        data: {
          'categoria': g.categoria,
          'curso': g.curso,
          'anio': g.anio,
          'iterable': 0,
          'imagenGrupo': g.imagen,
          'idInstructor': g.idInstructor,
          'cupos': 5,
          'fechaCreacion': FormatDate.fechaACadena(DateTime.now(), '-'),
          'fechaIncripcionCierre': cierreInscripcionPruebas(),
        },
      );
      return Grupoentidad(
        categoria: g.categoria,
        curso: g.curso,
        anio: g.anio,
        iterable: r.data['iterable'] as int,
        imagen: g.imagen,
        idInstructor: g.idInstructor,
        cupos: 5,
        fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
      );
    }

    Clasesviewmodel vmClaseDe(Grupoentidad g) =>
        crearClasesViewModel()..inicializarGrupo(
          g.categoria,
          g.curso,
          g.anio,
          g.iterable,
          g.idInstructor!,
        );

    //prueba4ClaseInexistente de la suite remota sigue en verde por casualidad:
    //su 404 es el de una ruta que no existe, no el de la clase
    test('$capa - $tipo - Asistencias - BUG BK-02 - la lista de una clase real carga', () async {
      final g = semilla.grupoSembrado;
      final detalle = crearDetalleGrupoViewModel(g);
      await detalle.cargarClases();
      final vm = crearAtencionViewModel();

      await vm.cargarAtenciones(g, detalle.clases.datos.first);

      expect(vm.error, isNull);
      expect(vm.atenciones, isNotEmpty);
    });

    test('$capa - $tipo - Registrar clase - control BK-04 - sin horario ese dia y sin justificacion el backend la rechaza', () async {
      final g = await grupoVacio();

      final r = await vmClaseDe(g).registrarClase(fecha: ayer, horasTexto: '2');

      expect(r, isA<Fallo>(), reason: texto(r));
      expect((r as Fallo).codigo, 422);
    });

    //la app no tiene como enviar la justificacion: el parametro no existe
    test('$capa - $tipo - Registrar clase - BUG BK-04 - sin horario ese dia se puede enviar la justificacion', () async {
      final g = await grupoVacio();

      final Resultado<void> r = await (vmClaseDe(g) as dynamic).registrarClase(
        fecha: ayer,
        horasTexto: '2',
        justificacion: 'Clase de reposicion acordada con el grupo',
      );

      expect(r, isA<Exito>(), reason: texto(r));
    });

    //con horarios el grupo funciona; solo falla la lista vacia
    test('$capa - $tipo - Horarios - BUG BK-05 - un grupo sin horarios queda vacio y sin error', () async {
      final g = await grupoVacio();
      final vm = crearHorariosViewModel();

      await vm.cargarHorariosDe([g]);

      expect(vm.horariosDe(g).error, isNull);
      expect(vm.horariosDe(g).datos, isEmpty);
    });

    //el menu ofrece "Continuar con correo", que llama GET /login sin JWT.
    //VmLoginTest.prueba1 pasa porque la suite si manda un token
    test('$capa - $tipo - Login - BUG BK-11 - el inicio con correo responde sin exigir un JWT que aun no existe', () async {
      almacenPruebas.token = null;
      final vm = AutenticacionViewModel(
        Servicioautenticacion(
          Autenticacionrepositorio(
            conexion: Conexionautenticacionremoto(
              crearDioPruebas(baseUrlPruebas),
            ),
            almacenToken: AlmacenToken(),
          ),
        ),
        GoogleSignInFalso(),
      );
      vm.prepararLoginConCorreo('prueba_no_registrado@noexiste.test');

      final respuesta = await vm.login();

      expect(respuesta.codigoHttp, isNot(401));
    });
  });
}
