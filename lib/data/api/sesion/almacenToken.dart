//JWT propio del backend (dpt_token) de la sesion actual. Lo escribe el
//repositorio de autenticacion al intercambiar el ID Token de Google en
///auth/token y lo lee InterceptorToken en cada peticion. Vive solo en
//memoria: al abrir la app, verificarSesion vuelve a pedirlo con Google
class AlmacenToken {
  String? token;

  bool get hayToken => token != null && token!.isNotEmpty;

  void borrar() {
    token = null;
  }
}
