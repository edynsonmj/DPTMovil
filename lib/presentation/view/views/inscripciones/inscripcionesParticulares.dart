import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/alertFechas.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:provider/provider.dart';

class InscripcionesParticularesView extends StatefulWidget {
  const InscripcionesParticularesView({super.key});

  @override
  State<InscripcionesParticularesView> createState() {
    return _InscripcionesParticularesState();
  }
}

class _InscripcionesParticularesState
    extends State<InscripcionesParticularesView> {
  CategoriaViewModel _categoriaViewModel = CategoriaViewModel();
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _categoriaViewModel =
          Provider.of<CategoriaViewModel>(context, listen: false);
      //TODO: crear endpoint que traiga solo los titulos de las categorias
      _categoriaViewModel.cargarCategorias(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    _categoriaViewModel = Provider.of<CategoriaViewModel>(context);
    return Scaffold(
      appBar: Bar(title: 'Inscripciones'),
      body: contenedorSeguro(context),
    );
  }

  SafeArea contenedorSeguro(BuildContext context) {
    return SafeArea(
        child: Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      child: contenido(),
    ));
  }

  Widget contenido() {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              linkInscripcionesGenerales(),
              descripcion(),
              filtro(),
              listadoGrupos()
            ],
          );
        },
      ),
    );
  }

  Widget linkInscripcionesGenerales() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRutas.InscripcionesGenerales);
          },
          child: Text('INSCRIPCIONES GENERALES'))
    ]);
  }

  Widget descripcion() {
    return Column(children: [
      ListTile(
          title: Text('Configuracion especifica', style: Tipografia.cuerpo1()),
          subtitle: Text(
            'Asigne a cada grupo en particular el estado de las inscripciones, las inscripciones solo pueden ser asignadas a grupos activos',
            style: Tipografia.cuerpo2(),
          )),
      ListTile(
        subtitle: Text('Filtre segun la categoria de los grupos a manipular',
            style: Tipografia.cuerpo2()),
      )
    ]);
  }

  Widget filtro() {
    DropdownMenu menu = DropdownMenu(
      hintText: 'Todos',
      helperText: 'seleccion una categoria',
      textAlign: TextAlign.center,
      dropdownMenuEntries: _categoriaViewModel.getListaEntradas,
      onSelected: (seleccion) {
        setState(() {
          _categoriaSeleccionada = seleccion;
        });
      },
    );
    return Container(margin: EdgeInsets.symmetric(vertical: 10), child: menu);
  }

  Widget listadoGrupos() {
    return ListView.builder(
      shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
      physics: const NeverScrollableScrollPhysics(), // Desactiva scroll interno
      itemCount: 20, // Cambia esto según tu lista
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          child: MiniTarjeta(
            existeCampoImagen: true,
            atrTitulo: 'grupo $index',
            atrSubTitulo: (_categoriaSeleccionada != null)
                ? _categoriaSeleccionada!
                : 'todos',
            atrIndicadorEstado: (index % 2 == 0) ? 'Cerradas' : 'abiertas',
            atrIndicador: 'inscripciones',
          ),
          onTap: () {
            estadoInscripcionGrupo(context, 'Grupo $index', 'cerrado');
          },
        );
      },
    );
  }

  void estadoInscripcionGrupo(
      BuildContext context, String grupo, String estado) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Control inscripciones'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                title: Text(grupo),
                subtitle: Text('Grupo'),
              ),
              ListTile(
                title: Text(estado),
                subtitle: Text('Estado inscripcion'),
              )
            ]),
            actionsOverflowAlignment: OverflowBarAlignment.center,
            actions: [
              OutlinedButton(
                  onPressed: () {
                    //cierra el alert
                    Navigator.of(context).pop();
                    _confirmarAbrir(context, grupo);
                  },
                  child: Text('Abrir')),
              OutlinedButton(
                  onPressed: () {
                    //cierra el dialogo
                    Navigator.of(context).pop();
                    _confirmarCerrar(context, grupo);
                  },
                  child: Text('Cerrar'),
                  style: FilledButton.styleFrom(
                      foregroundColor: ColorTheme.secondary,
                      side: BorderSide(color: ColorTheme.secondary))),
              OutlinedButton(
                  onPressed: () {
                    //cierra el dialogo
                    Navigator.of(context).pop();
                    //_mostrarSelectorFecha(context, grupo);
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertFechas(
                              seleccionRango:
                                  (DateTime fecha1, DateTime? fecha2) {
                                //TODO: funcion que ejecuta la accion
                              },
                              titulo: 'inscripciones $grupo',
                              contenido:
                                  'asigne a el grupo $grupo una fecha de apertura y cierre para las inscripciones');
                        });
                  },
                  child: Text('Programar'),
                  style: FilledButton.styleFrom(
                      foregroundColor: ColorTheme.tertiary,
                      side: BorderSide(color: ColorTheme.tertiary)))
            ],
          );
        });
  }

  void _confirmarAbrir(BuildContext context, String grupo) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Abrir Inscripciones '),
            content: Text(
                '¿Esta seguro de abrir las inscripciones al grupo $grupo?',
                textAlign: TextAlign.center),
            actions: [
              TextButton(
                  onPressed: () {
                    //cierra el alert
                    Navigator.of(context).pop();
                    //TODO: funcion que ejecuta la accon
                  },
                  child: Text('Confirmar')),
              TextButton(
                  onPressed: () {
                    //cierra el dialogo
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                  style: FilledButton.styleFrom(
                      foregroundColor: ColorTheme.secondary))
            ],
          );
        });
  }

  void _confirmarCerrar(BuildContext context, String grupo) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cerrar Inscripciones '),
            content: Text(
              '¿Esta seguro de cerrar las inscripciones al grupo $grupo?',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    //TODO: llamar funcion para ejecutar accion
                    //cierra el alert
                    Navigator.of(context).pop();
                  },
                  child: Text('Confirmar')),
              TextButton(
                onPressed: () {
                  //cierra el dialogo
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                    foregroundColor: ColorTheme.secondary),
                child: Text('Cancelar'),
              )
            ],
          );
        });
  }
}
