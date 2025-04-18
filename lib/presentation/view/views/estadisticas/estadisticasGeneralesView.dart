import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/graficoBarrasAgrupado.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:provider/provider.dart';

class EstadisticasGeneralesView extends StatefulWidget {
  @override
  State<EstadisticasGeneralesView> createState() {
    return _EstadisticasGeneralesState();
  }
}

class _EstadisticasGeneralesState extends State<EstadisticasGeneralesView> {
  late EstadisticasViewModel estadisticasViewModel;
  List<Estadistica> listaGeneral = [];
  late List<Estadistica> listaCursos1 = [];
  late List<Estadistica> listaCursos2 = [];
  late List<Estadistica> listaCursos3 = [];
  late List<Estadistica> listaGrupos = [];
  String? seleccionCategoria;
  String? seleccionCurso;
  //Definimos el estado al iniciar la vista
  @override
  void initState() {
    super.initState();
    //cargamos las estadisticas generales que se muestran al abrir la vista, categorias
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      estadisticasViewModel = Provider.of<EstadisticasViewModel>(
        context,
        listen: false,
      );
      await estadisticasViewModel.cargarGeneralCategorias(context);
      await estadisticasViewModel.cargarCursosGenerales(
        context,
        estadisticasViewModel.getListCategorias[0].label,
      );
      setState(() {
        listaGeneral =
            estadisticasViewModel.getListEstadisticasGeneralCategorias;
        listaCursos1 = estadisticasViewModel.getListEstadisticasGeneralCursos;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Estadisticas generales'),
      drawer: Menulateral(),
      body: Consumer<EstadisticasViewModel>(
        builder: (context, viewModel, child) {
          return _contenedorSeguro(viewModel);
        },
      ),
    );
  }

  Widget _contenedorSeguro(EstadisticasViewModel viewModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: _contenido(viewModel)),
      ),
    );
  }

  Widget _contenido(EstadisticasViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('Categorias', style: Tipografia.h5()),
          //Grafico
          SizedBox(
            height: 500,
            //child: GraficoBarrasAgrupado(data: listaGeneral),
            child: GraficoBarrasAgrupado(
              data: [
                Estadistica(
                  etiqueta: 'Deporte Recreativo',
                  atenciones: 20,
                  horas: 50,
                ),
                Estadistica(etiqueta: 'semillero', atenciones: 0, horas: 0),
                Estadistica(etiqueta: 'seleccionado', atenciones: 0, horas: 0),
              ],
            ),
          ),
          Text('Cursos - Deporte Recreativo', style: Tipografia.h5()),
          SizedBox(
            height: 500,
            child: GraficoBarrasAgrupado(
              data: [
                Estadistica(
                  etiqueta: 'Futbol masculino',
                  atenciones: 5,
                  horas: 15,
                ),
                Estadistica(
                  etiqueta: 'Baloncesto femenino',
                  atenciones: 10,
                  horas: 20,
                ),
                Estadistica(
                  etiqueta: 'Natacion nivel 1',
                  atenciones: 5,
                  horas: 15,
                ),
              ],
            ),
          ),
          Text('Cursos - semillero', style: Tipografia.h5()),
          SizedBox(height: 500, child: GraficoBarrasAgrupado(data: [])),
          Text('Cursos - seleccionado', style: Tipografia.h5()),
          SizedBox(height: 500, child: GraficoBarrasAgrupado(data: [])),
          //selector categoria
          //TODO: error al usar este desplegable, tambien hay problemas en el uso del previo desplegable
          /*Container(
            alignment: Alignment.center,
            //importante!!! para evitar fallos en la rederizacin, el dropdownmenu debe tener estacio orizontal suficiente, aplicar restricciones a su contenedor es necesario
            width: double.infinity,
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, child) {
                return DropdownMenu(
                  hintText: 'Seleccionar categoria',
                  dropdownMenuEntries: viewModel.getListCategorias,
                );
              },
            ),
          ),*/
          /*if (seleccionCategoria != null)
            SizedBox(
              height: 500,
              child: GraficoBarrasAgrupado(
                data: viewModel.getListEstadisticasGeneralCursos,
              ),
            ),*/
          //grafico
          /*SizedBox(
            height: 500,
            child: GraficoBarrasAgrupado(
              data: viewModel.getListEstadisticasGeneralCursos,
            ),
          ),*/
        ],
      ),
    );
  }
}
