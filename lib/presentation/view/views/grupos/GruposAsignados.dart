import 'package:dpt_movil/domain/entities/diaSemana.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
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
    //los vms los crea la ruta gruposAsignados. La carga se encadena aqui una
    //sola vez (fase 6c): primero la lista y, con ella, los horarios
    final grupos = context.read<Gruposviewmodel>();
    final horarios = context.read<Horariosviewmodel>();
    Future.microtask(() async {
      await grupos.listarGruposInstructor(widget.instructorId);
      horarios.cargarHorariosDe(grupos.getListaGrupos ?? []);
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

  //la tarjeta lee solo los horarios de su grupo con context.select: cuando
  //llegan se reconstruye esa tarjeta, sin volver a pedir nada al backend
  Widget mostrarTarjeta(Grupoentidad grupo) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Builder(
          builder: (context) {
            final horarios = context.select<
              Horariosviewmodel,
              EstadoSeccion<List<Horarioentidad>>
            >((vm) => vm.horariosDe(grupo));
            if (horarios.cargando) {
              return Center(child: CircularProgressIndicator());
            }
            return InkWell(
              onTap: () {
                Navigator.pushNamed(context, AppRutas.grupo, arguments: grupo);
              },
              child: Tarjeta(
                atrTitulo: '${grupo.curso}-${grupo.anio}-${grupo.iterable}',
                atrInfoPie: grupo.categoria,
                //la url la da el vm; la tarjeta ya no arma la del servidor
                atrUrlImagen:
                    grupo.imagen == null
                        ? ''
                        : context.read<Gruposviewmodel>().urlImagen(
                          grupo.imagen!,
                        ),
                atrDescripcion: _descripcionHorarios(horarios.datos),
              ),
            );
          },
        ),
      ],
    );
  }

  //sin horarios (o si su peticion fallo) la tarjeta queda sin descripcion
  String _descripcionHorarios(List<Horarioentidad> horarios) {
    String descripcion = '';
    for (Horarioentidad horario in horarios) {
      descripcion =
          descripcion +
          '${DiaSemana.etiqueta(horario.dia)}: ${horario.horaInicio} - ${horario.horaFin} \n';
    }
    return descripcion;
  }
}
