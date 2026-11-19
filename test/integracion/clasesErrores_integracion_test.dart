
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAlumnosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//diagnostico de clases de punta a punta sin backend (plan-diagnostico-
//clases.md): el mismo montaje que test/integracion/clases_integracion_test.dart.
//Afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;

  DetalleGrupoViewModel pantallaGrupo(Grupoentidad grupo) {
    final dio = crearDioFalso(adaptador);
    return DetalleGrupoViewModel(
      grupo,
      ServicioCurso(CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)))),
      Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
      Servicioalumno(Alumnosrepositorio(cliente: Conexionalumnosremoto(dio))),
      Servicioclase(Claserepositorio(cliente: Conexionclasesremoto(dio))),
    );
  }

  Grupoentidad grupo(String categoria, String curso) => Grupoentidad(
    categoria: categoria,
    curso: curso,
    anio: 2026,
    iterable: 1,
    cupos: 10,
    fechaCreacion: '2026-10-22',
  );

  setUp(() => adaptador = AdaptadorHttpFalso());

  group('Clases (errores de punta a punta):', () {
    //una clase sin fecha: DateTime.parse(null) en fromJson lanza un TypeError
    //que atraviesa la conexion (solo captura Exception) y el repositorio (la
    //llamada a la conexion esta fuera de su try)
    test('$capa - $tipo - Cargar clases - una clase incompleta llega como error con codigo, no como excepcion', () async {
      final incompleta = Map<String, dynamic>.from(
        (leerContrato('clases', 'clasesGrupo_200') as List).first,
      )..['fecha'] = null;
      adaptador.responder('GET', '/clasesGrupo', 200, [incompleta]);
      final vm = pantallaGrupo(grupo('Categoria Fase 4', 'Curso Categoria Fase 4'));

      await vm.cargarClases();

      expect(vm.clases.error, isNotNull);
      //formato del vm para una RespuestaModelo con error: "Código: N - ..."
      expect(vm.clases.error, startsWith('Código: '));
    });

    //GR-05 en la conexion de clases: el mismo defecto, sin ID nuevo
    test('$capa - $tipo - Cargar clases - categoria y curso llegan completos a la query de /clasesGrupo', () async {
      adaptador.responder('GET', '/clasesGrupo', 200, []);
      final vm = pantallaGrupo(grupo('Fútbol & Voleibol', 'Nivel 1 + 2'));

      await vm.cargarClases();

      final query =
          adaptador.peticionesA('GET', '/clasesGrupo').single.uri.queryParameters;
      expect([query['categoria'], query['curso']], ['Fútbol & Voleibol', 'Nivel 1 + 2']);
    });
  });
}
