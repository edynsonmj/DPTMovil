import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogCargando.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GruposAsignados extends StatefulWidget {
  String instructorId;
  GruposAsignados({super.key, required this.instructorId});
  @override
  State<StatefulWidget> createState() {
    return _GrupoAsignadosState();
  }
}

class _GrupoAsignadosState extends State<GruposAsignados> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vm = Provider.of<Gruposviewmodel>(context, listen: false);
      vm.listarGruposInstructor(widget.instructorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Grupos asignados'),
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
    Inscripcionentidad inscripcion = Inscripcionentidad(
      alumnoId: widget.instructorId,
      categoria: grupo.categoria,
      curso: grupo.curso,
      anio: grupo.anio,
      iterable: grupo.iterable,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Consumer<Horariosviewmodel>(
          builder: (context, vmHorarios, _) {
            return FutureBuilder(
              future: vmHorarios.listarHorariosGrupo(
                grupo.categoria,
                grupo.curso,
                grupo.anio,
                grupo.iterable,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                RespuestaModelo respuesta = snapshot.data!;
                List<Horarioentidad> listaHorarios =
                    respuesta.datos as List<Horarioentidad>;
                String descripcion = '';
                for (Horarioentidad horario in listaHorarios) {
                  descripcion =
                      descripcion +
                      '${horario.dia}: ${horario.horaInicio} - ${horario.horaFin} \n';
                }
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRutas.grupo,
                      arguments: grupo,
                    );
                  },
                  child: Tarjeta(
                    atrTitulo: '${grupo.curso}-${grupo.anio}-${grupo.iterable}',
                    atrInfoPie: grupo.categoria,
                    idImagen: grupo.imagen,
                    atrDescripcion: descripcion,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
