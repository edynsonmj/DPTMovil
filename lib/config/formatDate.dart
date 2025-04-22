class FormatDate {
  static String fechaACadena(DateTime fecha, String separador) {
    if (fecha == null || separador == null) {
      return '';
    }
    return '${fecha.year}-${fecha.month}-${fecha.day}';
  }
}
