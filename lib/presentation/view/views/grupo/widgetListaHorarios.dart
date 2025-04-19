import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:flutter/material.dart';

class Widgetlistahorarios extends StatelessWidget {
  Grupoentidad grupo;

  Widgetlistahorarios({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    return horarios();
  }

  Widget horarios() {
    Horariosviewmodel vmHorario = Horariosviewmodel();
    return FutureBuilder(
      future: vmHorario.listarHorariosGrupo(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      ),
      builder: (context, promesa) {
        if (promesa.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (promesa.hasError) {
          return Text(
            'Error: ${promesa.error}',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        } else if (!promesa.hasData) {
          return Text(
            'Sin informacion',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
        if (promesa.data!.codigoHttp != 200) {
          return Text(
            'no se logro obtener informacion: ${promesa.data!.codigoHttp} - ${promesa.data!.error?.mensaje}',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
        if (promesa.data!.datos is! List) {
          return Text(
            'informacion sobre el curso en formato erroneo',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
        try {
          List<dynamic> listaDynamic = promesa.data!.datos;
          List<Horarioentidad> lista = listaDynamic as List<Horarioentidad>;
          return mostrarHorarios(lista);
        } catch (e) {
          return Text(
            'Informacion no compatible en view',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
      },
    );
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
