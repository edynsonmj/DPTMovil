import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/views/grupo/widgetListaAlumnos.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/alumnosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter/material.dart';

class Claseview extends StatefulWidget {
  final Grupoentidad grupo;
  final Claseentidad clase;

  const Claseview({super.key, required this.grupo, required this.clase});

  @override
  State<Claseview> createState() => _ClaseviewState();
}

class _ClaseviewState extends State<Claseview> {
  final Map<String, bool> asistenciaSeleccionada = {};
  Future<RespuestaModelo>? _futureAtenciones;
  List<Atencionentidad> _atenciones = [];

  @override
  void initState() {
    super.initState();
    Atencionviewmodel vmAtenciones = Atencionviewmodel();
    _futureAtenciones = vmAtenciones.listarAtencionesClase(
      widget.grupo.categoria,
      widget.grupo.curso,
      widget.grupo.anio,
      widget.grupo.iterable,
      widget.clase.codigo!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(
        title:
            '${widget.grupo.curso} ${widget.grupo.anio}.${widget.grupo.iterable}',
      ),
      drawer: Builder(builder: (context)=> Menulateral()),
      body: contenedorSeguro(context),
    );
  }

  Widget contenedorSeguro(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(child: Column(children: [alumnos()])),
    );
  }

  Widget alumnos() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Text('Atenciones', style: Tipografia.h6()),
          ),
          listadoAlumnos(),
          acciones(),
        ],
      ),
    );
  }

  Widget listadoAlumnos() {
    if (_futureAtenciones == null) {
      return Center(child: CircularProgressIndicator());
    }
    return FutureBuilder(
      future: _futureAtenciones,
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
            'Sin información',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }

        if (promesa.data!.codigoHttp != 200) {
          return Text(
            'No se logró obtener información: ${promesa.data!.codigoHttp} - ${promesa.data!.error?.mensaje}',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }

        if (promesa.data!.datos is! List) {
          return Text(
            'Información sobre el curso en formato erróneo',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }

        try {
          List<dynamic> listaDynamic = promesa.data!.datos;
          List<Atencionentidad> lista = listaDynamic.cast<Atencionentidad>();
          _atenciones = lista;
          if (lista.isEmpty) {
            return Text(
              '¡No hay alumnos aún!',
              style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
            );
          }
          return mostrarListadoAlumnos(_atenciones);
        } catch (e) {
          return Text(
            'Información no compatible en la vista',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
      },
    );
  }

  Widget acciones() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FilledButton(
            onPressed: () async {
              Atencionviewmodel vm = Atencionviewmodel();
              RespuestaModelo respuesta = await vm.registrarAtenciones(
                context,
                _atenciones,
                widget.clase.codigo ?? _atenciones[0].idClase,
              );
              if (respuesta.codigoHttp == 200) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return DialogExito(
                      titulo: "Exito",
                      mensaje: "Se ha registrado la info",
                    );
                  },
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return DialogError(
                      titulo: "fallo",
                      mensaje: "no fue posible hacer registror",
                      codigo: 0,
                    );
                  },
                );
              }
            },
            child: Text('Guardar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget mostrarListadoAlumnos(List<Atencionentidad> listado) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: listado.length,
        itemBuilder: (context, index) {
          Atencionentidad atencionentidad = listado[index];
          return atencion(atencionentidad, index);
        },
      ),
    );
  }

  Widget atencion(Atencionentidad atencion, int index) {
    return Row(
      children: [
        Stack(
          children: [
            MiniTarjeta(
              existeCampoImagen: true,
              atrTitulo: atencion.alumno.nombre,
              atrSubTitulo: atencion.alumno.id,
              existeBotonCierre: false,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Checkbox(
                value: _atenciones[index].estaAtendido,
                onChanged: (value) {
                  setState(() {
                    _atenciones[index].estaAtendido =
                        value ?? _atenciones[index].estaAtendido;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
