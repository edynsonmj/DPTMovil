import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:provider/provider.dart';

class InscripcionesGeneralesView extends StatefulWidget {
  const InscripcionesGeneralesView({super.key});
  @override
  State<InscripcionesGeneralesView> createState() {
    return _InscripcionesGeneralesState();
  }
}

class _InscripcionesGeneralesState extends State<InscripcionesGeneralesView> {
  //estado
  late CategoriaViewModel categoriaViewModel;
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarCategorias());
  }

  //el vm devuelve el resultado ya resuelto; el aviso es decision de la vista.
  //Una lista vacia no es un error: el filtro queda sin opciones
  Future<void> _cargarCategorias() async {
    final resultado =
        await context.read<CategoriaViewModel>().listarYNotificarCategorias();
    if (resultado is Fallo<void> && mounted) {
      showDialog(
        context: context,
        builder:
            (_) => DialogError(
              titulo: 'No se pudieron cargar las categorias',
              mensaje: resultado.mensaje,
              codigo: resultado.codigo,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //obtenemos el provider cada vez que se construya el widget
    categoriaViewModel = Provider.of<CategoriaViewModel>(context);
    return Scaffold(
      appBar: Bar(title: 'Inscripciones'),
      drawer: Builder(builder: (context)=> Menulateral()),
      body: contenedorSeguro(context),
    );
  }

  SafeArea contenedorSeguro(BuildContext context) {
    return SafeArea(
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 25), child: contenido()));
  }

  Widget filtro() {
    DropdownMenu menu = DropdownMenu(
      hintText: 'sin seleccion',
      helperText: 'seleccion una categoria',
      textAlign: TextAlign.center,
      dropdownMenuEntries: [
        for (final titulo in categoriaViewModel.titulos)
          DropdownMenuEntry(value: titulo, label: titulo),
      ],
      onSelected: (seleccion) {
        setState(() {
          _categoriaSeleccionada = seleccion;
        });
      },
    );
    return Container(margin: EdgeInsets.symmetric(vertical: 10), child: menu);
  }

  Widget contenido() {
    return Column(children: [
      configuracionEspecifica(),
      configuracionGeneral(),
      Divider(
        color: ColorTheme.neutral,
      ),
    ]);
  }

  Widget configuracionGeneral() {
    Widget descripcion = ListTile(
      title: Text('configuracion general', style: Tipografia.cuerpo1()),
      subtitle: Text(
          'A continuacion selecciones la categoria de la cual desea manipular todas las inscripciones',
          style: Tipografia.cuerpo2()),
    );
    //decision D1 (plan de abrir inscripciones): el backend solo abre y cierra
    //por grupo. Hasta que tenga un endpoint por categoria las acciones se
    //muestran deshabilitadas y se remite a la configuracion por grupo; antes
    //confirmaban sin hacer nada
    Widget abrir = OutlinedButton(onPressed: null, child: Text('Abrir'));
    Widget cerrar = OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
            foregroundColor: ColorTheme.secondary,
            side: BorderSide(color: ColorTheme.secondary)),
        child: Text('Cerrar'));
    Widget programar = OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
            foregroundColor: ColorTheme.tertiary,
            side: BorderSide(color: ColorTheme.tertiary)),
        child: Text('Programar'));
    Widget acciones = Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [abrir, cerrar, programar]);
    Widget aviso = ListTile(
      subtitle: Text(
          'Abrir, cerrar o programar todos los grupos de una categoria aun no esta disponible. Use la CONFIGURACION DETALLADA para hacerlo grupo por grupo.',
          style: Tipografia.cuerpo2(color: ColorTheme.secondaryDark)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        descripcion,
        filtro(),
        if (_categoriaSeleccionada != null) ...[acciones, aviso]
      ],
    );
  }

  Widget configuracionEspecifica() {
    Widget boton = TextButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRutas.InscripcionesParticulares);
        },
        child: Text('CONFIGURACION DETALLADA'));
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [boton],
    );
  }

}
