import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
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
  CursosViewModel cursosViewModel = CursosViewModel();
  final ScrollController _scrollController = ScrollController();
  String? _cursoSeleccionado;
  final double _alturaTarjeta = 0.0;

  //libera recursos cuando se deshaga el widget
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //dirige el scroll de la lista cursos a un curso seleccionado
  void _moverScrollACurso(String cursoNombre) {
    //obtenemos el indice segun el nombre del curso suministrado
    final index = cursosViewModel.getListaCursos!.indexWhere(
      (curso) => curso.nombreCurso == cursoNombre,
    );
    if (index != -1) {
      //garantizamos que se haya cargado la vista para evitar errores
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //verificamos que el scroll posea un cliente (una lista) suscrita
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            // Ajusta este valor según la altura de tarjeta
            index * 400,
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
      //definimos el provider a usar en el estado inicial
      final cursosViewModel = Provider.of<CursosViewModel>(
        context,
        listen: false,
      );
      //cargamos los cursos
      //cursosViewModel.cargarListaCursos();
      cursosViewModel.listarCursosDe(context, widget.categoria);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CursosViewModel>(context);
    cursosViewModel = viewModel;
    return Scaffold(
      appBar: Bar(title: 'Cursos de ${widget.categoria.titulo}'),
      drawer: Menulateral(),
      body: contenedorSeguro(context, viewModel),
    );
  }

  ///Contenido de la vista, donde se evita que los elementos se sobrepongan sobre elementos de la interfaz del dispositivo
  SafeArea contenedorSeguro(BuildContext context, CursosViewModel viewModel) {
    //orientacion del dispositivo
    final Orientation orientacion = MediaQuery.of(context).orientation;
    //primera seccion de la pantalla
    Container contenidoEstatico = Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filtro(viewModel),
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
      onPressed: () {},
      label: Text('AGREGAR CURSO'),
      icon: Icon(Icons.add),
    );
    //elementos de la vista sobre las cuales se puede hacer scroll
    Expanded listaItems = componenteLista(orientacion, viewModel);
    //encapsulo todo en safeArea
    return SafeArea(
      child: Column(children: [contenidoEstatico, ajustes, listaItems]),
    );
  }

  Expanded componenteLista(Orientation orientacion, CursosViewModel viewModel) {
    return Expanded(
      child: Center(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: viewModel.getListaCursos?.length ?? 0,
          itemBuilder: (BuildContext context, int index) {
            final CursoEntidad curso = viewModel.getListaCursos![index];
            return Center(
              child: InkWell(
                child: Tarjeta(
                  atrDatosImagen: null, //curso.imagen?.datos,
                  atrTitulo: curso.nombreCurso,
                  atrInfo1: curso.nombreDeporte,
                  atrInfo2: curso.tituloCategoria,
                  atrDescripcion: curso.descripcion,
                  atrInfoPie: '${(index + 1) * 5} grupos',
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRutas.curso,
                    arguments: curso,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  DropdownMenu filtro(CursosViewModel viewModel) {
    DropdownMenu menu = DropdownMenu(
      hintText: 'desplazar a',
      textAlign: TextAlign.center,
      width: 155,
      dropdownMenuEntries: viewModel.getListaEntradas,
      onSelected: (seleccion) {
        setState(() {
          _cursoSeleccionado = seleccion;
        });
        _moverScrollACurso(seleccion);
      },
    );
    return menu;
  }
}
