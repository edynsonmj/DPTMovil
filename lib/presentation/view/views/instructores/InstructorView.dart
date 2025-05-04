import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/avatar.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';

class Instructorview extends StatefulWidget {
  String instructor;
  Instructorview({super.key, required this.instructor});

  @override
  State<Instructorview> createState() {
    return _InstructorState();
  }
}

class _InstructorState extends State<Instructorview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: widget.instructor),
      drawer: Builder(builder: (context)=> Menulateral()),
      body: contenedorSeguro(),
    );
  }

  Widget contenedorSeguro() {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 25),
        child: contenido(),
      ),
    );
  }

  Widget contenido() {
    return SingleChildScrollView(
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            seccionInformacion(),
            Divider(),
            seccionProrroga(),
            Divider(),
            seccionInscripcion(),
            seccionGrupos(),
            seccionAcciones()
          ],
        );
      }),
    );
  }

  Widget seccionInformacion() {
    return Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Avatar(atrDimension: 120),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              'Edynson Muñoz Jimenez',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Nombre', style: Tipografia.cuerpo2()),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              'Cedula',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Tipo identificacion', style: Tipografia.cuerpo2()),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              '987456321',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Identificacion', style: Tipografia.cuerpo2()),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              'Masculino',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Sexo', style: Tipografia.cuerpo2()),
          ),
        ],
      ),
      Positioned(top: 150, right: 8, child: EditIcon())
    ]);
  }

  Widget seccionProrroga() {
    return Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Carga informacion',
            style: Tipografia.h6(color: ColorTheme.primary),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              '28 de cada mes',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Limite general', style: Tipografia.cuerpo2()),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              '...',
              style: Tipografia.cuerpo1(),
            ),
            subtitle:
                Text('Dias faltantes prorroga', style: Tipografia.cuerpo2()),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              'No definido',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Fecha limite', style: Tipografia.cuerpo2()),
          )
        ],
      ),
      Positioned(top: 30, right: 8, child: EditIcon())
    ]);
  }

  Widget seccionInscripcion() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Text(
              'Agregar grupo',
              style: Tipografia.h6(color: ColorTheme.primary),
            ),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SearchBar(
                  hintText: 'Buscar grupo',
                  leading: Icon(Icons.search),
                )),
          ],
        ));
  }

  Widget seccionGrupos() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text('Grupos asignado al instructor',
              style: Tipografia.h6(color: ColorTheme.primary)),
          listaGrupos(),
        ],
      ),
    );
  }

  Widget listaGrupos() {
    return ListView.builder(
        //ajusta el tamaño de la lista al contenido
        shrinkWrap: true,
        //desactiva el scroll interno
        physics: const NeverScrollableScrollPhysics(),
        //TODO: cambiar valor por el de la longitud lista del provider
        itemCount: 3,
        itemBuilder: (BuildContext context, int index) {
          return MiniTarjeta(
            atrTitulo: 'Grupo $index',
            atrSubTitulo: 'Curso x',
            existeCampoImagen: true,
            existeBotonCierre: true,
            atrIndicador: '20',
          );
        });
  }

  Widget seccionAcciones() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTheme.secondary,
                  side: BorderSide(color: ColorTheme.secondary)),
              child: Text('DESHABILITAR INSTRUCTOR'),
            ),
            FilledButton(
              onPressed: () {},
              style:
                  FilledButton.styleFrom(backgroundColor: ColorTheme.secondary),
              child: Text('ELIMINAR INSTRUCTOR'),
            ),
          ],
        ));
  }
}
