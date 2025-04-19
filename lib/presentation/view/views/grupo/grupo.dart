import 'dart:typed_data';

import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaAlumnos.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaClases.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaHorarios.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/campoBusqueda.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/encabezadoImagen.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';

class Grupo extends StatelessWidget {
  Grupoentidad grupo;
  Grupo({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: '${grupo.curso} ${grupo.anio}.${grupo.iterable}'),
      drawer: Menulateral(),
      body: contenedorSeguro(context),
    );
  }

  Widget contenedorSeguro(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            EncabezadoImagen(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: contenedor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget contenedor(context) {
    return Column(
      children: [
        CampoBusqueda(leyenda: 'buscar instructor...'),
        MiniTarjeta(
          existeCampoImagen: true,
          atrMargerSuperior: 15,
          atrMargerInferior: 15,
          atrTitulo: 'Edynson Muñoz Jimenez',
          atrSubTitulo: 'Instructor',
          existeBotonCierre: true,
          atrDatosImagen: Uint8List(0),
        ),
        informacionCurso(context),
        informacionGrupo(),
        cupos(),
        Widgetlistahorarios(grupo: grupo),
        Widgetlistaalumnos(grupo: grupo),
        Widgetlistaclases(grupo: grupo),
        botonesCierre(),
      ],
    );
  }

  Widget botonesCierre() {
    return Container(
      child: Column(
        children: [
          OutlinedButton(
            onPressed: () {},
            child: Text('FINALIZAR GRUPO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorTheme.secondary,
              side: BorderSide(color: ColorTheme.secondary),
            ),
          ),
          FilledButton(
            onPressed: () {},
            child: Text('ELIMINAR GRUPO'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget cupos() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          Column(
            children: [
              ListTile(
                title: Text('Cupos', style: Tipografia.cuerpo1()),
                subtitle: Text('${grupo.cupos}', style: Tipografia.cuerpo2()),
              ),
              ListTile(
                title: Text('Matriculados', style: Tipografia.cuerpo1()),
                subtitle: Text('20', style: Tipografia.cuerpo2()),
              ),
            ],
          ),
          Positioned(child: EditIcon(), top: 8, right: 8),
        ],
      ),
    );
  }

  Widget informacionCurso(context) {
    CursosViewModel vmCurso = CursosViewModel();
    return FutureBuilder(
      future: vmCurso.obtenerCurso(grupo.categoria, grupo.curso),
      builder: (context, promesa) {
        if (promesa.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (promesa.hasError) {
          return Text('Error: ${promesa.error}');
        } else if (!promesa.hasData) {
          return Text('Sin informacion');
        }
        if (promesa.data!.codigoHttp != 200) {
          return Text(
            'no se logro obtener informacion: ${promesa.data!.codigoHttp} - ${promesa.data!.error?.mensaje}',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
        if (promesa.data!.datos is! CursoEntidad) {
          return Text('informacion sobre el curso en formato erroneo');
        }
        CursoEntidad curso = promesa.data!.datos;
        return mostrarInfoCurso(curso);
      },
    );
  }

  Widget mostrarInfoCurso(CursoEntidad curso) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Text('Informacion del curso', style: Tipografia.h6()),
            ListTile(
              title: Text('Curso', style: Tipografia.cuerpo1()),
              subtitle: Text(
                '${curso.nombreCurso} - ${curso.tituloCategoria}',
                style: Tipografia.cuerpo2(),
              ),
            ),
            ListTile(
              title: Text('Descripcion', style: Tipografia.cuerpo1()),
              subtitle: Text(style: Tipografia.cuerpo2(), curso.descripcion),
            ),
          ],
        ),
      ),
    );
  }

  Widget informacionGrupo() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            Text('Informacion del Grupo', style: Tipografia.h6()),
            ListTile(
              title: Text('Grupo', style: Tipografia.cuerpo1()),
              subtitle: Text(
                '${grupo.curso}: ${grupo.anio}.${grupo.iterable} - ${grupo.categoria}',
                style: Tipografia.cuerpo2(),
              ),
            ),
            ListTile(
              title: Text('Estado', style: Tipografia.cuerpo1()),
              subtitle: Text('Activo', style: Tipografia.cuerpo2()),
            ),
            ListTile(
              title: Text('Fecha de creacion', style: Tipografia.cuerpo1()),
              subtitle: Text(grupo.fechaCreacion, style: Tipografia.cuerpo2()),
            ),
            ListTile(
              title: Text('Fecha finalizacion', style: Tipografia.cuerpo1()),
              subtitle: Text(
                '${grupo.fechaFinalizacion}',
                style: Tipografia.cuerpo2(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
