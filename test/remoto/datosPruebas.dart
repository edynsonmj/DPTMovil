import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/config/formatDate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'jwtPruebas.dart';

//datos que el backend nuevo exige para sembrar la suite remota. Solo pruebas:
//lo que falte en la app queda como hallazgo, no se esconde aqui

const String _baseUrl = 'http://localhost:8082/api/v2';

//POST /grupo responde 422 GC-0015 sin fecha de cierre de inscripciones
String cierreInscripcionPruebas() => FormatDate.fechaACadena(
  DateTime.now().add(const Duration(days: 30)),
  '-',
);

//con cierre y sin apertura el grupo nace abierto. Con esta apertura nace
//cerrado, como antes, y abrirInscripcionesPruebas lo abre cuando toca
String aperturaFuturaPruebas() => FormatDate.fechaACadena(
  DateTime.now().add(const Duration(days: 10)),
  '-',
);

//POST /RegistroPerfilAlumno pide datos segun tipoAlumno: Estudiante, codigo +
//facultad + programa; Docente, facultad + programa; Administrativo o
//Contratista, dependencia. Sin ellos responde 422 GC-0029. Toca la misma
//entidad, porque varias pruebas la comparan despues con lo que devuelve el
//backend
Future<PerfilEntidad> completarRegistro(PerfilEntidad perfil) async {
  if (perfil.tipoAlumno == 'Estudiante' || perfil.tipoAlumno == 'Docente') {
    final respuesta = await crearDioPruebas(_baseUrl).get(
      '/programas',
      queryParameters: {'facultad': perfil.facultad},
    );
    perfil.programa = (respuesta.data as List).first['nombre'] as String;
    if (perfil.tipoAlumno == 'Estudiante') {
      perfil.alumnoCodigo = perfil.id;
    }
  } else {
    perfil.dependencia = 'Dependencia prueba';
  }
  return perfil;
}

//abre las inscripciones directo por la ruta: VmPeriodoInscripcionTest prueba
//el camino de la app y las siembras de otros modulos no dependen de el
Future<void> abrirInscripcionesPruebas(Grupoentidad g) async {
  final r = await crearDioPruebas(_baseUrl).patch(
    '/grupo/periodo',
    data: {
      'fechaApertura': FormatDate.fechaACadena(DateTime.now(), '-'),
      'fechaCierre': cierreInscripcionPruebas(),
      'grupos': [
        {
          'categoria': g.categoria,
          'curso': g.curso,
          'anio': g.anio,
          'iterable': g.iterable,
        },
      ],
    },
  );
  expect(r.statusCode, 200, reason: 'no se abrio el grupo');
}

//POST /claseGrupo responde 422 GC-0021 si el grupo no tiene horario ese dia:
//una franja de 2 h por dia deja registrar clases en cualquier fecha
Future<void> sembrarHorariosSemana(Grupoentidad g) async {
  final dio = crearDioPruebas(_baseUrl);
  for (final dia in const [
    'LUNES',
    'MARTES',
    'MIERCOLES',
    'JUEVES',
    'VIERNES',
    'SABADO',
    'DOMINGO',
  ]) {
    final r = await dio.post(
      '/horario',
      data: {
        'categoria': g.categoria,
        'curso': g.curso,
        'anio': g.anio,
        'iterable': g.iterable,
        'dia': dia,
        'horaInicio': '08:00',
        'horaFin': '10:00',
        'escenario': 'Escenario prueba',
      },
    );
    expect(r.statusCode, 201, reason: 'no se creo el horario $dia');
  }
}

//id del perfil creado o el del perfil enviado: para firmar su token
String idDeRegistro(RespuestaModelo respuesta, PerfilEntidad perfil) =>
    (respuesta.datos is PerfilEntidad)
        ? (respuesta.datos as PerfilEntidad).id
        : perfil.id;
