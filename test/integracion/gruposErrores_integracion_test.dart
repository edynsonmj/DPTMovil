
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//diagnostico de grupos de punta a punta sin backend (plan-diagnostico-
//grupos.md): el mismo montaje que test/integracion/grupos_integracion_test.dart.
//Afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late Gruporepositorio repositorio;
  late Gruposviewmodel vm;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    repositorio = Gruporepositorio(
      conexion: Conexiongruposremoto(crearDioFalso(adaptador)),
    );
    vm = Gruposviewmodel(Serviciogrupo(repositorio));
  });

  group('Grupos (errores de punta a punta):', () {
    //el "&" corta el valor en la query: el backend recibe otra categoria
    test('$capa - $tipo - Listar grupos de - categoria y curso llegan completos a la query', () async {
      adaptador.responder('GET', '/gruposCurso', 200, []);

      await vm.listarGruposDe('Fútbol & Voleibol', 'Nivel 1 + 2');

      final query =
          adaptador.peticionesA('GET', '/gruposCurso').single.uri.queryParameters;
      expect(query['prmCategoria'], 'Fútbol & Voleibol');
      expect(query['prmCurso'], 'Nivel 1 + 2');
    });

    //un grupo sin "cupos": GrupoModelo.fromJson lanza un TypeError y las tres
    //listas solo capturan Exception (/gruposNoEliminados si lo captura)
    test('$capa - $tipo - Listar grupos (curso e instructor) - un grupo incompleto vuelve como error de la conexion, sin lanzar', () async {
      final incompleto = Map<String, dynamic>.from(
        (leerContrato('inscripciones', 'gruposNoEliminados_200') as List).first,
      )..remove('cupos');
      adaptador.responder('GET', '/gruposCurso', 200, [incompleto]);
      adaptador.responder('GET', '/gruposInstructor', 200, [incompleto]);

      for (final pedir in <Future<dynamic> Function()>[
        () => repositorio.listarGruposDe('Categoria Fase 4', 'Curso Categoria Fase 4'),
        () => repositorio.listarGruposInstructores('2'),
      ]) {
        Object? lanzado;
        dynamic respuesta;
        try {
          respuesta = await pedir();
        } catch (e) {
          lanzado = e;
        }
        expect(lanzado, isNull, reason: 'lanzo: $lanzado');
        expect(respuesta.codigoHttp, isNot(200));
      }
    });
    //GR-02 (corregido) paso a test/integracion/grupos_integracion_test.dart
  });
}
