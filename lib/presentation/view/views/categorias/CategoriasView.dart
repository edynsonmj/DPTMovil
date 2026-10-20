import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
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
      AutenticacionViewModel autenticacionViewModel =
          Provider.of<AutenticacionViewModel>(context, listen: false);
      autenticacionViewModel.verificarSesion();
      //la carga no muestra dialogos: el error queda en el vm y se pinta en
      //listaCategorias
      categoriaViewModel.listarYNotificarCategorias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Categorias'),
      drawer: Builder(builder: (context) => Menulateral()),
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
        child: Consumer<AutenticacionViewModel>(
          builder: (context, vm, _) {
            return Column(
              children: [
                if (vm.perfilSesion?.role == Roles.coordinador)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRutas.editarCategoria);
                    },
                    label: Text('Agregar categoria'),
                    icon: Icon(Icons.add),
                  ),
                listaCategorias(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget listaCategorias(CategoriaViewModel viewModel) {
    if (viewModel.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(
        child: Text(
          viewModel.error!,
          style: Tipografia.cuerpo1(color: ColorTheme.error),
        ),
      );
    }
    //antes de la primera carga la lista aun no existe: tambien es espera
    if (viewModel.categorias == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.categorias!.isEmpty) {
      return Center(
        child: Text(
          'No hay categorias aun en el sistema',
          style: Tipografia.cuerpo1(color: ColorTheme.error),
        ),
      );
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
      //se nombra distinto para no ocultar el context del State: tras el pop el
      //context del dialogo queda invalido y no sirve para lo que viene despues
      builder: (contextDialogo) {
        return AlertDialog(
          title: Text('Confirmar eliminacion'),
          content: Text('¿Esta seguro de eliminar la categoria $titulo?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(contextDialogo).pop();
                final resultado = await categoriaViewModel.eliminarCategoria(
                  titulo,
                );
                if (!mounted) return;
                switch (resultado) {
                  //el viewModel ya refresco la lista, solo se avisa
                  case Exito():
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('La categoria $titulo ha sido eliminada'),
                      ),
                    );
                  case Fallo(:final codigo, :final mensaje):
                    _mostrarErrorEliminacion(codigo, mensaje);
                }
              },
              child: Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(contextDialogo).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarErrorEliminacion(int codigo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) {
        return DialogError(
          titulo: 'Error al eliminar la categoria',
          codigo: codigo,
          //el backend manda el detalle como json, DialogError lo desglosa
          mensaje: mensaje,
        );
      },
    );
  }
}
