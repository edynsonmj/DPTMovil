class ErrorModelo{
  final int codigoHttp;
  final String mensaje;
  final String url;
  final String metodo;

  ErrorModelo({
    required this.codigoHttp,
    required this.mensaje,
    required this.url,
    required this.metodo
  });
}