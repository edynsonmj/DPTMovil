import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ConvertFile {
  static Future<File> uInt8ListToFile(Uint8List datos, String nombreArchivo) async{
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$nombreArchivo');
    await file.writeAsBytes(datos);
    return file;
  }
}
