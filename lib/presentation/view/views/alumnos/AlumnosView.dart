import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';

class Alumnosview extends StatefulWidget {
  const Alumnosview({super.key});

  @override
  State<Alumnosview> createState() {
    return _AlumnosState();
  }
}

class _AlumnosState extends State<Alumnosview> {
  String? _categoria;
  String? _curso;
  String? _grupo;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Alumnos'),
      drawer: Menulateral(),
      body: contenedorSeguro(),
    );
  }

  Widget contenedorSeguro() {
    return SafeArea(
        child: Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      child: contenido(),
    ));
  }

  Widget contenido() {
    return SingleChildScrollView(
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            seccionAgregar(),
            //TODO: apartado para busqueda
            seccionFiltros(),
            Divider(),
            seccionListado()
          ],
        );
      }),
    );
  }

  Widget seccionAgregar() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
          onPressed: () {},
          label: Text('AGREGAR ALUMNO'),
          icon: Icon(Icons.add)),
    );
  }

  Widget seccionFiltros() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            filtroCategoria(),
            if (_categoria != null) filtroCurso(),
            if (_curso != null && _categoria != null) filtroGrupo(),
          ],
        ));
  }

  Widget filtroCategoria() {
    DropdownMenu menu = DropdownMenu(
        helperText: 'seleccione una categoria',
        hintText: 'Sin seleccion',
        textAlign: TextAlign.center,
        onSelected: (value) {
          setState(() {
            _categoria = value;
            if (_categoria == null) {
              _curso = null;
              _grupo = null;
            }
          });
        },
        dropdownMenuEntries: [
          DropdownMenuEntry(value: null, label: 'sin seleccion'),
          DropdownMenuEntry(value: 'seleccionado', label: 'seleccionado'),
          DropdownMenuEntry(value: 'semillero', label: 'semillero'),
          DropdownMenuEntry(value: 'recreativo', label: 'recreativo'),
        ]);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: menu,
    );
  }

  Widget filtroCurso() {
    DropdownMenu menu = DropdownMenu(
        helperText: 'seleccione un curso',
        hintText: 'Sin seleccion',
        textAlign: TextAlign.center,
        onSelected: (value) {
          setState(() {
            _curso = value;
            if (_curso == null) {
              _grupo = null;
            }
          });
        },
        dropdownMenuEntries: [
          DropdownMenuEntry(value: null, label: 'sin seleccion'),
          DropdownMenuEntry(value: 'curso 1', label: 'curso 1'),
          DropdownMenuEntry(value: 'curso 2', label: 'curso 2'),
          DropdownMenuEntry(value: 'curso 3', label: 'curso 3'),
        ]);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: menu,
    );
  }

  Widget filtroGrupo() {
    DropdownMenu menu = DropdownMenu(
        helperText: 'seleccione un grupo',
        hintText: 'Sin seleccion',
        textAlign: TextAlign.center,
        onSelected: (value) {
          setState(() {
            _grupo = value;
          });
        },
        dropdownMenuEntries: [
          DropdownMenuEntry(value: null, label: 'sin seleccion'),
          DropdownMenuEntry(value: 'grupo 1', label: 'grupo 1'),
          DropdownMenuEntry(value: 'grupo 2', label: 'grupo 2'),
          DropdownMenuEntry(value: 'grupo 3', label: 'grupo 3'),
        ]);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: menu,
    );
  }

  Widget seccionListado() {
    return Container(
      child: Column(
        children: [
          Text(
            'Listado alumno',
            style: Tipografia.h5(),
          ),
          //listadoAlumnos(),
          listadoAlumnos2(),
        ],
      ),
    );
  }

  Widget listadoAlumnos() {
    return ListView.builder(
        //ajusta el tamaño de la lista al contenido
        shrinkWrap: true,
        //desactiva el scroll interno
        physics: const NeverScrollableScrollPhysics(),
        //TODO: cambiar valor por el de la longitud lista del provider
        itemCount: 20,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            child: MiniTarjeta(
              atrTitulo: 'alumno $index',
              atrSubTitulo: '2165478$index',
              existeCampoImagen: true,
              atrIndicadorEstado: 'tipo',
              atrIndicador: 'facultad',
            ),
            onTap: () {
              Navigator.pushNamed(context, AppRutas.alumno,
                  arguments: 'alumno $index');
            },
          );
        });
  }

  Widget listadoAlumnos2() {
    return ListView(
      shrinkWrap: true,
      children: [
        InkWell(
          child: MiniTarjeta(
            atrTitulo: 'Edynson Muñoz Jimenez',
            atrSubTitulo: '123456789',
            existeCampoImagen: true,
            atrIndicadorEstado: 'Estudiante',
            atrIndicador: 'FIET',
          ),
          onTap: () {
            Navigator.pushNamed(context, AppRutas.alumno,
                arguments: 'Edynson Muñoz Jimenez');
          },
        ),
        InkWell(
          child: MiniTarjeta(
            atrTitulo: 'Pepito perez',
            atrSubTitulo: '123456784',
            existeCampoImagen: true,
            atrIndicadorEstado: 'Administrativo',
            atrIndicador: 'FIET',
          ),
          onTap: () {
            Navigator.pushNamed(context, AppRutas.alumno,
                arguments: 'Edynson Muñoz Jimenez');
          },
        ),
        InkWell(
          child: MiniTarjeta(
            atrTitulo: 'Miguel Angel',
            atrSubTitulo: '123456787',
            existeCampoImagen: true,
            atrIndicadorEstado: 'Estudiante',
            atrIndicador: 'FIET',
          ),
          onTap: () {
            Navigator.pushNamed(context, AppRutas.alumno,
                arguments: 'Edynson Muñoz Jimenez');
          },
        )
      ],
    );
  }
}
