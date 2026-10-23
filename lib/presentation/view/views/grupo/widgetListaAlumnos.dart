import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Widgetlistaalumnos extends StatelessWidget {
  const Widgetlistaalumnos({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Text('Alumnos', style: Tipografia.h6()),
          ),
          listadoAlumnos(context),
        ],
      ),
    );
  }

  Widget listadoAlumnos(BuildContext context) {
    //solo se reconstruye cuando cambia la seccion de alumnos del vm
    final seccion = context
        .select<DetalleGrupoViewModel, EstadoSeccion<List<Alumnoentidad>>>(
          (vm) => vm.alumnos,
        );
    if (seccion.cargando) {
      return const CircularProgressIndicator();
    }
    if (seccion.error != null) {
      return Text(
        'no se logro obtener informacion: ${seccion.error}',
        style: Tipografia.cuerpo1(color: ColorTheme.error),
      );
    }
    if (seccion.datos.isEmpty) {
      return Text(
        'No hay alumnos aun!',
        style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
      );
    }
    return mostrarListadoAlumnos(seccion.datos);
  }

  Widget mostrarListadoAlumnos(List<Alumnoentidad> listado) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: ListView.builder(
        shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
        physics:
            const NeverScrollableScrollPhysics(), // Desactiva scroll interno
        itemCount: listado.length, // Cambia esto según tu lista
        itemBuilder: (BuildContext context, int index) {
          //TODO: establecer inkwell para comportamiento al tocar
          Alumnoentidad alumno = listado[index];
          return MiniTarjeta(
            existeCampoImagen: true,
            atrTitulo: alumno.nombre,
            atrSubTitulo: alumno.id,
            existeBotonCierre: true,
          );
        },
      ),
    );
  }
}
