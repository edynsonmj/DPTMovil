import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/estadistica_graficoArgumentos.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:dpt_movil/presentation/view/widgets/alertFechasEstadisticas.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/graficoBarrasAgrupado.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:provider/provider.dart';

//sin estado propio (fase 7c): el rango y las tres secciones viven en el vm
//de la ruta, que pide cada seccion una vez por rango. Cada grafica lee solo
//su seccion con context.select
class EstadisticasGeneralesView extends StatelessWidget {
  const EstadisticasGeneralesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Estadisticas generales'),
      drawer: Builder(builder: (context) => Menulateral()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _contenido(context),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final inicio = context.select<EstadisticasViewModel, String?>(
      (vm) => vm.inicio,
    );
    final fin = context.select<EstadisticasViewModel, String?>((vm) => vm.fin);
    final hayRango = inicio != null && fin != null;
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (inicio != null) Text(inicio),
              fechas(context),
              if (fin != null) Text(fin),
            ],
          ),
          if (!hayRango)
            Text(
              "Seleccione un rango de tiempo antes de continuar",
              style: Tipografia.cuerpo1(color: ColorTheme.error),
            ),
          if (hayRango)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [const _BotonExportar()],
            ),
          //Graficos
          if (hayRango) ...[
            _SeccionGrafica(
              titulo: 'Categorias',
              seccion: (vm) => vm.categorias,
              formato: formatoDatosCategorias,
            ),
            _SeccionGrafica(
              titulo: 'Cursos',
              seccion: (vm) => vm.cursos,
              formato: formatoDatosCursos,
            ),
            _SeccionGrafica(
              titulo: 'Grupos',
              seccion: (vm) => vm.grupos,
              formato: formatoDatosGrupos,
            ),
          ],
        ],
      ),
    );
  }

  Widget fechas(BuildContext context) {
    //el dialogo no queda bajo el provider de la ruta: el vm se toma antes
    final viewModel = context.read<EstadisticasViewModel>();
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return Alertfechasestadisticas(
              titulo: 'Seleccione las fechas',
              contenido: 'Asigne un rango de fechas para generar estadisticas',
              seleccionRango: (DateTime? fecha1, DateTime? fecha2) {
                if (fecha1 != null && fecha2 != null) {
                  viewModel.cargar(
                    FormatDate.fechaACadena(fecha1, '-'),
                    FormatDate.fechaACadena(fecha2, '-'),
                  );
                } else {
                  viewModel.limpiar();
                }
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

  //las listas llegan ya ordenadas por tiempo total desde el vm; la grafica pinta
  //horas con decimales (4 h 30 = 4,5)
  static List<EstadisticaGraficoargumentos> formatoDatosCategorias(
    List<Estadistica> lista,
  ) {
    return lista
        .map(
          (estadistica) => EstadisticaGraficoargumentos(
            leyenda: estadistica.leyenda1,
            indice1: estadistica.clases,
            indice2: estadistica.duracion / 60,
          ),
        )
        .toList();
  }

  static List<EstadisticaGraficoargumentos> formatoDatosCursos(
    List<Estadistica> lista,
  ) {
    return lista
        .map(
          (estadistica) => EstadisticaGraficoargumentos(
            leyenda: '${estadistica.leyenda2} - ${estadistica.leyenda1}',
            indice1: estadistica.clases,
            indice2: estadistica.duracion / 60,
          ),
        )
        .toList();
  }

  static List<EstadisticaGraficoargumentos> formatoDatosGrupos(
    List<Estadistica> lista,
  ) {
    return lista
        .map(
          (estadistica) => EstadisticaGraficoargumentos(
            leyenda:
                '${estadistica.leyenda3}.${estadistica.leyenda4}:${estadistica.leyenda2} - ${estadistica.leyenda1}',
            indice1: estadistica.clases,
            indice2: estadistica.duracion / 60,
          ),
        )
        .toList();
  }
}

class _SeccionGrafica extends StatelessWidget {
  final String titulo;
  final EstadoSeccion<List<Estadistica>> Function(EstadisticasViewModel)
  seccion;
  final List<EstadisticaGraficoargumentos> Function(List<Estadistica>)
  formato;

  const _SeccionGrafica({
    required this.titulo,
    required this.seccion,
    required this.formato,
  });

  @override
  Widget build(BuildContext context) {
    final estado = context.select(seccion);
    return Column(
      children: [Text(titulo, style: Tipografia.h5()), _cuerpo(estado)],
    );
  }

  Widget _cuerpo(EstadoSeccion<List<Estadistica>> estado) {
    const double alto = 600;
    if (estado.cargando) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (estado.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          estado.error!,
          textAlign: TextAlign.center,
          style: Tipografia.cuerpo1(color: ColorTheme.error),
        ),
      );
    }
    if (estado.datos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Sin datos'),
      );
    }
    return SizedBox(
      height: alto,
      child: GraficoBarrasAgrupado(data: formato(estado.datos), alto: alto),
    );
  }
}

//deshabilitado mientras grupos carga o no tiene datos (M4)
class _BotonExportar extends StatelessWidget {
  const _BotonExportar();

  @override
  Widget build(BuildContext context) {
    final puedeExportar = context.select<EstadisticasViewModel, bool>(
      (vm) => vm.puedeExportar,
    );
    return IconButton(
      onPressed:
          puedeExportar
              ? () async {
                //se toma antes del await para no usar context despues
                final mensajero = ScaffoldMessenger.of(context);
                bool estado =
                    await context.read<EstadisticasViewModel>().export();
                mensajero.showSnackBar(
                  estado
                      ? SnackBar(
                        content: Text("Archivo guardado en tu carpeta descargas"),
                        backgroundColor: ColorTheme.primaryLight,
                      )
                      : SnackBar(
                        content: Text("Ha ocurrido un error en el proceso"),
                        backgroundColor: ColorTheme.error,
                      ),
                );
              }
              : null,
      icon: Icon(Icons.download),
    );
  }
}
