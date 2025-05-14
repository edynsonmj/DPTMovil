import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Widgetlistagrupos extends StatefulWidget {
  CursoEntidad curso;
  Widgetlistagrupos({super.key, required this.curso});

  @override
  State<StatefulWidget> createState() {
    return _WidgetListaGruposState();
  }
}

class _WidgetListaGruposState extends State<Widgetlistagrupos> {
  @override
  void initState() {
    super.initState();
    super.initState();
    Future.microtask(() {
      final vmGrupo = Provider.of<Gruposviewmodel>(context, listen: false);
      vmGrupo.listarGruposDe(
        widget.curso.tituloCategoria,
        widget.curso.nombreCurso,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Gruposviewmodel>(
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

        if (vm.getListaGrupos == null) {
          return Center(
            child: Text(
              "Informacion no encontrada (null)",
              style: Tipografia.cuerpo1(color: ColorTheme.error),
            ),
          );
        }

        if (vm.getListaGrupos!.isEmpty) {
          return Center(
            child: Text(
              "Aun no hay grupos para este curso",
              style: Tipografia.cuerpo1(color: ColorTheme.error),
            ),
          );
        }

        return mostrarGrupos(vm.getListaGrupos!);
      },
    );
  }

  Widget mostrarGrupos(List<Grupoentidad> lista) {
    return ListView.builder(
      shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
      physics: const NeverScrollableScrollPhysics(), // Desactiva scroll interno
      itemCount: lista.length, // Cambia esto según tu lista
      itemBuilder: (BuildContext context, int index) {
        final Grupoentidad grupo = lista[index];
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
  }
}
