import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';

/***
 * Construye un grafico de barras agrupado por atenciones y categorias
 */
class GraficoBarrasAgrupado extends StatelessWidget {
  ///Informacion para el grafico
  List<Estadistica> data;

  GraficoBarrasAgrupado({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return contenedor();
  }

  Widget contenedor() {
    return Container(
      child: Column(
        children: [
          etiquetas(),
          //es necesario poner expanded para garantizar el espacio que necesita el grafico para renderizarse, expanded garantiza una espacio vertical
          Expanded(child: graficoScroll()),
        ],
      ),
    );
  }

  Widget graficoScroll() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: (data.length * 50) + 80, // Ajusta el ancho dinámicamente
        child: grafico(),
      ),
    );
  }

  Widget etiquetas() {
    return SizedBox(
      width: double.infinity,
      child: Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            etiqueta('Atenciones', ColorTheme.primary),
            etiqueta('Horas', ColorTheme.secondary),
          ],
        ),
      ),
    );
  }

  Widget etiqueta(String titulo, Color color) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          color: color,
          margin: EdgeInsets.symmetric(horizontal: 10),
        ),
        Text(titulo, style: Tipografia.cuerpo1()),
      ],
    );
  }

  Widget grafico() {
    return BarChart(
      BarChartData(
        barGroups: _obtenerBarGroups(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _obtenerTitulos,
              reservedSize: 100,
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
      ),
    );
  }

  List<BarChartGroupData> _obtenerBarGroups() {
    return List.generate(data.length, (index) {
      final estadistica = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: estadistica.atenciones,
            color: ColorTheme.primary,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: estadistica.horas,
            color: ColorTheme.secondary,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 5,
      );
    });
  }

  Widget _obtenerTitulos(double valor, TitleMeta meta) {
    final index = valor.toInt();
    if (index >= 0 && index < data.length) {
      var titulo = data[index].etiqueta;
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Transform.rotate(
          angle: -pi / 4, // Rotar 45° (-pi/4 en radianes)
          child: Text(
            titulo.length > 10 ? '${titulo.substring(0, 10)}...' : titulo,
            style: Tipografia.cuerpo1(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return Container();
  }
}
