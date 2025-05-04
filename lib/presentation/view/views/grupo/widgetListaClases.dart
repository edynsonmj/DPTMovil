import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/clase_grupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/utils/Utilidades.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Widgetlistaclases extends StatefulWidget {
  final Grupoentidad grupo;
  const Widgetlistaclases({super.key, required this.grupo});

  @override
  State<Widgetlistaclases> createState() => _WidgetlistaclasesState();
}

class _WidgetlistaclasesState extends State<Widgetlistaclases> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vmClase = Provider.of<Clasesviewmodel>(context, listen: false);
      vmClase.inicializarGrupo(
        widget.grupo.categoria,
        widget.grupo.curso,
        widget.grupo.anio,
        widget.grupo.iterable,
      );
      vmClase.listarYNotificarClases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Clasesviewmodel>(
      builder: (context, vm, _) {
        if (vm.cargando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.error != null) {
          return Center(
            child: Text(
              vm.error!,
              style: Tipografia.cuerpo1(color: ColorTheme.error),
            ),
          );
        }

        return mostrarClases(vm.clases);
      },
    );
  }

  Widget mostrarClases(List<Claseentidad> lista) {
    return Column(
      children: [
        Text('Clases', style: Tipografia.h6()),
        OutlinedButton.icon(
          onPressed: () async {
            Claseentidad entidad = Claseentidad(
              idGrupoCategoria: widget.grupo.categoria,
              idGrupoCurso: widget.grupo.curso,
              idGrupoAnio: widget.grupo.anio,
              idGrupoIterable: widget.grupo.iterable,
              idInstructor: "1234567890",
              fecha: null,
              horas: null,
              minutos: null,
              eliminado: 0,
            );
            final resultado = await Navigator.pushNamed(
              context,
              AppRutas.formularioClase,
              arguments: entidad,
            );

            if (resultado == true) {
              final vmClase = Provider.of<Clasesviewmodel>(
                context,
                listen: false,
              );
              vmClase.listarYNotificarClases();
            }
          },
          label: Text('AGREGAR CLASE'),
          icon: Icon(Icons.add),
        ),
        (lista.isEmpty)
            ? Text(
              'No hay clases aún!',
              style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                Claseentidad clase = lista[index];
                return mostrarTarjeta(context, clase);
              },
            ),
      ],
    );
  }

  Widget mostrarTarjeta(BuildContext context, Claseentidad clase) {
    return InkWell(
      child: Stack(
        children: [
          MiniTarjeta(
            atrTitulo:
                'Fecha clase: ${FormatDate.fechaACadena(clase.fecha!, "-")}',
            atrSubTitulo: 'Tiempo: ${clase.horas}h:${clase.minutos}m',
            existeBotonCierre: false,
            existeCampoImagen: false,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () async {
                final eliminado = await Utilidades.mostrarDialogoConfirmacion(
                  context,
                  '¿Esta seguro de eliminar la clase ${clase.codigo} con fecha ${FormatDate.fechaACadena(clase.fecha!, '-')}',
                  'Eliminar clase',
                );
                if (eliminado) {
                  final vmClase = Provider.of<Clasesviewmodel>(
                    context,
                    listen: false,
                  );
                  await vmClase.eliminarClase(clase.codigo!);
                  await vmClase.listarYNotificarClases();
                }
              },
              icon: Icon(Icons.close),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRutas.clase,
          arguments: ClaseGrupoargumentos(clase: clase, grupo: widget.grupo),
        );
      },
    );
  }

  Future<bool> _confirmarEliminacion(
    BuildContext context,
    Claseentidad clase,
  ) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirmar eliminación'),
              content: Text(
                '¿Está seguro de eliminar la clase ${clase.codigo} del ${clase.fecha}?',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(true); // Confirmado
                    final vmClase = Provider.of<Clasesviewmodel>(
                      context,
                      listen: false,
                    );
                    await vmClase.eliminarClase(clase.codigo!);
                    await vmClase.listarYNotificarClases();
                  },
                  child: Text('Eliminar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancelar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
