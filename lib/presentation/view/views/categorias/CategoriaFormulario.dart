import 'dart:io';

import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:provider/provider.dart';

class CategoriaFormulario extends StatefulWidget {
  final CategoriaEntidad? categoria;

  CategoriaFormulario({super.key, this.categoria});

  @override
  State<StatefulWidget> createState() {
    return _CategoriaFormularioState();
  }
}

class _CategoriaFormularioState extends State<CategoriaFormulario> {
  late CategoriaViewModel _viewModel;
  CategoriaEntidad? _categoria;
  bool _esEdicion = false;

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  File? _imagen;
  //peticion en vuelo: bloquea el boton y muestra el indicador de carga
  bool _guardando = false;

  void clear() {
    _tituloController.clear();
    _descripcionController.clear();
    _imagen = null;
  }

  @override
  void initState() {
    super.initState();
    //se obtiene aqui y no tras el primer frame: _mostrarImagen lo usa ya en
    //el primer build para pedir la url de la imagen
    _viewModel = Provider.of<CategoriaViewModel>(context, listen: false);
    _categoria = widget.categoria;
    if (_categoria != null) {
      _esEdicion = true;
      if (_categoria!.titulo != null)
        _tituloController.text = _categoria!.titulo;
      if (_categoria!.descripcion != null)
        _descripcionController.text = _categoria!.descripcion;
      //_imagen queda en null: solo guarda una imagen nueva elegida por el
      //usuario, la existente se muestra por red con idImagen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(
        title:
            '${(_categoria == null) ? "Insertar Categoria" : "Editar " + (_categoria!.titulo)}',
      ),
      drawer: Builder(builder: (context) => Menulateral()),
      body: contenedorSeguro(context),
    );
  }

  Future<void> _submitForm() async {
    //primero los campos: asi se ven todos los errores en linea a la vez
    if (!_formKey.currentState!.validate()) return;

    //se espera la peticion para saber cuando termina: mientras tanto el boton
    //queda bloqueado, los timeouts son largos y sin esto la pantalla parece
    //no hacer nada
    setState(() {
      _guardando = true;
    });
    try {
      //crear o actualizar, la regla de la imagen y el armado de la entidad
      //los decide el viewModel; la vista solo entrega lo que hay en pantalla
      final resultado = await _viewModel.guardarCategoria(
        titulo: _tituloController.text,
        descripcion: _descripcionController.text,
        imagenNueva: _imagen,
        original: _categoria,
      );
      await _mostrarResultado(resultado);
    } finally {
      //en exito se hace pop, el widget ya no esta montado y no hay que tocarlo
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  //el viewModel ya interpreto la respuesta: la vista solo decide que mostrar.
  //los campos se limpian solo en exito: si falla el usuario conserva lo que
  //escribio y puede reintentar
  Future<void> _mostrarResultado(Resultado<CategoriaEntidad> resultado) async {
    if (!mounted) return;
    switch (resultado) {
      case Exito():
        await showDialog(
          context: context,
          barrierDismissible: !_esEdicion,
          builder:
              (_) =>
                  _esEdicion
                      ? DialogExito(
                        titulo: 'Accion exitosa',
                        mensaje:
                            'La categoria ${_categoria!.titulo}, ha sido modificada con exito',
                      )
                      : DialogExito(
                        titulo: 'Categoria registrada',
                        mensaje: 'La categoria se ha guardado exitosamente.',
                      ),
        );
        clear();
        //se regresa a la lista, el viewModel ya la refresco tras el exito
        if (mounted) Navigator.pop(context, true);
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          barrierDismissible: !_esEdicion,
          builder:
              (_) => DialogError(
                titulo:
                    _esEdicion
                        ? 'Error al modificar la categoria'
                        : 'Error al guardar categoria',
                codigo: codigo,
                mensaje: mensaje,
              ),
        );
    }
  }

  Widget contenedorSeguro(BuildContext context) {
    return SafeArea(child: contenido());
  }

  Widget contenido() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _inputTitulo(),
              _inputDescripcion(),
              _inputImagen(),
              _acciones(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputTitulo() {
    return TextFormField(
      controller: _tituloController,
      enabled: _esEdicion ? false : true,
      decoration: InputDecoration(labelText: 'Titulo'),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa titulo de la categoria, por favor';
        }
        return null;
      },
    );
  }

  Widget _inputDescripcion() {
    return TextFormField(
      controller: _descripcionController,
      maxLines: 10,
      minLines: 1,
      decoration: InputDecoration(label: Text('Descripcion')),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa la descripción de la categoria, por favor';
        }
        return null;
      },
    );
  }

  Widget _inputImagen() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          _mostrarImagen(),
          OutlinedButton(
            onPressed: _selectorImagen,
            child: Text(
              (_imagen == null) ? 'Seleccionar Imagen' : 'Cambiar imagen',
            ),
          ),
        ],
      ),
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

  Widget _botonSubmit() {
    return Container(
      child: FilledButton(
        //null deshabilita el boton: evita encolar varias peticiones a la vez
        onPressed:
            _guardando
                ? null
                : () {
                  _submitForm();
                },
        child:
            _guardando
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Text('GUARDAR'),
      ),
    );
  }

  Widget _botonCancelar() {
    return Container(
      child: FilledButton(
        //no se permite salir a medias mientras se guarda
        onPressed:
            _guardando
                ? null
                : () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                  clear();
                },
        child: Text('CANCELAR'),
        style: FilledButton.styleFrom(backgroundColor: ColorTheme.secondary),
      ),
    );
  }

  Future<void> _selectorImagen() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        _imagen = File(pickedImage.path);
      });
    }
  }

  Widget _mostrarImagen() {
    //hay id -> existe imagen
    //hay file -> se ha cargado o modificado
    if (_categoria?.idImagen == null && _imagen == null) {
      return Text('No se ha seleccionado ninguna imagen');
    }
    Image img;
    //Si hay imagen en a cargar
    if (_categoria?.idImagen != null && _imagen == null) {
      img = Image.network(
        _viewModel.urlImagen(_categoria!.idImagen!),
        fit: BoxFit.cover,
      );
    } else {
      img = Image.file(_imagen!, fit: BoxFit.cover);
    }

    Container contenedor = Container(height: 300, child: img);

    Positioned posicion = Positioned(
      top: 8,
      right: 8,
      child: IconButton.filledTonal(
        onPressed: () {
          setState(() {
            _imagen = null;
          });
        },
        icon: Icon(Icons.close),
      ),
    );

    return Stack(children: [contenedor]);
  }
}
