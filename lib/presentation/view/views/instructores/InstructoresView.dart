import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//pantalla "Instructores" del menu del coordinador: la lista que da el backend
//(IT-03). La ruta crea el vm y pide la carga; aqui solo se pinta su estado.
//Antes era una maqueta con 20 tarjetas inventadas, un filtro de categoria
//sin datos detras y un boton de agregar que no hacia nada
class Instructoresview extends StatelessWidget {
  const Instructoresview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Instructores'),
      drawer: Builder(builder: (context) => Menulateral()),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 25),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Listado instructores', style: Tipografia.h5()),
                ),
                const _ListadoInstructores(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListadoInstructores extends StatelessWidget {
  const _ListadoInstructores();

  @override
  Widget build(BuildContext context) {
    final cargando = context.select<InstructoresViewModel, bool>(
      (vm) => vm.cargando,
    );
    final error = context.select<InstructoresViewModel, String?>(
      (vm) => vm.error,
    );
    final instructores = context
        .select<InstructoresViewModel, List<Instructorentidad>>(
          (vm) => vm.instructores,
        );

    if (cargando) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      );
    }
    if (error != null) {
      return Column(
        children: [
          Text('No se pudieron cargar los instructores', style: Tipografia.h6()),
          Text(error, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed:
                () =>
                    context
                        .read<InstructoresViewModel>()
                        .listarYNotificarInstructores(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (instructores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No hay instructores registrados'),
      );
    }
    return ListView.builder(
      //ajusta el tamaño de la lista al contenido y deja el scroll a la pagina
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: instructores.length,
      itemBuilder: (context, index) {
        final instructor = instructores[index];
        final nombre = instructor.nombre ?? instructor.id;
        return InkWell(
          child: MiniTarjeta(
            atrTitulo: nombre,
            atrSubTitulo: instructor.correo ?? '',
            existeCampoImagen: true,
            atrIndicador: instructor.id,
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRutas.instructor,
              arguments: nombre,
            );
          },
        );
      },
    );
  }
}
