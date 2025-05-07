import 'dart:io';
import 'package:excel/excel.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:dpt_movil/domain/entities/estadistica.dart';

class ExcelExport {
  Excel excel = Excel.createExcel();

  Sheet llenarHoja(String nombreHoja, List<Estadistica> datos) {
    final sheet = excel[nombreHoja];

    // Encabezados
    sheet.appendRow([
      TextCellValue('Leyenda1'),
      TextCellValue('Leyenda2'),
      TextCellValue('Leyenda3'),
      TextCellValue('Leyenda4'),
      TextCellValue('Clases'),
      TextCellValue('Horas'),
      TextCellValue('Minutos'),
      TextCellValue('Duración'),
    ]);

    // Filas de datos
    for (var item in datos) {
      sheet.appendRow([
        TextCellValue(item.leyenda1),
        TextCellValue(item.leyenda2 ?? ''),
        TextCellValue(item.leyenda3 ?? ''),
        TextCellValue(item.leyenda4 ?? ''),
        DoubleCellValue(item.clases),
        DoubleCellValue(item.horas),
        DoubleCellValue(item.minutos),
        DoubleCellValue(item.duracion),
      ]);
    }
    return sheet;
  }

  Future<File> exportarEstadisticasAExcel() async {
    // Eliminar hoja por defecto si aún existe y no la usamos
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Guardar archivo en carpeta temporal
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/estadisticas.xlsx';
    final fileBytes = excel.save();

    final file = File(filePath);
    file.writeAsBytesSync(fileBytes!);
    return file;
  }

  Future<bool> guardarArchivoExcel(File archivoExcel) async {
    if (await Permission.storage.request().isGranted) {
      final directorio = Directory('/storage/emulated/0/Download');

      if (await directorio.exists()) {
        // Obtener fecha actual y formatearla
        String fecha = DateTime.now().toString();
        String ruta = '${directorio.path}/reporte_$fecha.xlsx';

        await archivoExcel.copy(ruta);
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
}
