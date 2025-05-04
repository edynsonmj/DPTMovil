import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:provider/provider.dart';

class CategoriasView extends StatefulWidget {
  const CategoriasView({super.key});

  @override
  State<CategoriasView> createState() {
    return _CategoriasViewState();
  }
}

class _CategoriasViewState extends State<CategoriasView> {
  late CategoriaViewModel categoriaViewModel;
  //Definimos el estado al iniciar la vista
  @override
  void initState() {
    super.initState();
    //cargamos las categorias
    WidgetsBinding.instance.addPostFrameCallback((_) {
      categoriaViewModel = Provider.of<CategoriaViewModel>(
        context,
        listen: false,
      );
      //categoriaViewModel.fetchCategorias();
      categoriaViewModel.cargarCategorias(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Categorias'),
      //Bar(title: 'Categorias'),
      drawer: Builder(builder: (context) => Menulateral()),
      //body: contenedorSeguro(categoriaViewModel)
      body: Consumer<CategoriaViewModel>(
        builder: (context, viewModel, child) {
          return contenedorSeguro(viewModel);
        },
      ),
    );
  }

  Widget contenedorSeguro(CategoriaViewModel viewModel) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRutas.editarCategoria);
              },
              label: Text('Agregar categoria'),
              icon: Icon(Icons.add),
            ),
            listaCategorias(viewModel),
          ],
        ),
      ),
    );
  }

  Widget listaCategorias(CategoriaViewModel viewModel) {
    if (viewModel.categorias == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
      //evita scroll interno
      physics: const NeverScrollableScrollPhysics(),
      //la lista se construira segun el tamaño de la lista categorias del viewmodel
      itemCount: viewModel.categorias?.length ?? 0,
      itemBuilder: (context, index) {
        final CategoriaEntidad categoria = viewModel.categorias![index];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [mostrarTarjeta(categoria)],
        );
      },
    );
  }

  Widget mostrarTarjeta(CategoriaEntidad categoria) {
    return Consumer<AutenticacionViewModel>(
      builder: (context, vm, _) {
        return Stack(
          children: [
            InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRutas.cursos,
                  arguments: categoria,
                );
              },
              child: Tarjeta(
                atrTitulo: categoria.titulo,
                atrDescripcion: categoria.descripcion,
                atrRutaTarjeta: AppRutas.cursos,
                atrDatosImagen: categoria.imagen?.datos,
                idImagen: categoria.idImagen,
              ),
            ),
            if (vm.perfilSesion?.role == Roles.coordinador)
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRutas.editarCategoria,
                      arguments: categoria,
                    );
                  },
                  icon: EditIcon(),
                ),
              ),
            if (vm.perfilSesion?.role == Roles.coordinador)
              Positioned(
                right: 8,
                top: 50,
                child: IconButton(
                  onPressed: () {
                    _confirmarEliminacion(categoria.titulo);
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(2, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarEliminacion(String titulo) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar eliminacion'),
          content: Text('¿Esta seguro de eliminar la categoria $titulo?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await categoriaViewModel.eliminarCategoria(titulo);
                await categoriaViewModel.cargarCategorias(context);
              },
              child: Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
