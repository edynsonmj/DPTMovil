import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/estadistica_graficoArgumentos.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:dpt_movil/presentation/view/widgets/alertFechas.dart';
import 'package:dpt_movil/presentation/view/widgets/alertFechasEstadisticas.dart';
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
  String? fechaInicio;
  String? fechaFin;
  String? seleccionCategoria;
  String? seleccionCurso;
  //Definimos el estado al iniciar la vista
  @override
  void initState() {
    super.initState();
    //cargamos las estadisticas generales que se muestran al abrir la vista, categorias
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Estadisticas generales'),
      drawer: Builder(builder: (context) => Menulateral()),
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
        child: _contenido(viewModel),
      ),
    );
  }

  Widget _contenido(EstadisticasViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (fechaInicio != null) Text(fechaInicio.toString()),
              fechas(),
              if (fechaFin != null) Text(fechaFin.toString()),
            ],
          ),
          if (fechaInicio == null && fechaFin == null)
            Text(
              "Seleccione un rango de tiempo antes de continuar",
              style: Tipografia.cuerpo1(color: ColorTheme.error),
            ),
          //Grafico
          if (fechaInicio != null && fechaFin != null) graficas(viewModel),
        ],
      ),
    );
  }

  Widget graficas(EstadisticasViewModel viewModel) {
    return Column(
      children: [
        seccionGraficaCategorias(viewModel),
        seccionGraficaCursos(viewModel),
        seccionGraficaGrupos(viewModel),
      ],
    );
  }

  Widget seccionGraficaCategorias(EstadisticasViewModel viewModel) {
    double alto = 600;
    return Column(
      children: [
        Text('Categorias', style: Tipografia.h5()),
        //Grafico
        if (fechaInicio != null && fechaFin != null)
          SizedBox(
            height: alto,
            //child: GraficoBarrasAgrupado(data: listaGeneral),
            child: FutureBuilder(
              future: viewModel.estadisticasCategorias(fechaInicio!, fechaFin!),
              builder: (context, promesa) {
                if (!promesa.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                RespuestaModelo respuesta = promesa.data as RespuestaModelo;
                List lista = respuesta.datos as List;
                List<Estadistica> estadisticas = lista as List<Estadistica>;
                List<EstadisticaGraficoargumentos> datos =
                    formatoDatosCategorias(estadisticas);
                return GraficoBarrasAgrupado(data: datos, alto: alto);
              },
            ),
          ),
      ],
    );
  }

  Widget seccionGraficaCursos(EstadisticasViewModel viewModel) {
    double alto = 600;
    return Column(
      children: [
        Text('Cursos', style: Tipografia.h5()),
        //Grafico
        if (fechaInicio != null && fechaFin != null)
          SizedBox(
            height: alto,
            //child: GraficoBarrasAgrupado(data: listaGeneral),
            child: FutureBuilder(
              future: viewModel.estadisticasCursos(fechaInicio!, fechaFin!),
              builder: (context, promesa) {
                if (!promesa.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                RespuestaModelo respuesta = promesa.data as RespuestaModelo;
                List lista = respuesta.datos as List;
                List<Estadistica> estadisticas = lista as List<Estadistica>;
                List<EstadisticaGraficoargumentos> datos = formatoDatosCursos(
                  estadisticas,
                );
                return GraficoBarrasAgrupado(data: datos, alto: alto);
              },
            ),
          ),
      ],
    );
  }

  Widget seccionGraficaGrupos(EstadisticasViewModel viewModel) {
    double alto = 600;
    return Column(
      children: [
        Text('Cursos', style: Tipografia.h5()),
        //Grafico
        if (fechaInicio != null && fechaFin != null)
          SizedBox(
            height: alto,
            //child: GraficoBarrasAgrupado(data: listaGeneral),
            child: FutureBuilder(
              future: viewModel.estadisticasGrupos(fechaInicio!, fechaFin!),
              builder: (context, promesa) {
                if (!promesa.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                RespuestaModelo respuesta = promesa.data as RespuestaModelo;
                List lista = respuesta.datos as List;
                List<Estadistica> estadisticas = lista as List<Estadistica>;
                List<EstadisticaGraficoargumentos> datos = formatoDatosGrupos(
                  estadisticas,
                );
                return GraficoBarrasAgrupado(data: datos, alto: alto);
              },
            ),
          ),
      ],
    );
  }

  Widget fechas() {
    return OutlinedButton(
      onPressed: () {
        //_mostrarProgramar(context, _categoriaSeleccionada!);
        showDialog(
          context: context,
          builder: (context) {
            return Alertfechasestadisticas(
              titulo: 'Seleccione las fechas',
              contenido: 'Asigne un rango de fechas para generar estadisticas',
              seleccionRango: (DateTime? fecha1, DateTime? fecha2) {
                setState(() {
                  fechaInicio =
                      (fecha1 != null)
                          ? FormatDate.fechaACadena(fecha1, '-')
                          : null;
                  fechaFin =
                      (fecha2 != null)
                          ? FormatDate.fechaACadena(fecha2, '-')
                          : null;
                });
              },
            );
          },
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorTheme.tertiary,
        side: BorderSide(color: ColorTheme.tertiary),
      ),
      child: Text('Asignar fechas'),
    );
  }

  List<EstadisticaGraficoargumentos> formatoDatosCategorias(
    List<Estadistica> lista,
  ) {
    lista.sort((a, b) => b.horas.compareTo(a.horas));
    List<EstadisticaGraficoargumentos> argumentos = [];
    lista.forEach((estadistica) {
      EstadisticaGraficoargumentos argumento = EstadisticaGraficoargumentos(
        leyenda: estadistica.leyenda1,
        indice1: estadistica.clases,
        indice2: estadistica.horas,
      );
      argumentos.add(argumento);
    });
    return argumentos;
  }

  List<EstadisticaGraficoargumentos> formatoDatosCursos(
    List<Estadistica> lista,
  ) {
    lista.sort((a, b) => b.horas.compareTo(a.horas));
    List<EstadisticaGraficoargumentos> argumentos = [];
    lista.forEach((estadistica) {
      EstadisticaGraficoargumentos argumento = EstadisticaGraficoargumentos(
        leyenda: '${estadistica.leyenda2} - ${estadistica.leyenda1}',
        indice1: estadistica.clases,
        indice2: estadistica.horas,
      );
      argumentos.add(argumento);
    });
    return argumentos;
  }

  List<EstadisticaGraficoargumentos> formatoDatosGrupos(
    List<Estadistica> lista,
  ) {
    lista.sort((a, b) => b.horas.compareTo(a.horas));
    List<EstadisticaGraficoargumentos> argumentos = [];
    lista.forEach((estadistica) {
      EstadisticaGraficoargumentos argumento = EstadisticaGraficoargumentos(
        leyenda:
            '${estadistica.leyenda3}.${estadistica.leyenda4}:${estadistica.leyenda2} - ${estadistica.leyenda1}',
        indice1: estadistica.clases,
        indice2: estadistica.horas,
      );
      argumentos.add(argumento);
    });
    return argumentos;
  }
}
