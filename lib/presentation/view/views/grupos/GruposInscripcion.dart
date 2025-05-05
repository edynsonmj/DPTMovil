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
                RespuestaModelo respuesta = snapshot.data!;
                List<Horarioentidad> listaHorarios =
                    respuesta.datos as List<Horarioentidad>;
                String descripcion = '';
                for (Horarioentidad horario in listaHorarios) {
                  descripcion =
                      descripcion +
                      '${horario.dia}: ${horario.horaInicio} - ${horario.horaFin} \n';
                }
                return Tarjeta(
                  atrTitulo: '${grupo.curso}-${grupo.anio}-${grupo.iterable}',
                  atrInfoPie: grupo.categoria,
                  idImagen: grupo.imagen,
                  atrDescripcion: descripcion,
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
                      if (estado) {
                        await vm.desvincularInscripcion(inscripcion);
                      } else {
                        await vm.agregarIncripcion(inscripcion);
                        if (vm.cargando) {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return DialogCargando();
                            },
                          );
                        }
                        if (vm.codigoInsercion == 201) {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return DialogExito(
                                titulo: "Operacion exitosa",
                                mensaje: "Te has inscrito al grupo",
                              );
                            },
                          );
                        }
                        if (vm.error != null) {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return DialogError(
                                codigo: vm.codigoInsercion ?? 0,
                                mensaje: vm.error ?? "Error desconocido",
                                titulo: "Error en la operacion",
                              );
                            },
                          );
                        }
                      }
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
}
