import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Autenticacionview extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AutenticacionState();
  }
}

class _AutenticacionState extends State<Autenticacionview> {
  String? _tipoId;
  String? _nombre;
  String? _correo;
  String? _sexo;
  String? _tipoAlumno;
  String? _facultad;
  final _formKey = GlobalKey<FormState>();
  final _controllerId = TextEditingController();
  late AutenticacionViewModel _vmAut;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vmAut = Provider.of<AutenticacionViewModel>(context, listen: false);
      _correo = _vmAut.cuenta!.email;
      _nombre = _vmAut.cuenta!.displayName!;
    });
    Future.microtask(() {
      final vmFacultades = Provider.of<Facultadesviewmodel>(
        context,
        listen: false,
      );
      vmFacultades.listarYNotificarFacultades();
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Registro'),
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
              _inputNombre(),
              _inputId(),
              _inputTipoID(),
              _inputSexo(),
              _inputTipoAlumno(),
              _inputFacultad(),
              _acciones(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputFacultad() {
    return Consumer<Facultadesviewmodel>(
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

        return _mostrarSeleccionableFacultad(vm.facultades);
      },
    );
  }

  _mostrarSeleccionableFacultad(List<String> facultades) {
    List<DropdownMenuEntry> entradas = [];
    facultades.forEach((facultad) {
      DropdownMenuEntry entrada = DropdownMenuEntry(
        value: facultad,
        label: facultad,
      );
      entradas.add(entrada);
    });
    DropdownMenu menu = DropdownMenu(
      hintText: 'Facultad',
      helperText: 'Selecciona tu facultad',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: entradas,
      onSelected: (seleccion) {
        setState(() {
          _facultad = seleccion;
        });
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
  }

  Widget _inputTipoAlumno() {
    List<DropdownMenuEntry> entradas = [
      //ALM_TIPO IN('Estudiante','Administrativo','Docente')
      DropdownMenuEntry(value: 'Estudiante', label: 'Estudiante'),
      DropdownMenuEntry(value: 'Administrativo', label: 'Administrativo'),
      DropdownMenuEntry(value: 'Docente', label: 'Docente'),
    ];
    DropdownMenu menu = DropdownMenu(
      hintText: 'Rol universitario',
      helperText: 'Estas vinculado a la universidad como:',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: entradas,
      onSelected: (seleccion) {
        setState(() {
          _tipoAlumno = seleccion;
        });
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
  }

  Widget _inputId() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: TextFormField(
        controller: _controllerId,
        maxLines: 1,
        minLines: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(label: Text('Identificacion')),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingrese su identificacion';
          }
          return null;
        },
      ),
    );
  }

  //PERF_TIPOID IN('CC','TI','CE','PP','PEP','DIE')
  Widget _inputTipoID() {
    List<DropdownMenuEntry> entradas = [
      DropdownMenuEntry(value: 'CC', label: 'CC'),
      DropdownMenuEntry(value: 'TI', label: 'TI'),
    ];
    DropdownMenu menu = DropdownMenu(
      hintText: 'Tipo ID',
      helperText: 'Selecciona tu tipo de identificacion',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: entradas,
      onSelected: (seleccion) {
        setState(() {
          _tipoId = seleccion;
        });
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
  }

  Widget _inputNombre() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _nombre == null
            ? Text('Registre la informacion antes de continuar, por favor')
            : Text('$_nombre'),
        _correo == null ? Text('') : Text('$_correo'),
      ],
    );
  }

  //PERF_SEXO IN ('M','F')
  Widget _inputSexo() {
    List<DropdownMenuEntry> entradas = [
      DropdownMenuEntry(value: 'M', label: 'M'),
      DropdownMenuEntry(value: 'F', label: 'F'),
    ];
    DropdownMenu menu = DropdownMenu(
      hintText: 'Sexo',
      helperText: 'Selecciona tu sexo',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: entradas,
      onSelected: (seleccion) {
        setState(() {
          _sexo = seleccion;
        });
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
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
    if (_correo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "falta informacion (correo), inicia sesion con google nuevamente",
          ),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_nombre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "falta informacion (nombre), inicia sesion con google nuevamente",
          ),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_sexo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecciona tu sexo por favor"),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_tipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecciona tipo de identificacion por favor"),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_tipoAlumno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Selecciona administrativo, docente o estudiante segun tu rol en la universidad",
          ),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_facultad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecciona la facultad a la que perteneces por favor"),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      PerfilEntidad perfil = PerfilEntidad(
        id: _controllerId.text,
        nombre: _nombre!,
        correo: _correo!,
        tipoId: _tipoId!,
        sexo: _sexo!,
        facultad: _facultad,
        tipoAlumno: _tipoAlumno,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Valores aceptados"),
          backgroundColor: ColorTheme.primary,
        ),
      );
      //usar el view model aqui asi genera error
      RespuestaModelo respuesta = await _vmAut.registroAlumno(perfil);
      if (respuesta.codigoHttp == 201) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, false);
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
