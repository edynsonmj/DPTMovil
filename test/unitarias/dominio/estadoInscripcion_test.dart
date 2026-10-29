import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//estado de inscripcion de un grupo (plan de abrir inscripciones, fase 3).
//La regla es la que se observo en el backend: aparece en /gruposInscripcion
//si apertura <= hoy y (sin cierre o cierre >= hoy)
void main() {
  const String capa = "dominio";
  const String tipo = "unitaria";

  final hoy = DateTime(2026, 10, 29);

  Grupoentidad grupo(String? apertura, String? cierre) => Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    cupos: 20,
    fechaCreacion: '2026-10-01',
    fechaInscripcionApertura: apertura,
    fechaInscripcionCierre: cierre,
  );

  group('Estado de inscripcion de un grupo:', () {
    test('$capa - $tipo - Estado inscripcion - los grupos del contrato el dia de la captura', () {
      //gruposNoEliminados_200.json se capturo el 2026-10-29
      final estados =
          (leerContrato('inscripciones', 'gruposNoEliminados_200') as List)
              .map((json) => Grupoentidad.fromModelo(GrupoModelo.fromJson(json)))
              .map((g) => g.estadoInscripcion(hoy))
              .toList();

      expect(estados, [
        EstadoInscripcion.abierta,
        EstadoInscripcion.sinPeriodo,
        EstadoInscripcion.cerrada,
      ]);
    });

    test('$capa - $tipo - Estado inscripcion - sin apertura nunca se abrio', () {
      expect(grupo(null, null).estadoInscripcion(hoy), EstadoInscripcion.sinPeriodo);
      expect(
        grupo('no-es-fecha', null).estadoInscripcion(hoy),
        EstadoInscripcion.sinPeriodo,
      );
    });

    test('$capa - $tipo - Estado inscripcion - apertura futura esta programada', () {
      expect(
        grupo('2026-10-30', '2026-11-30').estadoInscripcion(hoy),
        EstadoInscripcion.programada,
      );
    });

    test('$capa - $tipo - Estado inscripcion - abierta desde hoy, con o sin cierre', () {
      expect(grupo('2026-10-29', null).estadoInscripcion(hoy), EstadoInscripcion.abierta);
      expect(
        grupo('2026-10-01', '2026-11-30').estadoInscripcion(hoy),
        EstadoInscripcion.abierta,
      );
    });

    test('$capa - $tipo - Estado inscripcion - el dia del cierre aun esta abierta', () {
      //inferido de que "cerrar" deja el cierre en ayer; se confirma contra
      //el backend en la fase 5
      expect(
        grupo('2026-10-01', '2026-10-29').estadoInscripcion(hoy),
        EstadoInscripcion.abierta,
      );
    });

    test('$capa - $tipo - Estado inscripcion - con el cierre en el pasado esta cerrada', () {
      //lo que deja "cerrar" (cerrar_200.json): apertura = cierre = ayer
      expect(
        grupo('2026-10-28', '2026-10-28').estadoInscripcion(hoy),
        EstadoInscripcion.cerrada,
      );
    });

    test('$capa - $tipo - Estado inscripcion - la hora del dia no cambia el estado', () {
      final ultimoMinuto = DateTime(2026, 10, 29, 23, 59);
      expect(
        grupo('2026-10-29', '2026-10-29').estadoInscripcion(ultimoMinuto),
        EstadoInscripcion.abierta,
      );
      expect(
        grupo('2026-10-30', null).estadoInscripcion(ultimoMinuto),
        EstadoInscripcion.programada,
      );
    });
  });
}
