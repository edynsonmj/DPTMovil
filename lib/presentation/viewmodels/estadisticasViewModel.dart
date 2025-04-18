import 'package:flutter/material.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';

class EstadisticasViewModel with ChangeNotifier {
  //DEFINICIONES
  //definicion del servicio
  final ServicioEstadisticas _servicioEstadisticas;
  //paquetes estadisticos
  List<Estadistica> _listEstadisticasGeneralesCategorias = [];
  List<Estadistica> _listEstadisticasGeneralesCursos = [];
  //
  List<DropdownMenuEntry> _listCategorias = [];

  //constructor que instancia el servicio usado por el viewModel
  EstadisticasViewModel() : _servicioEstadisticas = ServicioEstadisticas();

  //CARGAR DATOS
  Future<void> cargarGeneralCategorias(context) async {
    try {
      RespuestaModelo respuesta =
          await _servicioEstadisticas.generalesCategorias();
      _listEstadisticasGeneralesCategorias = _manejarRepuestaEstadistica(
        context,
        respuesta,
      );
      _cargarCategorias();
    } catch (e) {
      mostrarError(context, 'Excepcion no controlada', e.toString(), 0);
    } finally {
      notifyListeners();
    }
  }

  Future<void> cargarCursosGenerales(context, String categoria) async {
    try {
      RespuestaModelo respuesta = await _servicioEstadisticas.generalesGrupos(
        categoria,
      );
      _listEstadisticasGeneralesCursos = _manejarRepuestaEstadistica(
        context,
        respuesta,
      );
      //TODO: cargar grupos
      //_cargarCategorias();
    } catch (e) {
      mostrarError(context, 'Excepcion no controlada', e.toString(), 0);
    } finally {
      notifyListeners();
    }
  }

  List<Estadistica> _manejarRepuestaEstadistica(
    context,
    RespuestaModelo respuesta,
  ) {
    switch (respuesta.codigoHttp) {
      case 200:
        //caso exitoso, retorno los datos
        if (respuesta.datos is List<Estadistica>) {
          //datos obtenidos fijar en lista
          return respuesta.datos as List<Estadistica>;
        }
        //fallo en datos
        mostrarError(
          context,
          'Datos inconsistentes',
          'El formato de los datos recibidos no es el esperado',
          0,
        );
        return [];
      case 204:
        mostrarError(
          context,
          'Operacion exitosa, pero...',
          "No hay informacion",
          0,
        );
        return [];
      default:
        mostrarError(
          context,
          'Informacion no recibida',
          respuesta.error?.mensaje ?? 'no hay informacion respecto al error',
          respuesta.codigoHttp,
        );
        return [];
    }
  }

  //CARGAR LISTA DE CATEGORIAS
  void _cargarCategorias() {
    _listEstadisticasGeneralesCategorias.forEach((estadistica) {
      print("entrada: ${estadistica.etiqueta}");
      DropdownMenuEntry entry = DropdownMenuEntry(
        value: estadistica.etiqueta,
        label: estadistica.etiqueta,
      );
      _listCategorias.add(entry);
    });
    print("finalizado");
  }

  //GETTERS
  List<Estadistica> get getListEstadisticasGeneralCategorias =>
      _listEstadisticasGeneralesCategorias;

  List<Estadistica> get getListEstadisticasGeneralCursos =>
      _listEstadisticasGeneralesCursos;

  List<DropdownMenuEntry> get getListCategorias => _listCategorias;
  //MOSTRAR ERROR
  mostrarError(context, String titulo, String mensaje, int codigo) {
    showDialog(
      context: context,
      builder: (context) {
        return DialogError(titulo: titulo, mensaje: mensaje, codigo: codigo);
      },
    );
  }
}
