import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionclasesFalsa.dart';
import '../../dobles/conexiongruposFalsa.dart';
import '../../dobles/conexioninstructoresFalsa.dart';

//los vms del modulo grupo reciben su servicio por constructor desde la fase
//4: se arma la misma cadena que la raiz, con el doble en lugar de la conexion
//remota. Solo rutas criticas; los casos contra el backend siguen en test/remoto
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  group('Modulo grupo (vms con doble):', () {
    test('$capa - $tipo - Listar instructores - 200 carga la lista', () async {
      final conexion = ConexioninstructoresFalsa();
      conexion.respuestaInstructores = RespuestaModelo(
        codigoHttp: 200,
        datos: [Instructormodelo(id: 'ins1', nombre: 'Luis')],
      );
      final vm = InstructoresViewModel(
        ServicioInstructor(Instructoresrepositorio(conexion: conexion)),
      );

      await vm.listarYNotificarInstructores();

      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.instructores.map((i) => i.id), ['ins1']);
    });

    test('$capa - $tipo - Insertar grupo - 201 sin recargar la lista', () async {
      final conexion = ConexiongruposFalsa();
      conexion.respuestaInsertar = RespuestaModelo(codigoHttp: 201);
      final vm = Gruposviewmodel(
        Serviciogrupo(Gruporepositorio(conexion: conexion)),
      );

      final respuesta = await vm.insertarGrupo(
        Grupoentidad(
          categoria: 'Deportes',
          curso: 'Iniciacion',
          anio: 2026,
          iterable: 0,
          idInstructor: 'ins1',
          cupos: 20,
          fechaCreacion: '2026-10-23',
        ),
      );

      expect(respuesta.codigoHttp, 201);
      expect(conexion.ultimoInsertado?.idInstructor, 'ins1');
      //el formulario tiene su propio vm: la lista la recarga la pantalla
      //del curso al volver, no este insert
      expect(conexion.llamadasGruposDe, 0);
    });

    test('$capa - $tipo - Url de imagen de grupo - la arma la conexion', () {
      final vm = Gruposviewmodel(
        Serviciogrupo(Gruporepositorio(conexion: ConexiongruposFalsa())),
      );

      //la vista ya no conoce el servidor: la url baja desde la conexion
      expect(vm.urlImagen(5), 'http://falso/imagenStream?idImagen=5');
    });

    test('$capa - $tipo - Registrar clase - 201 refresca la lista del vm', () async {
      final conexion = ConexionclasesFalsa();
      conexion.respuestaAgregar = RespuestaModelo(codigoHttp: 201);
      conexion.respuestaClases = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Clasemodelo(
            codigo: 9,
            idGrupoCategoria: 'Deportes',
            idGrupoCurso: 'Iniciacion',
            idGrupoAnio: 2026,
            idGrupoIterable: 1,
            idInstructor: 'ins1',
            fecha: DateTime(2026, 10, 22),
            horas: 2,
            minutos: 0,
            eliminado: 0,
          ),
        ],
      );
      final vm = Clasesviewmodel(
        Servicioclase(Claserepositorio(cliente: conexion)),
      );
      //como lo hace la ruta formularioClase con el grupo que recibe
      vm.inicializarGrupo('Deportes', 'Iniciacion', 2026, 1, 'ins1');

      final resultado = await vm.registrarClase(
        fecha: DateTime(2026, 10, 22),
        horasTexto: '2',
      );

      expect(resultado, isA<Exito>());
      //la clase se arma con el grupo inicializado
      expect(conexion.ultimaAgregada?.idGrupoIterable, 1);
      expect(conexion.ultimaAgregada?.idInstructor, 'ins1');
      expect(conexion.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(vm.clases.map((c) => c.codigo), [9]);
    });
  });
}
