import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Claseformulario extends StatefulWidget {
  const Claseformulario({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ClaseFormularioState();
  }
}

class _ClaseFormularioState extends State<Claseformulario> {
  final _horasController = TextEditingController();
  //valor que el usuario esta eligiendo, como el texto de un controller: se
  //entrega al vm al guardar
  DateTime? fecha = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _horasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Agregar clase'),
      drawer: Builder(builder: (context) => Menulateral()),
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
  }) async {
    final DateTime? selectorFecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'seleccione una fecha',
    );
    //cancelar el selector devuelve null: se conserva la fecha que habia
    if (selectorFecha == null || !mounted) return;
    setState(() {
      fecha = selectorFecha;
    });
  }

  Widget _inputFecha() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fecha inicial'),
        OutlinedButton(
          onPressed: () async {
            await _seleccionFecha(
              context: context,
              fechaInicial: fecha ?? DateTime.now(),
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
      //solo para marcar el campo en linea; la regla la aplica el vm
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    //armar la clase y validar las horas lo hace el vm
    final resultado = await context.read<Clasesviewmodel>().registrarClase(
      fecha: fecha,
      horasTexto: _horasController.text,
    );
    await _mostrarResultado(resultado);
  }

  //el vm ya interpreto la respuesta: la vista solo decide que mostrar
  Future<void> _mostrarResultado(Resultado<bool> resultado) async {
    if (!mounted) return;
    switch (resultado) {
      case Exito(:final datos):
        final bool nueva = datos ?? true;
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(
                titulo: nueva ? 'Clase registrada' : 'Clase existente',
                mensaje:
                    nueva
                        ? 'La clase se ha guardado exitosamente.'
                        : 'Ya existía una clase en esa fecha; no se creó otra.',
              ),
        );
        //con true la pantalla del grupo recarga sus clases
        if (mounted) Navigator.pop(context, true);
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                titulo: 'Error al guardar clase',
                codigo: codigo,
                mensaje: mensaje,
              ),
        );
    }
  }

  Widget _botonSubmit() {
    return Container(
      child: FilledButton(
        onPressed: () {
          _submitForm();
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
