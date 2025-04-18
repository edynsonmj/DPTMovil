import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/avatar.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/campoBusqueda.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';

class Alumnoview extends StatefulWidget {
  String alumno;
  Alumnoview({super.key, required this.alumno});

  @override
  State<Alumnoview> createState() {
    // TODO: implement createState
    return _AlumnoState();
  }
}

class _AlumnoState extends State<Alumnoview> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: Bar(title: widget.alumno),
      drawer: Menulateral(),
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
            seccionInscripcion(),
            seccionGrupos(),
            Divider(),
            seccionAtenciones(),
            Divider(),
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
              '123456789',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Identificacion', style: Tipografia.cuerpo2()),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              '9876543210',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Codigo', style: Tipografia.cuerpo2()),
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
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              'FIET',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Facultad', style: Tipografia.cuerpo2()),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(
              'Estudiante',
              style: Tipografia.cuerpo1(),
            ),
            subtitle: Text('Estamento', style: Tipografia.cuerpo2()),
          ),
        ],
      ),
      Positioned(top: 150, right: 8, child: EditIcon())
    ]);
  }

  Widget seccionInscripcion() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Text(
              'Agregar inscripcion',
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
          Text('Grupos activos inscritos',
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

  Widget seccionAtenciones() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text('Atenciones', style: Tipografia.h6(color: ColorTheme.primary)),
          listaAtenciones(),
        ],
      ),
    );
  }

  Widget listaAtenciones() {
    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 20,
        itemBuilder: (BuildContext context, int index) {
          return MiniTarjeta(
            atrTitulo: 'fecha $index',
            atrSubTitulo: 'curso $index',
            existeCampoImagen: false,
            atrIndicador: 'categoria $index',
            existeBotonCierre: true,
          );
        });
  }

  Widget seccionAcciones() {
    return Container(
      child: FilledButton(
          onPressed: () {},
          child: Text('ELIMINAR ALUMNO'),
          style: FilledButton.styleFrom(backgroundColor: ColorTheme.secondary)),
    );
  }
}
