import 'dart:io';

import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formCursoArgumentos.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:dpt_movil/presentation/view/widgets/imagenRemota.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class FormularioCurso extends StatefulWidget {
  Formcursoargumentos argumentos;

  FormularioCurso({super.key, required this.argumentos});

  @override
  State<StatefulWidget> createState() {
    return _FormularioCursoState();
  }
}

class _FormularioCursoState extends State<FormularioCurso> {
  String? _deporte;
  //bloquea GUARDAR mientras la peticion esta en vuelo
  bool _guardando = false;

  //los vms los crea la ruta formularioCurso (route_generator)
  late final CursosViewModel _vmCurso;
  late Formcursoargumentos _estado;
  late bool _esEdicion;
  File? _imagen;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vmCurso = context.read<CursosViewModel>();
    _estado = widget.argumentos;
    _esEdicion = widget.argumentos.esEdicion;
    _nombreController.value =
        _estado.curso?.nombreCurso == null
            ? TextEditingValue.empty
            : TextEditingValue(text: _estado.curso!.nombreCurso);
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
      drawer: Builder(builder: (context)=> Menulateral()),
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
              _inputDescripcion(),
              _inputComboDeporte(),
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

  //la ruta ya pidio los deportes; aqui solo se pinta su seccion
  Widget _inputComboDeporte() {
    final seccion = context.select<Deporteviewmodel, EstadoSeccion<List<String>>>(
      (vm) => vm.deportes,
    );
    if (seccion.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (seccion.error != null) {
      return Text(
        'No se logró obtener los deportes: ${seccion.error}',
        style: Tipografia.cuerpo1(color: ColorTheme.error),
      );
    }
    if (seccion.datos.isEmpty) {
      return Text(
        '¡No hay deportes aún!',
        style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
      );
    }
    return _mostrarDropdown(seccion.datos);
  }

  Widget _mostrarDropdown(List<String> lista) {
    List<DropdownMenuEntry> entradas = cargarEntradas(lista);
    DropdownMenu menu = DropdownMenu(
      hintText: 'seleccione...',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: entradas,
      onSelected: (seleccion) {
        setState(() {
          _deporte = seleccion;
        });
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
  }

  List<DropdownMenuEntry> cargarEntradas(List<String> lista) {
    List<DropdownMenuEntry> entradas = [];
    for (String item in lista) {
      entradas.add(DropdownMenuEntry(value: item, label: item));
    }
    return entradas;
  }

  Widget _mostrarImagen() {
    //hay id -> existe imagen
    //hay file -> se ha cargado o modificado
    if (_estado.curso?.imagen == null && _imagen == null) {
      return Text('No se ha seleccionado ninguna imagen');
    }
    Widget img;
    //Si hay imagen en a cargar
    if (_estado.curso?.imagen != null && _imagen == null) {
      img = ImagenRemota(
        _vmCurso.urlImagen(_estado.curso!.imagen!),
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
        onPressed: _guardando ? null : _submitForm,
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
    });
    try {
      //las reglas (deporte e imagen obligatorios) y el armado de la entidad
      //los decide el viewModel; la vista solo entrega lo que hay en pantalla
      final resultado = await _vmCurso.guardarCurso(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        categoria: _categoriaController.text,
        deporte: _deporte,
        imagenNueva: _imagen,
        original: _esEdicion ? _estado.curso : null,
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

  //los campos no se tocan: en exito se cierra la pantalla, y si falla el
  //usuario conserva lo que escribio y puede reintentar. Antes se limpiaban
  //antes de enviar
  Future<void> _mostrarResultado(Resultado<CursoEntidad> resultado) async {
    if (!mounted) return;
    switch (resultado) {
      case Exito():
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(
                titulo: 'Curso registrado',
                mensaje: 'El curso se ha guardado exitosamente.',
              ),
        );
        //la lista de cursos recarga la suya al recibir true
        if (mounted) Navigator.pop(context, true);
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                titulo: 'Error al guardar el curso',
                mensaje: mensaje,
                codigo: codigo,
              ),
        );
    }
  }
}
