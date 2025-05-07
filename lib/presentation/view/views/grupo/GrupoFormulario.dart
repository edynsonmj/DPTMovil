import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formGrupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Grupoformulario extends StatefulWidget {
  final Formgrupoargumentos argumentos;
  const Grupoformulario({super.key, required this.argumentos});

  @override
  State<StatefulWidget> createState() {
    return _GrupoFormularioState();
  }
}

class _GrupoFormularioState extends State<Grupoformulario> {
  late bool _esEdicion;
  late CursoEntidad _curso;
  Grupoentidad? _grupo;

  final _formKey = GlobalKey<FormState>();
  final _cuposController = TextEditingController();

  String? _idInstructor;
  int? _anio;
  String? _fechaCreacion;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.argumentos.esEdicion;
    _curso = widget.argumentos.curso;
    _grupo = widget.argumentos.grupo;
    Future.microtask(() {
      final vmInstructor = Provider.of<InstructoresViewModel>(
        context,
        listen: false,
      );
      vmInstructor.listarYNotificarInstructores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: _esEdicion ? 'Editar grupo' : 'Agregar grupo'),
      drawer: Builder(builder: (context) => Menulateral()),
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
              _infoCurso(),
              _inputCupos(),
              _selectInstructor(),
              _acciones(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCupos() {
    return TextFormField(
      controller: _cuposController,
      maxLines: 1,
      minLines: 1,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(label: Text('Cupos del grupo')),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingrese la cantidad de cupos';
        }
        return null;
      },
    );
  }

  Widget _selectInstructor() {
    return Consumer<InstructoresViewModel>(
      builder: (context, vm, _) {
        if (vm.cargando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.error != null) {
          return Center(
            child: Text(
              vm.error!,
              style: Tipografia.cuerpo1(color: ColorTheme.error),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 17),
          child: _mostrarDropdown(vm.instructores),
        );
      },
    );
  }

  Widget _mostrarDropdown(List<Instructorentidad> lista) {
    List<DropdownMenuEntry> entradas = [];

    for (Instructorentidad instructor in lista) {
      DropdownMenuEntry entrada = DropdownMenuEntry(
        value: instructor.id,
        label: '${instructor.nombre} - ${instructor.id}',
      );
      entradas.add(entrada);
    }

    DropdownMenu menu = DropdownMenu(
      hintText: 'instructor...',
      helperText: 'Asigne un instructor al grupo',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: entradas,
      onSelected: (seleccion) {
        setState(() {
          _idInstructor = seleccion;
        });
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
  }

  Widget _infoCurso() {
    if (!_esEdicion) {
      setState(() {
        _anio = DateTime.now().year;
        _fechaCreacion = FormatDate.fechaACadena(DateTime.now(), '-');
      });
    }
    return Column(
      children: [
        ListTile(
          title: Center(child: Text('Categoria', style: Tipografia.h6())),
          subtitle: Center(child: Text(_curso.tituloCategoria)),
        ),
        ListTile(
          title: Center(child: Text('Curso', style: Tipografia.h6())),
          subtitle: Center(child: Text(_curso.nombreCurso)),
        ),
        ListTile(
          title: Center(child: Text('Identificador', style: Tipografia.h6())),
          subtitle: Center(child: Text('$_anio.N')),
        ),
      ],
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
    if (_idInstructor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seleccione a un instructor'),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_anio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se ha establecido identificador'),
          backgroundColor: ColorTheme.error,
        ),
      );
    }
    if (_formKey.currentState!.validate()) {
      Grupoentidad g = Grupoentidad(
        categoria: _curso.tituloCategoria,
        curso: _curso.nombreCurso,
        anio: _anio!,
        iterable: 0,
        imagen: _curso.imagen,
        cupos: int.parse(_cuposController.text),
        idInstructor: _idInstructor,
        fechaCreacion: FormatDate.fechaACadena(DateTime.now(), '-'),
      );

      Gruposviewmodel vm = Provider.of<Gruposviewmodel>(context, listen: false);

      RespuestaModelo respuesta = await vm.insertarGrupo(g);

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
  }
}
