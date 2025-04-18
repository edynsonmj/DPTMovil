import 'package:flutter/material.dart';
import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';

class AlertFechas extends StatefulWidget {
  final Function(DateTime, DateTime?) seleccionRango;
  final String titulo;
  final String contenido;

  AlertFechas({
    super.key,
    required this.titulo,
    required this.contenido,
    required this.seleccionRango,
  });

  @override
  _AlertFechasState createState() => _AlertFechasState();
}

class _AlertFechasState extends State<AlertFechas> {
  DateTime? _fechaInicial;
  DateTime? _fechaFinal;

  ///asigna a [_fechaInicial] o [fechaFinal] segun la bandera [esInicial] la fecha designada en el selectro de fecha
  ///
  ///[esInicial] asigna la fecha a [_fechaInicial] si es true, asigna [_fechaFinal] de lo contrario.
  ///
  ///[fechaInicial] si es definida selecciona la fecha indicada al abrir el selector.
  ///
  ///[ultimaFecha] si es definida asigna el limite superial del calendario, de lo contrario asigna el año 2100
  ///
  ///[primeraFecha] si es definida asigna el limite inferior del calendario, de lo contrario sera la fecha actual
  Future<void> _seleccionFecha(
      {required BuildContext context,
      required bool esInicial,
      DateTime? fechaInicial,
      DateTime? ultimaFecha,
      DateTime? primeraFecha}) async {
    final DateTime? selectorFecha = await showDatePicker(
        context: context,
        initialDate: fechaInicial,
        firstDate: (primeraFecha == null) ? DateTime.now() : primeraFecha,
        lastDate: (ultimaFecha == null) ? DateTime(2100) : ultimaFecha,
        helpText: 'seleccione una fecha');
    setState(() {
      if (esInicial) {
        _fechaInicial = selectorFecha;
      } else {
        _fechaFinal = selectorFecha;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.titulo,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.contenido, textAlign: TextAlign.center),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
            child: Column(
              children: [campoInicial(), campoFinal()],
            ),
          )
        ],
      ),
      actions: [
        if (_fechaInicial != null)
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmarProgramacion(context);
              },
              child: Text('Confirmar')),
        TextButton(
          onPressed: () {
            setState(() {
              _fechaInicial = null;
              _fechaFinal = null;
            });
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: ColorTheme.secondary),
          child: Text('Cancelar'),
        )
      ],
    );
  }

  Widget campoInicial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fecha inicial'),
        OutlinedButton(
            onPressed: () async {
              //fija variable de fecha
              await _seleccionFecha(
                  context: context,
                  esInicial: true,
                  fechaInicial:
                      (_fechaInicial == null) ? DateTime.now() : _fechaInicial,
                  primeraFecha: null,
                  ultimaFecha: (_fechaFinal == null) ? null : _fechaFinal);
            },
            child: Text(_fechaInicial == null
                ? 'Seleccionar fecha inicial'
                : FormatDate.fechaACadena(_fechaInicial!, '/')))
      ],
    );
  }

  Widget campoFinal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fecha final'),
        OutlinedButton(
            onPressed: () async {
              //fija variable de fecha
              await _seleccionFecha(
                  context: context,
                  esInicial: false,
                  fechaInicial: (_fechaFinal == null) ? null : _fechaFinal,
                  primeraFecha: (_fechaInicial == null) ? null : _fechaInicial,
                  ultimaFecha: null);
            },
            child: Text(_fechaFinal == null
                ? 'Seleccionar fecha final'
                : FormatDate.fechaACadena(_fechaFinal!, '/')))
      ],
    );
  }

  void _confirmarProgramacion(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Confirmar programacion',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Está seguro de programar las inscripciones con estos valores?',
                  textAlign: TextAlign.center,
                ),
                Text(
                    'Fecha de apertura: ${(_fechaInicial != null) ? FormatDate.fechaACadena(_fechaInicial!, "/") : "No definido"}'),
                Text(
                    'Fecha de cierre: ${(_fechaFinal != null) ? FormatDate.fechaACadena(_fechaFinal!, "/") : "No definido"}')
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.seleccionRango(_fechaInicial!, _fechaFinal);
                  },
                  child: Text('Confirmar')),
              TextButton(
                onPressed: () {
                  //cierra el dialogo
                  /* se genera error al cancelar, corregir
                  setState(() {
                    _fechaInicial = null;
                    _fechaFinal = null;
                  });*/
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTheme.secondary),
                child: Text('Cancelar'),
              )
            ],
          );
        });
  }
}
