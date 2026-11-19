import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/routes/accesoRutas.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/clase_grupoArgumentos.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/utils/Utilidades.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//las clases las carga el vm de la pantalla al entrar (ruta grupo); este
//widget solo las pinta y delega agregar y eliminar
class Widgetlistaclases extends StatelessWidget {
  const Widgetlistaclases({super.key});

  @override
  Widget build(BuildContext context) {
    //solo se reconstruye cuando cambia la seccion de clases del vm
    final seccion = context
        .select<DetalleGrupoViewModel, EstadoSeccion<List<Claseentidad>>>(
          (vm) => vm.clases,
        );
    if (seccion.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (seccion.error != null) {
      return Center(
        child: Text(
          seccion.error!,
          style: Tipografia.cuerpo1(color: ColorTheme.error),
        ),
      );
    }
    //agregar, eliminar y tomar asistencia solo para quien dicta la clase
    //(AS-01); la ruta tambien lo comprueba (AccesoRutas)
    final dicta = context.select<AutenticacionViewModel, bool>(
      (vm) => AccesoRutas.dictaClase(vm.perfilSesion?.role),
    );
    return mostrarClases(context, seccion.datos, dicta);
  }

  Widget mostrarClases(
    BuildContext context,
    List<Claseentidad> lista,
    bool dicta,
  ) {
    return Column(
      children: [
        Text('Clases', style: Tipografia.h6()),
        if (dicta)
          OutlinedButton.icon(
            //el formulario es otra ruta con su propio vm: recibe el grupo como
            //argumento y, si vuelve con true, esta pantalla recarga sus clases
            onPressed: () async {
              final vm = context.read<DetalleGrupoViewModel>();
              final registrada = await Navigator.pushNamed(
                context,
                AppRutas.formularioClase,
                arguments: vm.grupo,
              );
              if (registrada == true) {
                vm.cargarClases();
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
                return mostrarTarjeta(context, clase, dicta);
              },
            ),
      ],
    );
  }

  Widget mostrarTarjeta(BuildContext context, Claseentidad clase, bool dicta) {
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
          if (dicta)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => _eliminar(context, clase),
                icon: Icon(Icons.close),
              ),
            ),
        ],
      ),
      onTap:
          !dicta
              ? null
              : () {
                Navigator.pushNamed(
                  context,
                  AppRutas.clase,
                  arguments: ClaseGrupoargumentos(
                    clase: clase,
                    grupo: context.read<DetalleGrupoViewModel>().grupo,
                  ),
                );
              },
    );
  }

  //el vm elimina y recarga la lista; la vista solo confirma y muestra el
  //error si lo hay
  Future<void> _eliminar(BuildContext context, Claseentidad clase) async {
    final vm = context.read<DetalleGrupoViewModel>();
    final eliminado = await Utilidades.mostrarDialogoConfirmacion(
      context,
      '¿Esta seguro de eliminar la clase ${clase.codigo} con fecha ${FormatDate.fechaACadena(clase.fecha!, '-')}',
      'Eliminar clase',
    );
    if (!eliminado) return;
    final resultado = await vm.eliminarClase(clase.codigo!);
    if (resultado case Fallo(:final codigo, :final mensaje)) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder:
            (_) => DialogError(
              titulo: 'Error al eliminar clase',
              codigo: codigo,
              mensaje: mensaje,
            ),
      );
    }
  }
}
