import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Widgetlistahorarios extends StatelessWidget {
  const Widgetlistahorarios({super.key});

  @override
  Widget build(BuildContext context) {
    //solo se reconstruye cuando cambia la seccion de horarios del vm
    final seccion = context
        .select<DetalleGrupoViewModel, EstadoSeccion<List<Horarioentidad>>>(
          (vm) => vm.horarios,
        );
    if (seccion.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (seccion.error != null) {
      return Text(
        'no se logro obtener informacion: ${seccion.error}',
        style: Tipografia.cuerpo1(color: ColorTheme.error),
      );
    }
    return mostrarHorarios(seccion.datos);
  }

  Widget mostrarHorarios(List<Horarioentidad> lista) {
    return Container(
      child: Column(
        children: [
          Text('Horarios', style: Tipografia.h6()),
          OutlinedButton.icon(
            onPressed: () {},
            label: Text('AGREGAR HORARIO'),
            icon: Icon(Icons.add),
          ),
          (lista.isEmpty)
              ? Text(
                'No hay horarios aun!',
                style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
              )
              : ListView.builder(
                shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
                physics:
                    const NeverScrollableScrollPhysics(), // Desactiva scroll interno
                itemCount: lista.length, // Cambia esto según tu lista
                itemBuilder: (BuildContext context, int index) {
                  Horarioentidad horario = lista[index];
                  return MiniTarjeta(
                    atrTitulo: '${horario.dia} - ${horario.escenario}',
                    atrSubTitulo: '${horario.horaInicio} - ${horario.horaFin}',
                    existeBotonCierre: true,
                    existeCampoImagen: false,
                  );
                },
              ),
        ],
      ),
    );
  }
}
