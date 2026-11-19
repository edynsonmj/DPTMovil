import 'package:dpt_movil/domain/entities/diaSemana.dart';
import 'package:flutter_test/flutter_test.dart';

//HO-06: el backend nombra los dias LUNES..DOMINGO, sin tilde, y los compara
//con equalsIgnoreCase. La app envia el codigo y muestra la etiqueta
void main() {
  const String capa = "dominio";
  const String tipo = "unitaria";

  group('Dias de la semana (HO-06):', () {
    test('$capa - $tipo - codigo - cualquier forma de escribir el dia da el codigo del backend', () {
      expect(DiaSemana.codigo('Miércoles'), 'MIERCOLES');
      expect(DiaSemana.codigo(' sábado '), 'SABADO');
      expect(DiaSemana.codigo('LUNES'), 'LUNES');
      expect(DiaSemana.codigo('Xyz'), isNull);
      expect(DiaSemana.codigo(''), isNull);
    });

    test('$capa - $tipo - etiqueta - el codigo y los dias viejos con tilde se muestran con tilde', () {
      expect(DiaSemana.etiqueta('MIERCOLES'), 'Miércoles');
      expect(DiaSemana.etiqueta('Miércoles'), 'Miércoles');
      expect(DiaSemana.etiqueta('SABADO'), 'Sábado');
      expect(DiaSemana.etiqueta('Xyz'), 'Xyz');
    });

    test('$capa - $tipo - numero - sigue la regla del backend: mayusculas da igual, la tilde no', () {
      expect(DiaSemana.numero('LUNES'), DateTime.monday);
      expect(DiaSemana.numero('miercoles'), DateTime.wednesday);
      expect(DiaSemana.numero('DOMINGO'), DateTime.sunday);
      expect(DiaSemana.numero('Miércoles'), isNull);
      expect(DiaSemana.numero('Sábado'), isNull);
    });

    test('$capa - $tipo - codigos - en el orden de DateTime.weekday', () {
      for (var i = 0; i < DiaSemana.codigos.length; i++) {
        expect(DiaSemana.numero(DiaSemana.codigos[i]), i + 1);
      }
    });
  });
}
