import 'dart:typed_data';

import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/encabezadoImagen.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';

class Curso extends StatelessWidget {
  CursoEntidad curso;
  Curso({super.key, required this.curso});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Curso: ${curso.nombreCurso}'),
      body: contenedorSeguro(context),
      drawer: Menulateral(),
    );
  }

  Widget contenedorSeguro(context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Contenido estático
            EncabezadoImagen(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  informacionCurso(),
                  OutlinedButton.icon(
                    onPressed: () {},
                    label: Text('AGREGAR GRUPO'),
                    icon: const Icon(Icons.add),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Grupos del curso', style: Tipografia.h5()),
                  ),
                  // Lista dinámica
                  listaGrupos(context),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorTheme.secondary,
                        side: BorderSide(color: ColorTheme.secondary),
                      ),
                      child: Text('DESHABILITAR CURSO'),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: Text('ELIMINAR CURSO'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorTheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //muestra la informacion del curso
  Widget informacionCurso() {
    Column datos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('Curso', style: Tipografia.cuerpo1()),
          subtitle: Text(curso.nombreCurso, style: Tipografia.cuerpo2()),
          contentPadding: EdgeInsets.symmetric(),
        ),
        ListTile(
          title: Text('Deporte', style: Tipografia.cuerpo1()),
          subtitle: Text(curso.nombreDeporte, style: Tipografia.cuerpo2()),
          contentPadding: EdgeInsets.symmetric(),
        ),
        ListTile(
          title: Text('Tipo de curso', style: Tipografia.cuerpo1()),
          subtitle: Text(curso.tituloCategoria, style: Tipografia.cuerpo2()),
          contentPadding: EdgeInsets.symmetric(),
        ),
        ListTile(
          title: Text('Descripción', style: Tipografia.cuerpo1()),
          contentPadding: EdgeInsets.symmetric(),
          subtitle: Text(style: Tipografia.cuerpo2(), curso.descripcion),
        ),
      ],
    );

    Container contenedor = Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: datos,
    );

    return Stack(
      children: [contenedor, Positioned(top: 30, right: 8, child: EditIcon())],
    );
  }

  Widget listaGrupos(context) {
    Gruposviewmodel viewModel = Gruposviewmodel();
    return FutureBuilder(
      future: viewModel.listarGruposDe(
        context,
        curso.tituloCategoria,
        curso.nombreCurso,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No hay grupos disponibles');
        }
        final List<Grupoentidad> lista = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
          physics:
              const NeverScrollableScrollPhysics(), // Desactiva scroll interno
          itemCount: lista.length, // Cambia esto según tu lista
          itemBuilder: (BuildContext context, int index) {
            final Grupoentidad grupo = lista[index];
            //TODO: establecer inwell para comportamiento al tocar
            return InkWell(
              onTap: () {
                Navigator.pushNamed(context, AppRutas.grupo, arguments: grupo);
              },
              child: MiniTarjeta(
                existeCampoImagen: true,
                atrTitulo: '${grupo.anio}.${grupo.iterable} ${grupo.curso}',
                atrSubTitulo: grupo.categoria,
                atrIndicador: '6/20',
                atrIndicadorEstado: 'activo',
              ),
            );
          },
        );
      },
    );
  }
}
