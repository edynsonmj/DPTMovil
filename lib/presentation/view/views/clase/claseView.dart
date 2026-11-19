import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//el Atencionviewmodel lo provee la ruta AppRutas.clase, uno por pantalla, y
//ya empieza a cargar al crearse: esta vista solo pinta y registra
class Claseview extends StatefulWidget {
  final Grupoentidad grupo;
  final Claseentidad clase;

  const Claseview({super.key, required this.grupo, required this.clase});

  @override
  State<Claseview> createState() => _ClaseviewState();
}

class _ClaseviewState extends State<Claseview> {
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
    return Consumer<Atencionviewmodel>(
      builder: (context, vm, _) {
        //antes de la primera carga la lista aun no existe: tambien es espera
        if (vm.cargando || vm.atenciones == null && vm.error == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null) {
          return Text(
            vm.error!,
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
        if (vm.atenciones!.isEmpty) {
          return Text(
            '¡No hay alumnos aún!',
            style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
          );
        }
        return mostrarListadoAlumnos(vm.atenciones!);
      },
    );
  }

  Widget acciones() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Builder(
            builder: (context) {
              //deshabilitado mientras carga, si la carga fallo, si no hay
              //alumnos o si ya hay un envio en camino
              final puede = context.select<Atencionviewmodel, bool>(
                (vm) => vm.puedeRegistrar,
              );
              return FilledButton(
                onPressed: puede ? _guardar : null,
                child: Text('Guardar'),
              );
            },
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

  Future<void> _guardar() async {
    final resultado =
        await context.read<Atencionviewmodel>().registrarAtenciones();
    await _mostrarResultado(resultado);
  }

  //el vm ya interpreto la respuesta: la vista solo decide que mostrar. El
  //dialogo va antes del pop: despues de cerrar la pantalla su context ya no
  //sirve para mostrar nada
  Future<void> _mostrarResultado(Resultado<void> resultado) async {
    if (!mounted) return;
    switch (resultado) {
      case Exito():
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(
                titulo: 'Atenciones registradas',
                mensaje: 'Se ha registrado la asistencia de la clase.',
              ),
        );
        if (mounted) Navigator.pop(context);
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                titulo: 'Error al registrar atenciones',
                codigo: codigo,
                mensaje: mensaje,
              ),
        );
    }
  }

  Widget mostrarListadoAlumnos(List<Atencionentidad> listado) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: listado.length,
        itemBuilder: (context, index) {
          return atencion(listado[index], index);
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
                value: atencion.estaAtendido,
                onChanged: (value) {
                  if (value == null) return;
                  context.read<Atencionviewmodel>().marcarAsistencia(
                    index,
                    value,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
