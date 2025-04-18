import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';

class Instructoresview extends StatefulWidget {
  const Instructoresview({super.key});

  @override
  State<Instructoresview> createState() {
    return _AlumnosState();
  }
}

class _AlumnosState extends State<Instructoresview> {
  String? _categoria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Instructores'),
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
          label: Text('AGREGAR INSTRUCTOR'),
          icon: Icon(Icons.add)),
    );
  }

  Widget seccionFiltros() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            filtro(),
          ],
        ));
  }

  Widget filtro() {
    DropdownMenu menu = DropdownMenu(
        helperText: 'seleccione una categoria',
        hintText: 'Sin seleccion',
        textAlign: TextAlign.center,
        onSelected: (value) {
          setState(() {
            _categoria = value;
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

  Widget seccionListado() {
    return Container(
      child: Column(
        children: [
          Text(
            'Listado instructores',
            style: Tipografia.h5(),
          ),
          //listadoInstructores(),
          listadoInstructores2()
        ],
      ),
    );
  }

  Widget listadoInstructores() {
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
              atrTitulo: 'Instructor $index',
              atrSubTitulo: 'Reportó: 5/6/2025',
              existeCampoImagen: true,
              atrIndicadorEstado: 'Activo',
              atrIndicador: '123456789',
            ),
            onTap: () {
              Navigator.pushNamed(context, AppRutas.instructor,
                  arguments: 'instructor $index');
            },
          );
        });
  }

  Widget listadoInstructores2() {
    return ListView(
      shrinkWrap: true,
      children: [
        InkWell(
          child: MiniTarjeta(
            atrTitulo: 'Edynson Muñoz',
            atrSubTitulo: 'Reportó: 5/6/2025',
            existeCampoImagen: true,
            atrIndicadorEstado: 'Activo',
            atrIndicador: '987456321',
          ),
          onTap: () {
            Navigator.pushNamed(context, AppRutas.instructor,
                arguments: 'Edynson Muñoz');
          },
        ),
        InkWell(
          child: MiniTarjeta(
            atrTitulo: 'Pablo Megia',
            atrSubTitulo: 'Reportó: 5/6/2025',
            existeCampoImagen: true,
            atrIndicadorEstado: 'Activo',
            atrIndicador: '13456789',
          ),
          onTap: () {
            Navigator.pushNamed(context, AppRutas.instructor,
                arguments: 'Pablo Megia');
          },
        )
      ],
    );
  }
}
