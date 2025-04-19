import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:flutter/material.dart';

class Widgetlistaclases extends StatelessWidget {
  Grupoentidad grupo;
  Widgetlistaclases({super.key, required this.grupo});
  @override
  Widget build(BuildContext context) {
    return clases();
  }

  Widget clases() {
    Clasesviewmodel vmClases = Clasesviewmodel();
    return FutureBuilder(
      future: vmClases.listarClasesGrupo(
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
          List<Claseentidad> lista = listaDynamic as List<Claseentidad>;
          return mostrarClases(lista);
        } catch (e) {
          return Text(
            'Informacion no compatible en view',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
      },
    );
  }

  Widget mostrarClases(List<Claseentidad> lista) {
    return Container(
      child: Column(
        children: [
          Text('Clases', style: Tipografia.h6()),
          OutlinedButton.icon(
            onPressed: () {},
            label: Text('AGREGAR CLASE'),
            icon: Icon(Icons.add),
          ),
          (lista.isEmpty)
              ? Text(
                'No hay clases aun!',
                style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
              )
              : ListView.builder(
                shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
                physics:
                    const NeverScrollableScrollPhysics(), // Desactiva scroll interno
                itemCount: lista.length, // Cambia esto según tu lista
                itemBuilder: (BuildContext context, int index) {
                  Claseentidad clase = lista[index];
                  return MiniTarjeta(
                    atrTitulo: 'Fecha clase: ${clase.fecha}',
                    atrSubTitulo: 'Tiempo: ${clase.horas}h:${clase.minutos}m',
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
