import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formCursoArgumentos.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:provider/provider.dart';

class CursosView extends StatefulWidget {
  CategoriaEntidad categoria;
  CursosView({super.key, required this.categoria});

  @override
  State<CursosView> createState() {
    return _CursosViewState();
  }
}

class _CursosViewState extends State<CursosView> {
  final ScrollController _scrollController = ScrollController();

  //libera recursos cuando se deshaga el widget
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //dirige el scroll de la lista cursos a un curso seleccionado
  void _moverScrollACurso(String cursoNombre) {
    //obtenemos el indice segun el nombre del curso suministrado
    final index = context.read<CursosViewModel>().getListaCursos!.indexWhere(
      (curso) => curso.nombreCurso == cursoNombre,
    );
    if (index != -1) {
      //garantizamos que se haya cargado la vista para evitar errores
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //verificamos que el scroll posea un cliente (una lista) suscrita
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            // Ajusta este valor según la altura de tarjeta
            index * 330,
            duration: Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    //nos aseguramos que se cargue el contexto para eviar errores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //el vm lo crea la ruta (route_generator); aqui solo se carga
      _cargarCursos();
    });
  }

  //el vm devuelve el resultado ya resuelto; el aviso es decision de la vista
  Future<void> _cargarCursos() async {
    final resultado = await context.read<CursosViewModel>().listarCursosDe(
      widget.categoria,
    );
    if (resultado is Fallo<void> && mounted) {
      showDialog(
        context: context,
        builder:
            (_) => DialogError(
              titulo: 'No se pudieron cargar los cursos',
              mensaje: resultado.mensaje,
              codigo: resultado.codigo,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CursosViewModel>();
    //solo se reconstruye si cambia el rol, no con cualquier cambio de sesion
    final esCoordinador = context.select<AutenticacionViewModel, bool>(
      (vm) => vm.perfilSesion?.role == Roles.coordinador,
    );
    return Scaffold(
      appBar: Bar(title: 'Cursos de ${widget.categoria.titulo}'),
      drawer: Builder(builder: (context) => Menulateral()),
      body: contenedorSeguro(context, viewModel, esCoordinador),
    );
  }

  ///Contenido de la vista, donde se evita que los elementos se sobrepongan sobre elementos de la interfaz del dispositivo
  Widget contenedorSeguro(
    BuildContext context,
    CursosViewModel viewModel,
    bool esCoordinador,
  ) {
    //primera seccion de la pantalla
    Container contenidoEstatico = Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filtro(viewModel),
          if (esCoordinador)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRutas.InscripcionesGenerales);
              },
              child: Text('INSCRIPCIONES'),
            ),
        ],
      ),
    );
    Widget ajustes = OutlinedButton.icon(
      onPressed: () async {
        final respuesta = await Navigator.pushNamed(
          context,
          AppRutas.formularioCurso,
          arguments: Formcursoargumentos(
            esEdicion: false,
            categoria: widget.categoria.titulo,
          ),
        );
        if (respuesta == true && context.mounted) {
          _cargarCursos();
        }
      },
      label: Text('AGREGAR CURSO'),
      icon: Icon(Icons.add),
    );
    //encapsulo todo en safeArea
    return SafeArea(
      child: Column(
        children: [
          contenidoEstatico,
          if (esCoordinador) ajustes,
          if (viewModel.cargando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (viewModel.getListaCursos == null ||
              viewModel.getListaCursos!.isEmpty)
            Center(
              child: Text(
                'No hay cursos aun para esta categoria',
                style: Tipografia.cuerpo1(color: ColorTheme.error),
              ),
            )
          //elementos de la vista sobre las cuales se puede hacer scroll
          else
            componenteLista(viewModel, esCoordinador),
        ],
      ),
    );
  }

  Expanded componenteLista(CursosViewModel viewModel, bool esCoordinador) {
    return Expanded(
      child: Center(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: viewModel.getListaCursos?.length ?? 0,
          itemBuilder: (BuildContext context, int index) {
            final CursoEntidad curso = viewModel.getListaCursos![index];
            return _mostrarTarjeta(curso, esCoordinador);
          },
        ),
      ),
    );
  }

  Widget _mostrarTarjeta(CursoEntidad curso, bool esCoordinador) {
    return Stack(
      children: [
        Center(
          child: InkWell(
            child: Tarjeta(
              //la url la da el vm; la tarjeta ya no arma la del servidor
              atrUrlImagen:
                  curso.imagen == null
                      ? ''
                      : context.read<CursosViewModel>().urlImagen(
                        curso.imagen!,
                      ),
              atrTitulo: curso.nombreCurso,
              atrInfo1: curso.nombreDeporte,
              atrInfo2: curso.tituloCategoria,
              atrDescripcion: curso.descripcion,
            ),
            onTap: () {
              if (esCoordinador) {
                Navigator.pushNamed(context, AppRutas.curso, arguments: curso);
              }
            },
          ),
        ),
      ],
    );
  }

  DropdownMenu filtro(CursosViewModel viewModel) {
    DropdownMenu menu = DropdownMenu(
      hintText: 'desplazar a',
      textAlign: TextAlign.center,
      width: 155,
      dropdownMenuEntries: [
        for (final nombre in viewModel.nombresCursos)
          DropdownMenuEntry(value: nombre, label: nombre),
      ],
      onSelected: (seleccion) {
        if (seleccion != null) _moverScrollACurso(seleccion);
      },
    );
    return menu;
  }
}
