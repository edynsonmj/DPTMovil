import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Autenticacionview extends StatefulWidget {
  const Autenticacionview({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AutenticacionState();
  }
}

class _AutenticacionState extends State<Autenticacionview> {
  String? _tipoId;
  String? _nombre;
  //true si el nombre llego con la sesion (Google): se muestra como texto. Se
  //decide una sola vez; con lo escrito a mano el campo sigue editable (AU-05)
  bool _nombreDeSesion = false;
  String? _correo;
  String? _sexo;
  String? _tipoAlumno;
  String? _facultad;
  String? _programa;
  bool _enviando = false;
  //motivo del ultimo rechazo del backend: queda escrito sobre los botones
  //hasta el siguiente intento, no en un SnackBar que se va solo (AU-06)
  String? _errorRegistro;
  final _formKey = GlobalKey<FormState>();
  final _controllerId = TextEditingController();
  final _controllerNombre = TextEditingController();
  final _controllerCodigo = TextEditingController();
  final _controllerDependencia = TextEditingController();

  //datos que pide el backend segun el tipo de vinculo
  bool get _pideFacultadYPrograma =>
      _tipoAlumno == 'Estudiante' || _tipoAlumno == 'Docente';
  bool get _pideCodigo => _tipoAlumno == 'Estudiante';
  bool get _pideDependencia =>
      _tipoAlumno == 'Administrativo' || _tipoAlumno == 'Contratista';
  late AutenticacionViewModel _vmAut;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vmAut = Provider.of<AutenticacionViewModel>(context, listen: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _correo = _vmAut.correoAutenticado;
        _nombre = _vmAut.nombreAutenticado;
        _nombreDeSesion = _nombre != null && _nombre!.trim().isNotEmpty;
        _controllerNombre.text = _nombre ?? '';
      });
    });
    final vmFacultades = Provider.of<Facultadesviewmodel>(
      context,
      listen: false,
    );
    Future.microtask(vmFacultades.listarYNotificarFacultades);
  }

  @override
  void dispose() {
    _controllerId.dispose();
    _controllerNombre.dispose();
    _controllerCodigo.dispose();
    _controllerDependencia.dispose();
    super.dispose();
  }

  @override
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
              if (_pideCodigo) _inputCodigo(),
              if (_pideFacultadYPrograma) _inputFacultad(),
              if (_pideFacultadYPrograma && _facultad != null) _inputPrograma(),
              if (_pideDependencia) _inputDependencia(),
              if (_errorRegistro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    _errorRegistro!,
                    textAlign: TextAlign.center,
                    style: Tipografia.cuerpo1(color: ColorTheme.error),
                  ),
                ),
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
    for (final facultad in facultades) {
      DropdownMenuEntry entrada = DropdownMenuEntry(
        value: facultad,
        label: facultad,
      );
      entradas.add(entrada);
    }
    DropdownMenu menu = DropdownMenu(
      hintText: 'Facultad',
      helperText: 'Selecciona tu facultad',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: entradas,
      initialSelection: _facultad,
      onSelected: (seleccion) {
        if (seleccion == null || seleccion == _facultad) return;
        setState(() {
          _facultad = seleccion;
          _programa = null;
        });
        context.read<Facultadesviewmodel>().listarProgramas(seleccion);
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
  }

  Widget _inputPrograma() {
    final estado = context
        .select<Facultadesviewmodel, EstadoSeccion<List<String>>>(
          (vm) => vm.programas,
        );
    if (estado.cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    String? aviso = estado.error;
    if (aviso == null && estado.datos.isEmpty) {
      aviso = 'La facultad no tiene programas registrados';
    }
    if (aviso != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text(aviso, style: Tipografia.cuerpo1(color: ColorTheme.error)),
      );
    }
    DropdownMenu menu = DropdownMenu(
      //clave por facultad: al cambiarla el desplegable empieza vacio
      key: ValueKey('programas-$_facultad'),
      hintText: 'Programa',
      helperText: 'Selecciona tu programa academico',
      textAlign: TextAlign.center,
      width: double.infinity,
      menuHeight: 300,
      dropdownMenuEntries: [
        for (final programa in estado.datos)
          DropdownMenuEntry(value: programa, label: programa),
      ],
      onSelected: (seleccion) {
        setState(() {
          _programa = seleccion;
        });
      },
    );
    return Padding(padding: EdgeInsets.symmetric(vertical: 15), child: menu);
  }

  Widget _inputCodigo() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: TextFormField(
        controller: _controllerCodigo,
        maxLines: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(label: Text('Codigo institucional')),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ingrese su codigo institucional';
          }
          return null;
        },
      ),
    );
  }

  Widget _inputDependencia() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: TextFormField(
        controller: _controllerDependencia,
        maxLines: 1,
        decoration: InputDecoration(label: Text('Dependencia')),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ingrese la dependencia en la que trabaja';
          }
          return null;
        },
      ),
    );
  }

  Widget _inputTipoAlumno() {
    List<DropdownMenuEntry> entradas = [
      //ALM_TIPO IN('Estudiante','Docente','Administrativo','Contratista')
      DropdownMenuEntry(value: 'Estudiante', label: 'Estudiante'),
      DropdownMenuEntry(value: 'Docente', label: 'Docente'),
      DropdownMenuEntry(value: 'Administrativo', label: 'Administrativo'),
      DropdownMenuEntry(value: 'Contratista', label: 'Contratista'),
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
        if (!_nombreDeSesion)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: TextFormField(
              controller: _controllerNombre,
              decoration: InputDecoration(label: Text('Nombre completo')),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese su nombre';
                }
                return null;
              },
            ),
          )
        else
          Text('$_nombre'),
        if (_correo != null) Text('$_correo'),
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

  Future<void> _submitForm(BuildContext context) async {
    _correo = _vmAut.correoAutenticado ?? _correo;
    if (_correo == null || _correo!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Falta informacion del correo para completar el registro"),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    _nombre = _controllerNombre.text.trim().isEmpty
        ? _nombre
        : _controllerNombre.text.trim();
    if (_nombre == null || _nombre!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Falta informacion del nombre para completar el registro"),
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
            "Selecciona estudiante, docente, administrativo o contratista segun tu vinculo con la universidad",
          ),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_pideFacultadYPrograma && _facultad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecciona la facultad a la que perteneces por favor"),
          backgroundColor: ColorTheme.error,
        ),
      );
      return;
    }
    if (_pideFacultadYPrograma && _programa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecciona tu programa academico por favor"),
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
        tipoAlumno: _tipoAlumno,
        //solo los datos del tipo de vinculo elegido
        facultad: _pideFacultadYPrograma ? _facultad : null,
        programa: _pideFacultadYPrograma ? _programa : null,
        alumnoCodigo: _pideCodigo ? _controllerCodigo.text.trim() : null,
        dependencia:
            _pideDependencia ? _controllerDependencia.text.trim() : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Valores aceptados"),
          backgroundColor: ColorTheme.primary,
        ),
      );
      setState(() {
        _enviando = true;
        _errorRegistro = null;
      });
      RespuestaModelo respuesta = await _vmAut.registroAlumno(perfil);
      if (!context.mounted) {
        return;
      }
      if (respuesta.codigoHttp == 201) {
        setState(() => _enviando = false);
        Navigator.pop(context, true);
        return;
      }
      //se queda en el formulario, con lo llenado, para corregir lo que el
      //backend rechazo
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _enviando = false;
        _errorRegistro = _vmAut.mensajeErrorRegistro(respuesta);
      });
    }
  }

  Widget _botonSubmit() {
    return FilledButton(
      onPressed:
          _enviando
              ? null
              : () {
                _submitForm(context);
              },
      child: Text('GUARDAR'),
    );
  }

  Widget _botonCancelar() {
    return FilledButton(
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context, false);
        }
      },
      style: FilledButton.styleFrom(backgroundColor: ColorTheme.secondary),
      child: Text('CANCELAR'),
    );
  }
}
