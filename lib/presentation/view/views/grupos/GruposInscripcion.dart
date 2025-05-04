import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Gruposinscripcion extends StatefulWidget {
  const Gruposinscripcion({super.key});
  @override
  State<StatefulWidget> createState() {
    return _GrupoInscripcionState();
  }
}

class _GrupoInscripcionState extends State<Gruposinscripcion> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vm = Provider.of<Gruposviewmodel>(context, listen: false);
      vm.listarGruposDisponiblesInscripcion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Inscripciones a cursos'),
      drawer: Builder(builder: (context) => Menulateral()),
      body: _contenedorSeguro(),
    );
  }

  Widget _contenedorSeguro() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Consumer<Gruposviewmodel>(
          builder: (context, vm, _) {
            if (vm.cargando) {
              return Center(child: CircularProgressIndicator());
            }
            if (vm.error != null) {
              return Center(
                child: Text(
                  vm.error!,
                  style: Tipografia.cuerpo1(color: ColorTheme.error),
                ),
              );
            }
            if (vm.getListaGrupos == null || vm.getListaGrupos!.isEmpty) {
              return Center(
                child: Text(
                  "No hay datos aun, lista vacia",
                  style: Tipografia.cuerpo1(color: ColorTheme.error),
                ),
              );
            }
            return _listaGrupos(vm);
          },
        ),
      ),
    );
  }

  Widget _listaGrupos(Gruposviewmodel vm) {
    return ListView.builder(
      shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
      //evita scroll interno
      physics: const NeverScrollableScrollPhysics(),
      //la lista se construira segun el tamaño de la lista categorias del viewmodel
      itemCount: vm.getListaGrupos!.length,
      itemBuilder: (context, index) {
        final Grupoentidad grupo = vm.getListaGrupos![index];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [mostrarTarjeta(grupo)],
        );
      },
    );
  }

  Widget mostrarTarjeta(Grupoentidad grupo) {
    return Stack(
      children: [
        Tarjeta(
          atrTitulo: '${grupo.curso}-${grupo.anio}-${grupo.iterable}',
          atrInfoPie: grupo.categoria,
          idImagen: grupo.imagen,
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(onPressed: () {}, icon: EditIcon()),
        ),
      ],
    );
  }
}
