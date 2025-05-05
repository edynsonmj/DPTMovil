import 'dart:math';

import 'package:dpt_movil/domain/entities/entidadesRutas/estadistica_graficoArgumentos.dart';
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
  List<EstadisticaGraficoargumentos> data;
  double alto;

  GraficoBarrasAgrupado({super.key, required this.data, required this.alto});

  @override
  Widget build(BuildContext context) {
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
        width: (data.length * 70) + 80, // Ajusta el ancho dinámicamente
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
              reservedSize: alto / 3,
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            tooltipMargin: 4,
            tooltipPadding: EdgeInsets.zero,
            tooltipRoundedRadius: 0,
            tooltipBorder: BorderSide.none,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(0),
                TextStyle(
                  color: Colors.black,
                  backgroundColor:
                      Colors.white, // ← Esto evita fondo detrás del texto
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _obtenerBarGroups() {
    return List.generate(data.length, (index) {
      final estadistica = data[index];
      return BarChartGroupData(
        showingTooltipIndicators: [0, 1],
        x: index,
        barRods: [
          BarChartRodData(
            toY: estadistica.indice1,
            color: ColorTheme.primary,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: estadistica.indice2,
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
      var titulo = data[index].leyenda;
      return Padding(
        padding: const EdgeInsets.only(
          top: 8.0,
        ), // Espacio entre el gráfico y el texto
        child: Transform.translate(
          offset: Offset(0, alto / 6),
          child: Transform.rotate(
            angle: pi / 2, // Texto de arriba hacia abajo
            alignment: Alignment.topCenter, // Apuntar hacia abajo desde abajo
            child: SizedBox(
              width: alto / 3, // Este ancho ya se reserva bien
              child: Text(
                titulo.length > 30 ? '${titulo.substring(0, 30)}...' : titulo,
                style: Tipografia.cuerpo1(),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
