import 'dart:typed_data';

import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaAlumnos.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaClases.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaHorarios.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/campoBusqueda.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/encabezadoImagen.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:provider/provider.dart';

class Grupo extends StatelessWidget {
  Grupoentidad grupo;
  Grupo({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: '${grupo.curso} ${grupo.anio}.${grupo.iterable}'),
      drawer: Builder(builder: (context)=> Menulateral()),
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
        const Widgetlistahorarios(),
        const Widgetlistaalumnos(),
        const Widgetlistaclases(),
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

  Widget informacionCurso(BuildContext context) {
    //el vm lo crea la ruta grupo y carga el curso al entrar; solo se
    //reconstruye cuando cambia esta seccion
    final seccion = context
        .select<DetalleGrupoViewModel, EstadoSeccion<CursoEntidad?>>(
          (vm) => vm.curso,
        );
    if (seccion.cargando) {
      return CircularProgressIndicator();
    }
    if (seccion.error != null || seccion.datos == null) {
      return Text(
        'no se logro obtener informacion: ${seccion.error}',
        style: Tipografia.cuerpo1(color: ColorTheme.error),
      );
    }
    return mostrarInfoCurso(seccion.datos!);
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
