import 'dart:io';

import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:dpt_movil/domain/excel.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

class EstadisticasViewModel with ChangeNotifier, NotificacionSegura {
  final ServicioEstadisticas _servicioEstadisticas;

  //el servicio llega de la raiz; el vm lo crea la ruta estadisticasGenerales
  EstadisticasViewModel(this._servicioEstadisticas);

  static const EstadoSeccion<List<Estadistica>> _sinDatos = EstadoSeccion(
    <Estadistica>[],
  );
  static const EstadoSeccion<List<Estadistica>> _cargando = EstadoSeccion(
    <Estadistica>[],
    cargando: true,
  );

  //rango elegido (fase 7c): null mientras no se asigne
  String? _inicio;
  String? _fin;

  //una seccion por grafica; cada una se pide una vez por rango
  EstadoSeccion<List<Estadistica>> _categorias = _sinDatos;
  EstadoSeccion<List<Estadistica>> _cursos = _sinDatos;
  EstadoSeccion<List<Estadistica>> _grupos = _sinDatos;

  //identifica la ultima carga: lo que llegue de un rango anterior se descarta
  int _peticion = 0;

  //pide las tres secciones en paralelo; cada una notifica al llegar
  Future<void> cargar(String inicio, String fin) async {
    final peticion = ++_peticion;
    _inicio = inicio;
    _fin = fin;
    _categorias = _cargando;
    _cursos = _cargando;
    _grupos = _cargando;
    notifyListeners();
    await Future.wait([
      _cargarSeccion(
        peticion,
        () => _servicioEstadisticas.generalesCategorias(inicio, fin),
        (estado) => _categorias = estado,
      ),
      _cargarSeccion(
        peticion,
        () => _servicioEstadisticas.generalesCursos(inicio, fin),
        (estado) => _cursos = estado,
      ),
      _cargarSeccion(
        peticion,
        () => _servicioEstadisticas.generalesGrupos(inicio, fin),
        (estado) => _grupos = estado,
      ),
    ]);
  }

  //lo que hace "Cancelar" en el dialogo de fechas
  void limpiar() {
    _peticion++;
    _inicio = null;
    _fin = null;
    _categorias = _sinDatos;
    _cursos = _sinDatos;
    _grupos = _sinDatos;
    notifyListeners();
  }

  Future<void> _cargarSeccion(
    int peticion,
    Future<RespuestaModelo> Function() pedir,
    void Function(EstadoSeccion<List<Estadistica>>) fijar,
  ) async {
    EstadoSeccion<List<Estadistica>> estado;
    try {
      final respuesta = await pedir();
      //un error deja la seccion con su mensaje, no rompe la pantalla
      estado =
          (respuesta.codigoHttp == 200 && respuesta.datos is List<Estadistica>)
              ? EstadoSeccion(
                _ordenarPorHoras(respuesta.datos as List<Estadistica>),
              )
              : EstadoSeccion(
                <Estadistica>[],
                error:
                    'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}',
              );
    } catch (e) {
      estado = EstadoSeccion(<Estadistica>[], error: e.toString());
    }
    if (peticion != _peticion) return;
    fijar(estado);
    notifyListeners();
  }

  //una copia ordenada una sola vez: la vista ya no ordena en build
  List<Estadistica> _ordenarPorHoras(List<Estadistica> lista) =>
      [...lista]..sort((a, b) => b.horas.compareTo(a.horas));

  //el boton de descarga exporta la seccion de grupos
  bool get puedeExportar => !_grupos.cargando && _grupos.datos.isNotEmpty;

  Future<bool> export() async {
    if (!puedeExportar) return false;
    ExcelExport export = ExcelExport();
    export.llenarHoja('prueba', _grupos.datos);
    File archivo = await export.exportarEstadisticasAExcel();
    return await export.guardarArchivoExcel(archivo);
  }

  //GETTERS
  String? get inicio => _inicio;
  String? get fin => _fin;
  EstadoSeccion<List<Estadistica>> get categorias => _categorias;
  EstadoSeccion<List<Estadistica>> get cursos => _cursos;
  EstadoSeccion<List<Estadistica>> get grupos => _grupos;
}
