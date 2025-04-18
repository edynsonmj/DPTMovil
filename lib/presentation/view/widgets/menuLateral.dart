import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';

class Menulateral extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return miMenu(context);
  }

  SafeArea miMenu(BuildContext context) {
    return SafeArea(
        child: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
              decoration: BoxDecoration(color: ColorTheme.primary),
              child: Text(
                'Menú de navegación',
                style: Tipografia.h3(color: Colors.white),
              )),
          ListTile(
            leading: Icon(Icons.account_circle_rounded),
            title: Text('Iniciar sesion'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.inicio);
            },
          ),
          ListTile(
            leading: Icon(Icons.home_rounded),
            title: Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.inicio);
            },
          ),
          ListTile(
            leading: Icon(Icons.category_rounded),
            title: Text('Categorias'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.categorias);
            },
          ),
          ListTile(
            leading: Icon(Icons.book_rounded),
            title: Text('Cursos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.cursos);
            },
          ),
          ListTile(
            leading: Icon(Icons.people_rounded),
            title: Text('Alumnos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.alumnos);
            },
          ),
          ListTile(
            leading: Icon(Icons.person_rounded),
            title: Text('Instructores'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.instructores);
            },
          ),
          ListTile(
            leading: Icon(Icons.how_to_reg_rounded),
            title: Text('Inscripciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.InscripcionesGenerales);
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart_rounded),
            title: Text('Estadisticas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.estadisticasGenerales);
            },
          ),
          ListTile(
            leading: Icon(Icons.login_rounded),
            title: Text('Cerrar sesion'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRutas.inicio);
            },
          ),
        ],
      ),
    ));
  }
}
