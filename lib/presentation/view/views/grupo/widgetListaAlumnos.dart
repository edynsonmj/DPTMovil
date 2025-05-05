import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/campoBusqueda.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:flutter/material.dart';

class Widgetlistaalumnos extends StatelessWidget {
  Grupoentidad grupo;

  Widgetlistaalumnos({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    //throw UnimplementedError();
    return alumnos();
  }

  Widget alumnos() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Text('Alumnos', style: Tipografia.h6()),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*Text(
                  'Agregar alumno',
                  style: Tipografia.leyendaNegrita(color: ColorTheme.neutral),
                ),
                CampoBusqueda(leyenda: 'buscar alumno...'),*/
              ],
            ),
          ),
          listadoAlumnos(),
        ],
      ),
    );
  }

  Widget listadoAlumnos() {
    Alumnosviewmodel vmAlumno = Alumnosviewmodel();
    return FutureBuilder(
      future: vmAlumno.listarAlumnosGrupo(
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
          List<Alumnoentidad> lista = listaDynamic as List<Alumnoentidad>;
          if (lista.isEmpty) {
            return Text(
              'No hay alumnos aun!',
              style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
            );
          }
          return mostrarListadoAlumnos(lista);
        } catch (e) {
          return Text(
            'Informacion no compatible en view',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
      },
    );
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
