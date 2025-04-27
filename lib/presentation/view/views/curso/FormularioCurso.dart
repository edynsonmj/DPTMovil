import 'dart:io';

import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formCursoArgumentos.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FormularioCurso extends StatefulWidget {
  Formcursoargumentos argumentos;

  FormularioCurso({super.key, required this.argumentos});

  @override
  State<StatefulWidget> createState() {
    return _FormularioCursoState();
  }
}

class _FormularioCursoState extends State<FormularioCurso> {
  final CursosViewModel _vmCurso = CursosViewModel();
  late Formcursoargumentos _estado;
  late bool _esEdicion;
  File? _imagen;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _deporteController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _estado = widget.argumentos;
    _esEdicion = widget.argumentos.esEdicion;
    _nombreController.value =
        _estado.curso?.nombreCurso == null
            ? TextEditingValue.empty
            : TextEditingValue(text: _estado.curso!.nombreCurso);
    _deporteController.value =
        _estado.curso?.nombreDeporte == null
            ? TextEditingValue.empty
            : TextEditingValue(text: _estado.curso!.nombreDeporte);
    _categoriaController.value = TextEditingValue(text: _estado.categoria);
    _descripcionController.value =
        _estado.curso?.descripcion == null
            ? TextEditingValue.empty
            : TextEditingValue(text: _estado.curso!.descripcion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(
        title:
            _esEdicion
                ? 'Editar curso: ${widget.argumentos.curso!.nombreCurso}'
                : 'Agregar curso',
      ),
      drawer: Menulateral(),
      body: _contenedorSeguro(context),
    );
  }

  Widget _contenedorSeguro(context) {
    return SafeArea(child: _contenido(context));
  }

  Widget _contenido(context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _inputNombre(),
              _inputDeporte(),
              _inputDescripcion(),
              _inputImagen(),
              _acciones(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputNombre() {
    return TextFormField(
      controller: _nombreController,
      maxLines: 1,
      minLines: 1,
      enabled: _esEdicion ? false : true,
      decoration: InputDecoration(label: Text('Nombre')),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingrese el nombre del curso';
        }
        return null;
      },
    );
  }

  Widget _inputDeporte() {
    return TextFormField(
      controller: _deporteController,
      maxLines: 1,
      minLines: 1,
      decoration: InputDecoration(label: Text('Deporte')),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingrese el deporte';
        }
        return null;
      },
    );
  }

  Widget _inputCategoria() {
    return TextFormField(
      controller: _categoriaController,
      maxLines: 1,
      minLines: 1,
      enabled: false,
      decoration: InputDecoration(label: Text('categoria')),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '';
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
        if (value == null || value.isEmpty) {
          return 'Ingresa la descripción de la curso, por favor';
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

  Widget _mostrarImagen() {
    //hay id -> existe imagen
    //hay file -> se ha cargado o modificado
    if (_estado.curso?.imagen == null && _imagen == null) {
      return Text('No se ha seleccionado ninguna imagen');
    }
    Image img;
    //Si hay imagen en a cargar
    if (_estado.curso?.imagen != null && _imagen == null) {
      String basepath = ConfigServicio().obtenerBaseApi();
      img = Image.network(
        '$basepath/imagenStream?idImagen=${_estado.curso?.imagen}',
        fit: BoxFit.cover,
      );
    } else {
      img = Image.file(_imagen!, fit: BoxFit.cover);
    }
    Container contenedor = Container(height: 300, child: img);
    return contenedor;
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

  Future<void> _submitForm(context) async {
    if (_imagen == null && _estado.curso?.imagen == null) {
      showDialog(
        context: context,
        builder: (_) {
          return DialogError(
            titulo: "Falta informacion",
            mensaje: "Carga una imagen por favor",
            codigo: 0,
          );
        },
      );
    }
    if (_formKey.currentState!.validate()) {
      CursoEntidad entidad = CursoEntidad(
        nombreCurso: _nombreController.text,
        nombreDeporte: _deporteController.text,
        tituloCategoria: _categoriaController.text,
        descripcion: _descripcionController.text,
        imagen: _estado.curso?.imagen,
      );
      if (_imagen != null) {
        entidad.imagenFile = _imagen;
      }
      _limpiarInputs();
      if (_esEdicion) {
        await _manejarEditar(entidad);
      } else {
        await _manejarAgregar(entidad);
      }
    }
  }

  _manejarAgregar(CursoEntidad entidad) async {
    RespuestaModelo respuesta = await _vmCurso.agregarCurso(entidad);

    if (respuesta.codigoHttp == 201) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(
                titulo: 'Curso registrado',
                mensaje: 'El curso se ha guardado exitosamente.',
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

  _manejarEditar(CursoEntidad entidad) {}

  _limpiarInputs() {
    _categoriaController.clear();
    _deporteController.clear();
    _nombreController.clear();
    _descripcionController.clear();
    setState(() {
      _imagen = null;
    });
  }
}
