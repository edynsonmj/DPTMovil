import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

//doble del selector de imagenes del sistema (image_picker). Se instala con
//ImagePickerPlatform.instance = SelectorImagenFalso(ruta) antes de montar la
//pantalla: ImagePicker().pickImage(...) devuelve el archivo de [ruta] sin
//abrir la galeria. [ruta] null simula que el usuario cancela
class SelectorImagenFalso extends ImagePickerPlatform {
  final String? ruta;
  int llamadas = 0;

  SelectorImagenFalso(this.ruta);

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    llamadas++;
    return ruta == null ? null : XFile(ruta!);
  }
}
