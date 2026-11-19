//dias de la semana de los horarios. El backend los nombra LUNES..DOMINGO, sin
//tilde, y los compara con equalsIgnoreCase (CalculadoraDuracionClase): un
//horario guardado como 'Miércoles' no cuenta como horario del miercoles
//(HO-06). La app envia siempre el codigo y muestra la etiqueta
class DiaSemana {
  DiaSemana._();

  //en el orden de DateTime.weekday (lunes = 1)
  static const List<String> codigos = [
    'LUNES',
    'MARTES',
    'MIERCOLES',
    'JUEVES',
    'VIERNES',
    'SABADO',
    'DOMINGO',
  ];

  static const Map<String, String> _etiquetas = {
    'LUNES': 'Lunes',
    'MARTES': 'Martes',
    'MIERCOLES': 'Miércoles',
    'JUEVES': 'Jueves',
    'VIERNES': 'Viernes',
    'SABADO': 'Sábado',
    'DOMINGO': 'Domingo',
  };

  //codigo del backend para un dia escrito de cualquier forma ('Miércoles',
  //'miercoles', 'MIERCOLES'); null si no es un dia
  static String? codigo(String dia) {
    const sinTilde = {'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U'};
    final normal =
        dia.trim().toUpperCase().split('').map((c) => sinTilde[c] ?? c).join();
    return codigos.contains(normal) ? normal : null;
  }

  //como se muestra. Un dia que no se reconoce se muestra tal cual llego
  static String etiqueta(String dia) => _etiquetas[codigo(dia)] ?? dia;

  //DateTime.weekday del dia segun la regla del backend: solo cuenta el codigo
  //sin tilde (mayusculas o minusculas da igual). Un horario viejo guardado
  //con tilde devuelve null, porque el backend tampoco lo cuenta
  static int? numero(String dia) {
    final i = codigos.indexOf(dia.toUpperCase());
    return i < 0 ? null : i + 1;
  }
}
