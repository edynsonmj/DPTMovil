import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Claseformulario extends StatefulWidget {
  final Claseentidad entidad;
  Claseformulario({super.key, required this.entidad});

  @override
  State<StatefulWidget> createState() {
    return _ClaseFormularioState();
  }
}

class _ClaseFormularioState extends State<Claseformulario> {
  final Clasesviewmodel vmClase = Clasesviewmodel();
  late Claseentidad claseEstado;
  final _horasController = TextEditingController();
  DateTime? fecha = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    claseEstado = widget.entidad;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Agregar clase'),
      drawer: Menulateral(),
      body: contenedorSeguro(context),
    );
  }

  Widget contenedorSeguro(context) {
    return SafeArea(child: contenido(context));
  }

  Widget contenido(context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(children: [_inputFecha(), _inputHoras(), _acciones()]),
        ),
      ),
    );
  }

  Future<void> _seleccionFecha({
    required BuildContext context,
    DateTime? fechaInicial,
    DateTime? ultimaFecha,
    DateTime? primeraFecha,
  }) async {
    final DateTime? selectorFecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'seleccione una fecha',
    );
    setState(() {
      fecha = selectorFecha;
      claseEstado.fecha = fecha;
    });
  }

  Widget _inputFecha() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fecha inicial'),
        OutlinedButton(
          onPressed: () async {
            //fija variable de fecha
            await _seleccionFecha(
              context: context,
              fechaInicial: DateTime.now(),
              primeraFecha: null,
            );
          },
          child: Text(
            fecha == null
                ? 'Seleccionar fecha'
                : FormatDate.fechaACadena(fecha!, '/'),
          ),
        ),
      ],
    );
  }

  Widget _inputHoras() {
    return TextFormField(
      controller: _horasController,
      maxLines: 1,
      minLines: 1,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(label: Text('Horas clase')),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingrese la duracion de la clase en horas';
        }
        return null;
      },
    );
  }

  Widget _acciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_botonSubmit(), _botonCancelar()],
      ),
    );
  }

  Future<void> _submitForm(context) async {
    if (_formKey.currentState!.validate()) {
      claseEstado.fecha = fecha;
      claseEstado.horas = int.parse(_horasController.text);
      claseEstado.minutos = 0;
      final respuesta = await vmClase.guardarClase(claseEstado);

      if (respuesta.codigoHttp == 201) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder:
                (_) => DialogExito(
                  titulo: 'Clase registrada',
                  mensaje: 'La clase se ha guardado exitosamente.',
                ),
          );
          Navigator.pop(context, true); // Volver y avisar éxito
        }
      } else {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder:
                (_) => DialogError(
                  titulo: 'Error al guardar clase',
                  mensaje:
                      respuesta.error?.mensaje ??
                      'Error desconocido. Código: ${respuesta.codigoHttp}',
                  codigo: respuesta.codigoHttp,
                ),
          );
        }
      }
    }
  }

  Widget _botonSubmit() {
    return Container(
      child: FilledButton(
        onPressed: () {
          _submitForm(context);
        },
        child: Text('GUARDAR'),
      ),
    );
  }

  Widget _botonCancelar() {
    return Container(
      child: FilledButton(
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context, false);
          }
        },
        child: Text('CANCELAR'),
        style: FilledButton.styleFrom(backgroundColor: ColorTheme.secondary),
      ),
    );
  }
}
