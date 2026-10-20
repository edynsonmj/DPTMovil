//resultado de una operacion tal como lo consume la vista: exito o fallo, sin
//codigos http que interpretar ni modelos de la capa de datos
sealed class Resultado<T> {}

class Exito<T> extends Resultado<T> {
  final T? datos;
  Exito([this.datos]);
}

class Fallo<T> extends Resultado<T> {
  final int codigo;
  final String mensaje;
  //metodo y url de la peticion que fallo, solo para diagnostico
  final String? origen;
  Fallo(this.codigo, this.mensaje, {this.origen});
}
