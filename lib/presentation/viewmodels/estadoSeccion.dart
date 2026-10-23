import 'package:flutter/foundation.dart';

//estado de una seccion de la pantalla (o de un grupo dentro de una lista).
//Inmutable: cada cambio crea uno nuevo, asi context.select detecta el cambio
//y solo reconstruye lo que depende de el. Antes vivia en
//detalleGrupoViewModel.dart (fase 4c); desde la fase 6c lo usan tambien
//Horariosviewmodel e Inscripcionviewmodel
class EstadoSeccion<T> {
  final T datos;
  final bool cargando;
  final String? error;

  const EstadoSeccion(this.datos, {this.cargando = false, this.error});
}

//un vm creado por la ruta se desecha al salir; una peticion que llega
//despues no debe notificar (ChangeNotifier lanza si se usa tras dispose)
mixin NotificacionSegura on ChangeNotifier {
  bool _desechado = false;

  @override
  void dispose() {
    _desechado = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_desechado) super.notifyListeners();
  }
}
