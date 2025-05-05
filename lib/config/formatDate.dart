class FormatDate {
  static String fechaACadena(DateTime fecha, String separador) {
    if (fecha == null || separador == null) {
      return '';
    }
    final year = fecha.year.toString();
    final month = fecha.month.toString().padLeft(2, '0'); // asegura dos dígitos
    final day = fecha.day.toString().padLeft(2, '0'); // asegura dos dígitos
    return '$year$separador$month$separador$day';
  }
}
