import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
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
    Future.microtask(() {
      //los vms los crea la ruta gruposDisponiblesInscripcion
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
    Inscripcionentidad inscripcion = Inscripcionentidad(
      alumnoId: widget.alumnoId,
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
                  atrDescripcion: _descripcionHorarios(snapshot.data!),
                );
              },
            );
          },
        ),
        Consumer<Inscripcionviewmodel>(
          builder: (context, vm, _) {
            return FutureBuilder<bool>(
              future: vm.validarInscripcion(inscripcion),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                bool estado = snapshot.data!;
                return Positioned(
                  top: 165,
                  child: FilledButton.icon(
                    label: Text(estado ? 'Quitar matrícula' : 'Matricular'),
                    icon: Icon(estado ? Icons.cancel : Icons.view_agenda),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          estado ? ColorTheme.error : ColorTheme.secondary,
                    ),
                    onPressed: () async {
                      final resultado =
                          estado
                              ? await vm.desvincularInscripcion(inscripcion)
                              : await vm.agregarIncripcion(inscripcion);
                      await _mostrarResultado(resultado, inscrito: !estado);
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  //solo pinta los horarios si la peticion salio bien: antes se hacia el cast
  //sin revisar el codigo y un error lanzaba una excepcion en la tarjeta
  String _descripcionHorarios(RespuestaModelo respuesta) {
    if (respuesta.codigoHttp != 200 || respuesta.datos is! List) return '';
    String descripcion = '';
    for (Horarioentidad horario
        in (respuesta.datos as List).cast<Horarioentidad>()) {
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
