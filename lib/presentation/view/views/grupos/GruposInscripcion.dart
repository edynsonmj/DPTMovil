import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Gruposinscripcion extends StatefulWidget {
  String alumnoId;
  Gruposinscripcion({super.key, required this.alumnoId});
  @override
  State<StatefulWidget> createState() {
    return _GrupoInscripcionState();
  }
}

class _GrupoInscripcionState extends State<Gruposinscripcion> {
  @override
  void initState() {
    super.initState();
    //los vms los crea la ruta gruposDisponiblesInscripcion. La carga se
    //encadena aqui una sola vez (fase 6c): primero la lista y, con ella, los
    //horarios y el estado de inscripcion de cada grupo
    final grupos = context.read<Gruposviewmodel>();
    final horarios = context.read<Horariosviewmodel>();
    final inscripcion = context.read<Inscripcionviewmodel>();
    Future.microtask(() async {
      await grupos.listarGruposDisponiblesInscripcion();
      final lista = grupos.getListaGrupos ?? [];
      horarios.cargarHorariosDe(lista);
      inscripcion.cargarEstados(widget.alumnoId, lista);
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

  //cada parte de la tarjeta lee solo el estado de su grupo con
  //context.select: cuando llega un horario o cambia una inscripcion se
  //reconstruye esa tarjeta, sin volver a pedir nada al backend
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
            return Tarjeta(
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
            );
          },
        ),
        Builder(
          builder: (context) {
            final estado = context
                .select<Inscripcionviewmodel, EstadoSeccion<bool>>(
                  (vm) => vm.estadoDe(grupo),
                );
            final procesando = context.select<Inscripcionviewmodel, bool>(
              (vm) => vm.procesando(grupo),
            );
            if (estado.cargando) {
              return Center(child: CircularProgressIndicator());
            }
            final bool inscrito = estado.datos;
            return Positioned(
              top: 165,
              child: FilledButton.icon(
                label: Text(inscrito ? 'Quitar matrícula' : 'Matricular'),
                icon: Icon(inscrito ? Icons.cancel : Icons.view_agenda),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      inscrito ? ColorTheme.error : ColorTheme.secondary,
                ),
                //deshabilitado mientras su operacion esta en camino (J4)
                onPressed:
                    procesando
                        ? null
                        : () => _matricularODesvincular(grupo, inscrito),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _matricularODesvincular(Grupoentidad grupo, bool inscrito) async {
    final vm = context.read<Inscripcionviewmodel>();
    final inscripcion = Inscripcionentidad(
      alumnoId: widget.alumnoId,
      categoria: grupo.categoria,
      curso: grupo.curso,
      anio: grupo.anio,
      iterable: grupo.iterable,
    );
    final resultado =
        inscrito
            ? await vm.desvincularInscripcion(inscripcion)
            : await vm.agregarIncripcion(inscripcion);
    await _mostrarResultado(resultado, inscrito: !inscrito);
  }

  //sin horarios (o si su peticion fallo) la tarjeta queda sin descripcion
  String _descripcionHorarios(List<Horarioentidad> horarios) {
    String descripcion = '';
    for (Horarioentidad horario in horarios) {
      descripcion =
          descripcion +
          '${horario.dia}: ${horario.horaInicio} - ${horario.horaFin} \n';
    }
    return descripcion;
  }

  //el vm ya interpreto la respuesta: la vista solo decide que mostrar, y
  //espera el dialogo para no usar un context que ya no sirve
  Future<void> _mostrarResultado(
    Resultado<void> resultado, {
    required bool inscrito,
  }) async {
    if (!mounted) return;
    switch (resultado) {
      case Exito():
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(
                titulo: "Operacion exitosa",
                mensaje:
                    inscrito
                        ? "Te has inscrito al grupo"
                        : "Se quito tu matricula del grupo",
              ),
        );
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                codigo: codigo,
                mensaje: mensaje,
                titulo: "Error en la operacion",
              ),
        );
    }
  }
}
