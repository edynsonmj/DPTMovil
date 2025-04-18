import 'package:dpt_movil/data/api/conexion/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:flutter/material.dart';

class ConexionEstadisticasLocal extends ConexionEstadisticas {
  Future<RespuestaModelo> generalCategorias() async {
    double horas = 0;
    double atenciones = 0;
    _dataSemillero.forEach((valor) {
      horas += valor.horas;
      atenciones += valor.atenciones;
    });
    EstadisticaModelo semillero = EstadisticaModelo(
      etiqueta: 'Semillero',
      atenciones: atenciones,
      horas: horas,
    );

    horas = 0;
    atenciones = 0;
    _dataAtencionesFormativo.forEach((valor) {
      horas += valor.horas;
      atenciones += valor.atenciones;
    });
    EstadisticaModelo formativo = EstadisticaModelo(
      etiqueta: 'Formativo',
      atenciones: atenciones,
      horas: horas,
    );

    horas = 0;
    atenciones = 0;
    _dataAtencionesSeleccionado.forEach((valor) {
      horas += valor.horas;
      atenciones += valor.atenciones;
    });
    EstadisticaModelo seleccionado = EstadisticaModelo(
      etiqueta: 'Seleccionado',
      atenciones: atenciones,
      horas: horas,
    );

    List<EstadisticaModelo> estadisticas = [semillero, formativo, seleccionado];
    return await Future.value(
      RespuestaModelo(codigoHttp: 200, datos: estadisticas),
    );
  }

  @override
  Future<RespuestaModelo> generalCursos(String categoria) async {
    RespuestaModelo respuesta;
    switch (categoria) {
      case 'Semillero':
        respuesta = RespuestaModelo(codigoHttp: 200, datos: _dataSemillero);
        break;
      case 'Formativo':
        respuesta = RespuestaModelo(
          codigoHttp: 200,
          datos: _dataAtencionesFormativo,
        );
        break;
      case 'Seleccionado':
        respuesta = RespuestaModelo(
          codigoHttp: 200,
          datos: _dataAtencionesSeleccionado,
        );
        break;
      default:
        respuesta = RespuestaModelo(
          codigoHttp: 404,
          error: ErrorModelo(
            codigoHttp: 404,
            mensaje:
                'La categoria especificada no se encuentra en los registros',
            url: 'estadisticas/general/cursos',
            metodo: 'GET',
          ),
        );
        break;
    }
    return await Future.value(respuesta);
  }

  @override
  Future<RespuestaModelo> generalGrupos(String categoria, String curso) {
    // TODO: implement generalGrupos
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> institucionalFacultades() {
    // TODO: implement institucionalFacultades
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> institucionalProgramas(String facultad) {
    // TODO: implement institucionalProgramas
    throw UnimplementedError();
  }

  final List<EstadisticaModelo> _dataSemillero = [
    // Atenciones para los grupos de Fútbol Base (Semillero)
    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 1',
      atenciones: 10,
      horas: 15,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 1',
      atenciones: 8,
      horas: 12,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 1',
      atenciones: 12,
      horas: 18,
    ),

    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 2',
      atenciones: 14,
      horas: 20,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 2',
      atenciones: 11,
      horas: 17,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 2',
      atenciones: 9,
      horas: 14,
    ),

    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 3',
      atenciones: 7,
      horas: 10,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 3',
      atenciones: 6,
      horas: 9,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Fútbol Base - 2025 - 3',
      atenciones: 8,
      horas: 12,
    ),

    // Atenciones para los grupos de Natación Infantil (Semillero)
    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 1',
      atenciones: 5,
      horas: 8,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 1',
      atenciones: 6,
      horas: 10,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 1',
      atenciones: 7,
      horas: 12,
    ),

    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 2',
      atenciones: 8,
      horas: 13,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 2',
      atenciones: 9,
      horas: 15,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 2',
      atenciones: 10,
      horas: 18,
    ),

    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 3',
      atenciones: 6,
      horas: 9,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 3',
      atenciones: 5,
      horas: 8,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Natación Infantil - 2025 - 3',
      atenciones: 7,
      horas: 10,
    ),

    // Atenciones para Béisbol Juvenil (Semillero)
    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 1',
      atenciones: 4,
      horas: 6,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 1',
      atenciones: 3,
      horas: 5,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 1',
      atenciones: 5,
      horas: 7,
    ),

    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 2',
      atenciones: 6,
      horas: 8,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 2',
      atenciones: 7,
      horas: 10,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 2',
      atenciones: 8,
      horas: 12,
    ),

    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 3',
      atenciones: 5,
      horas: 7,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 3',
      atenciones: 6,
      horas: 9,
    ),
    EstadisticaModelo(
      etiqueta: 'Semillero - Béisbol Juvenil - 2025 - 3',
      atenciones: 7,
      horas: 10,
    ),

    // Se continuarían con los demás grupos, siguiendo la misma lógica...
  ];

  final List<EstadisticaModelo> _dataAtencionesSeleccionado = [
    // Atenciones para los grupos de Fútbol Competitivo (Seleccionado)
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 1',
      atenciones: 15,
      horas: 20,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 1',
      atenciones: 12,
      horas: 18,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 1',
      atenciones: 17,
      horas: 25,
    ),

    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 2',
      atenciones: 20,
      horas: 28,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 2',
      atenciones: 18,
      horas: 26,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 2',
      atenciones: 22,
      horas: 30,
    ),

    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 3',
      atenciones: 14,
      horas: 22,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 3',
      atenciones: 16,
      horas: 24,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Fútbol Competitivo - 2025 - 3',
      atenciones: 19,
      horas: 27,
    ),

    // Atenciones para los grupos de Natación Profesional (Seleccionado)
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 1',
      atenciones: 10,
      horas: 15,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 1',
      atenciones: 12,
      horas: 17,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 1',
      atenciones: 14,
      horas: 19,
    ),

    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 2',
      atenciones: 9,
      horas: 14,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 2',
      atenciones: 11,
      horas: 16,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 2',
      atenciones: 13,
      horas: 18,
    ),

    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 3',
      atenciones: 15,
      horas: 21,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 3',
      atenciones: 16,
      horas: 23,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Natación Profesional - 2025 - 3',
      atenciones: 18,
      horas: 25,
    ),

    // Atenciones para los grupos de Béisbol Avanzado (Seleccionado)
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 1',
      atenciones: 7,
      horas: 10,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 1',
      atenciones: 8,
      horas: 12,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 1',
      atenciones: 10,
      horas: 14,
    ),

    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 2',
      atenciones: 5,
      horas: 8,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 2',
      atenciones: 6,
      horas: 9,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 2',
      atenciones: 9,
      horas: 11,
    ),

    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 3',
      atenciones: 8,
      horas: 11,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 3',
      atenciones: 9,
      horas: 13,
    ),
    EstadisticaModelo(
      etiqueta: 'Seleccionado - Béisbol Avanzado - 2025 - 3',
      atenciones: 11,
      horas: 15,
    ),
  ];

  final List<EstadisticaModelo> _dataAtencionesFormativo = [
    // Atenciones para los grupos de Técnica de Fútbol (Formativo)
    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 1',
      atenciones: 14,
      horas: 18,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 1',
      atenciones: 16,
      horas: 20,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 1',
      atenciones: 18,
      horas: 22,
    ),

    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 2',
      atenciones: 12,
      horas: 16,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 2',
      atenciones: 14,
      horas: 18,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 2',
      atenciones: 15,
      horas: 20,
    ),

    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 3',
      atenciones: 13,
      horas: 17,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 3',
      atenciones: 14,
      horas: 19,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Técnica de Fútbol - 2025 - 3',
      atenciones: 16,
      horas: 21,
    ),

    // Atenciones para los grupos de Natación para Adultos (Formativo)
    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 1',
      atenciones: 8,
      horas: 12,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 1',
      atenciones: 9,
      horas: 14,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 1',
      atenciones: 10,
      horas: 16,
    ),

    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 2',
      atenciones: 10,
      horas: 15,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 2',
      atenciones: 11,
      horas: 16,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 2',
      atenciones: 12,
      horas: 18,
    ),

    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 3',
      atenciones: 9,
      horas: 13,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 3',
      atenciones: 10,
      horas: 15,
    ),
    EstadisticaModelo(
      etiqueta: 'Formativo - Natación para Adultos - 2025 - 3',
      atenciones: 11,
      horas: 17,
    ),
  ];
}
