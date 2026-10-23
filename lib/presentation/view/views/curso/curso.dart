
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formGrupoArgumentos.dart';
import 'package:dpt_movil/presentation/view/views/curso/widgetListaGrupos.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/encabezadoImagen.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';

class Curso extends StatelessWidget {
  final CursoEntidad curso;
  Curso({super.key, required this.curso});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Curso: ${curso.nombreCurso}'),
      body: contenedorSeguro(context),
      drawer: Builder(builder: (context) => Menulateral()),
    );
  }

  Widget contenedorSeguro(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Contenido estático
            //la url la da el vm; el encabezado ya no arma la del servidor
            EncabezadoImagen(
              urlImagen:
                  curso.imagen == null
                      ? null
                      : context.read<Gruposviewmodel>().urlImagen(
                        curso.imagen!,
                      ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  informacionCurso(),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Formgrupoargumentos argumentos = Formgrupoargumentos(
                        curso: curso,
                        esEdicion: false,
                      );
                      final creado = await Navigator.pushNamed(
                        context,
                        AppRutas.grupoFormulario,
                        arguments: argumentos,
                      );
                      //el formulario es otra ruta y no ve el vm de esta
                      //pantalla: al volver con exito se recarga aqui
                      if (creado == true && context.mounted) {
                        context.read<Gruposviewmodel>().listarGruposDe(
                          curso.tituloCategoria,
                          curso.nombreCurso,
                        );
                      }
                    },
                    label: Text('AGREGAR GRUPO'),
                    icon: const Icon(Icons.add),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Grupos del curso', style: Tipografia.h5()),
                  ),
                  // Lista dinámica
                  Widgetlistagrupos(curso: curso),
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
}
