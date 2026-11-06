import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formGrupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
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
  //bloquea GUARDAR mientras la peticion esta en vuelo
  bool _guardando = false;

  final _formKey = GlobalKey<FormState>();
  final _cuposController = TextEditingController();

  String? _idInstructor;
  DateTime? _aperturaInscripcion;
  DateTime? _cierreInscripcion;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.argumentos.esEdicion;
    _curso = widget.argumentos.curso;
    _grupo = widget.argumentos.grupo;

    //el vm lo crea la ruta grupoFormulario (route_generator)
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
              _inputFechasInscripcion(),
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

  //sin apertura las inscripciones quedan abiertas desde que se crea el grupo
  Widget _inputFechasInscripcion() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            'Apertura de inscripciones (opcional)',
            style: Tipografia.cuerpo1(),
          ),
          OutlinedButton(
            onPressed:
                () => _elegirFecha(
                  _aperturaInscripcion,
                  (fecha) => _aperturaInscripcion = fecha,
                ),
            child: Text(
              _aperturaInscripcion == null
                  ? 'Abrir al crear el grupo'
                  : FormatDate.fechaACadena(_aperturaInscripcion!, '/'),
            ),
          ),
          SizedBox(height: 12),
          Text('Cierre de inscripciones', style: Tipografia.cuerpo1()),
          OutlinedButton(
            onPressed:
                () => _elegirFecha(
                  _cierreInscripcion,
                  (fecha) => _cierreInscripcion = fecha,
                ),
            child: Text(
              _cierreInscripcion == null
                  ? 'Seleccionar fecha de cierre'
                  : FormatDate.fechaACadena(_cierreInscripcion!, '/'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirFecha(
    DateTime? actual,
    void Function(DateTime) asignar,
  ) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'seleccione una fecha',
    );
    if (fecha == null || !mounted) return;
    setState(() => asignar(fecha));
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
          //solo se pinta: el anio que se envia lo fija el vm al guardar
          subtitle: Center(
            child: Text('${_grupo?.anio ?? DateTime.now().year}.N'),
          ),
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
      //las reglas (instructor, cupos numericos) y el armado del grupo los
      //decide el vm propio de la ruta; la vista solo entrega lo que hay en
      //pantalla. Guardar no recarga ninguna lista: lo hace la del curso al
      //recibir true
      final resultado = await context.read<Gruposviewmodel>().registrarGrupo(
        curso: _curso,
        cupos: _cuposController.text,
        idInstructor: _idInstructor,
        aperturaInscripcion: _aperturaInscripcion,
        cierreInscripcion: _cierreInscripcion,
        original: _esEdicion ? _grupo : null,
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

  Future<void> _mostrarResultado(Resultado<Grupoentidad> resultado) async {
    if (!mounted) return;
    switch (resultado) {
      case Exito():
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(
                titulo: 'Grupo registrado',
                mensaje: 'El grupo se ha guardado exitosamente.',
              ),
        );
        if (mounted) Navigator.pop(context, true);
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                titulo: 'Error al guardar el grupo',
                mensaje: mensaje,
                codigo: codigo,
              ),
        );
    }
  }
}
