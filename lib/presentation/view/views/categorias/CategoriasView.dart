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
  AutenticacionViewModel? _sesion;
  //perfil con el que se cargo la lista: si cambia (inicio o cierre de
  //sesion) cambia el JWT y la lista se pide de nuevo
  Object? _perfilCargado;
  bool _cargaInicialHecha = false;

  //Definimos el estado al iniciar la vista
  @override
  void initState() {
    super.initState();
    //cargamos las categorias
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      categoriaViewModel = Provider.of<CategoriaViewModel>(
        context,
        listen: false,
      );
      final sesion = Provider.of<AutenticacionViewModel>(
        context,
        listen: false,
      );
      _sesion = sesion..addListener(_alCambiarSesion);
      //el backend exige el JWT en /categorias2: la lista se pide despues de
      //recuperar la sesion de Google, no a la vez (salia sin token → 401)
      await sesion.verificarSesion();
      if (!mounted) return;
      _perfilCargado = sesion.perfilSesion;
      _cargaInicialHecha = true;
      //la carga no muestra dialogos: el error queda en el vm y se pinta en
      //listaCategorias
      categoriaViewModel.listarYNotificarCategorias();
    });
  }

  //iniciar sesion desde el menu (o cerrarla) estando en esta pantalla
  void _alCambiarSesion() {
    final perfil = _sesion?.perfilSesion;
    if (!_cargaInicialHecha || identical(perfil, _perfilCargado)) return;
    _perfilCargado = perfil;
    categoriaViewModel.listarYNotificarCategorias();
  }

  @override
  void dispose() {
    _sesion?.removeListener(_alCambiarSesion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Builder(builder: (context) => Menulateral()),
        appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 58,
            titleSpacing: 0,

            title: Row(
              children: [
                Container(
                  width: 30,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF08086B),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Deporte Para Todos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF08086B),
                      ),
                    ),
                  ],
                ),
              ],
            ),

        ),

      body: Consumer<CategoriaViewModel>(
        builder: (context, viewModel, child) {
          return contenedorSeguro(viewModel);
        },
      ),

      floatingActionButton: Consumer<AutenticacionViewModel>(
        builder: (context, vm, _) {
          if (vm.perfilSesion?.role != Roles.coordinador) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _abrirFormulario(),
            backgroundColor: const Color(0xFF08086B),
            foregroundColor: Colors.white,
            elevation: 5,
            icon: const Icon(Icons.add),
            label: const Text(
              'Nueva categoría',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
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
                _encabezado(),
                listaCategorias(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _encabezado() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 1),

        const Text(
          'Categorías',
          style: TextStyle(
            color: const Color(0xFF08086B),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFE83C52),
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          '',
          style: TextStyle(
            color: Color(0xFF77778A),
            fontSize: 10,
          ),
        ),
      ],
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
                //la url la da el vm; la tarjeta ya no arma la del servidor
                atrUrlImagen:
                    categoria.idImagen == null
                        ? ''
                        : context.read<CategoriaViewModel>().urlImagen(
                          categoria.idImagen!,
                        ),
              ),
            ),
            if (vm.perfilSesion?.role == Roles.coordinador)
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => _abrirFormulario(categoria),
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

  //el formulario tiene su propio vm (ruta editarCategoria), asi que no
  //refresca esta lista: devuelve true al guardar y aqui se recarga
  Future<void> _abrirFormulario([CategoriaEntidad? categoria]) async {
    final guardado = await Navigator.pushNamed(
      context,
      AppRutas.editarCategoria,
      arguments: categoria,
    );
    if (guardado == true && mounted) {
      context.read<CategoriaViewModel>().listarYNotificarCategorias();
    }
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
