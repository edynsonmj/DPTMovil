import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
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
  Future<List<Atencionentidad>>? _futureAtenciones;
  List<Atencionentidad> _atenciones = [];

  @override
  void initState() {
    super.initState();
    _futureAtenciones = _cargarAtencionesConAlumnos();
  }

  Future<List<Atencionentidad>> _cargarAtencionesConAlumnos() async {
    final vmAtenciones = Atencionviewmodel();
    final vmAlumnos = Alumnosviewmodel();

    final respuestas = await Future.wait([
      vmAtenciones.obtenerAtencionesClaseById(widget.clase.codigo!),
      vmAlumnos.listarAlumnosGrupo(
        widget.grupo.categoria,
        widget.grupo.curso,
        widget.grupo.anio,
        widget.grupo.iterable,
      ),
    ]);

    final respuestaAtenciones = respuestas[0];
    final respuestaAlumnos = respuestas[1];

    if (respuestaAlumnos.codigoHttp != 200) {
      throw Exception(
        'No se logro obtener alumnos: ${respuestaAlumnos.codigoHttp} - ${respuestaAlumnos.error?.mensaje}',
      );
    }

    if (respuestaAlumnos.datos is! List) {
      throw Exception('La informacion de alumnos no tiene el formato esperado');
    }

    final listaAlumnos = (respuestaAlumnos.datos as List).cast<Alumnoentidad>();
    final List<Atencionentidad> listaAtenciones;

    if (respuestaAtenciones.codigoHttp == 200 &&
        respuestaAtenciones.datos is List) {
      listaAtenciones =
          (respuestaAtenciones.datos as List).cast<Atencionentidad>();
    } else {
      listaAtenciones = [];
    }

    final Map<String, Atencionentidad> atencionesPorAlumno = {
      for (final atencion in listaAtenciones) atencion.idPerfil: atencion,
    };

    return listaAlumnos.map((alumno) {
      final atencionExistente = atencionesPorAlumno[alumno.id];
      if (atencionExistente != null) {
        atencionExistente.alumno = alumno;
        return atencionExistente;
      }

      return Atencionentidad(
        idPerfil: alumno.id,
        alumno: alumno,
        idClase: widget.clase.codigo!,
        estaAtendido: false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(
        title:
            '${widget.grupo.curso} ${widget.grupo.anio}.${widget.grupo.iterable}',
      ),
      drawer: Builder(builder: (context) => Menulateral()),
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

    return FutureBuilder<List<Atencionentidad>>(
      future: _futureAtenciones,
      builder: (context, promesa) {
        if (promesa.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (promesa.hasError) {
          return Text(
            'Error: ${promesa.error}',
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }

        final lista = promesa.data ?? [];
        _atenciones = lista;

        if (lista.isEmpty) {
          return Text(
            'No hay alumnos aun!',
            style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
          );
        }

        return mostrarListadoAlumnos(lista);
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
              if (_atenciones.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return DialogError(
                      titulo: 'fallo',
                      mensaje: 'No hay alumnos para registrar asistencia',
                      codigo: 0,
                    );
                  },
                );
                return;
              }

              final vm = Atencionviewmodel();
              final respuesta = await vm.registrarAtenciones(
                context,
                _atenciones,
                widget.clase.codigo ?? _atenciones[0].idClase,
              );

              if (!context.mounted) {
                return;
              }

              if (respuesta.codigoHttp == 200) {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) {
                    return DialogExito(
                      titulo: 'Exito',
                      mensaje: 'Se ha registrado la info',
                    );
                  },
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return DialogError(
                      titulo: 'fallo',
                      mensaje: 'no fue posible hacer registror',
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
            style: FilledButton.styleFrom(
              backgroundColor: ColorTheme.secondary,
            ),
            child: Text('Cancelar'),
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
          final atencionEntidad = listado[index];
          return atencion(atencionEntidad, index);
        },
      ),
    );
  }

  Widget atencion(Atencionentidad atencion, int index) {
    final alumno = atencion.alumno;
    if (alumno == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Stack(
          children: [
            MiniTarjeta(
              existeCampoImagen: true,
              atrTitulo: alumno.nombre,
              atrSubTitulo: alumno.id,
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
