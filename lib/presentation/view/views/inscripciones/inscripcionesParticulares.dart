import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/view/widgets/alertFechas.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/periodoInscripcionViewModel.dart';
import 'package:provider/provider.dart';

//pantalla del coordinador para abrir, programar y cerrar las inscripciones
//de cada grupo (plan de abrir inscripciones, fase 4). Los vms los crea la
//ruta InscripcionesParticulares y ya empiezan a cargar: esta vista solo
//pinta, filtra y delega las operaciones
class InscripcionesParticularesView extends StatefulWidget {
  const InscripcionesParticularesView({super.key});

  @override
  State<InscripcionesParticularesView> createState() {
    return _InscripcionesParticularesState();
  }
}

class _InscripcionesParticularesState
    extends State<InscripcionesParticularesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(title: 'Inscripciones'),
      body: contenedorSeguro(context),
    );
  }

  SafeArea contenedorSeguro(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 25),
        child: contenido(),
      ),
    );
  }

  Widget contenido() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          linkInscripcionesGenerales(),
          descripcion(),
          filtro(),
          listadoGrupos(),
        ],
      ),
    );
  }

  Widget linkInscripcionesGenerales() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRutas.InscripcionesGenerales);
          },
          child: Text('INSCRIPCIONES GENERALES'),
        ),
      ],
    );
  }

  Widget descripcion() {
    return Column(
      children: [
        ListTile(
          title: Text('Configuracion especifica', style: Tipografia.cuerpo1()),
          subtitle: Text(
            'Asigne a cada grupo en particular el estado de las inscripciones, las inscripciones solo pueden ser asignadas a grupos activos',
            style: Tipografia.cuerpo2(),
          ),
        ),
        ListTile(
          subtitle: Text(
            'Filtre segun la categoria de los grupos a manipular',
            style: Tipografia.cuerpo2(),
          ),
        ),
      ],
    );
  }

  //las categorias salen del vm de categorias (lista ya cargada por la ruta);
  //el filtro lo aplica el vm de periodos sobre los grupos que ya tiene
  Widget filtro() {
    final titulos = context.select<CategoriaViewModel, List<String>>(
      (vm) => vm.titulos,
    );
    DropdownMenu menu = DropdownMenu(
      hintText: 'Todas',
      helperText: 'seleccione una categoria',
      textAlign: TextAlign.center,
      dropdownMenuEntries: [
        DropdownMenuEntry(value: null, label: 'Todas'),
        for (final titulo in titulos)
          DropdownMenuEntry(value: titulo, label: titulo),
      ],
      onSelected: (seleccion) {
        context.read<PeriodoInscripcionViewModel>().filtrar(seleccion);
      },
    );
    return Container(margin: EdgeInsets.symmetric(vertical: 10), child: menu);
  }

  Widget listadoGrupos() {
    return Consumer<PeriodoInscripcionViewModel>(
      builder: (context, vm, _) {
        if (vm.grupos.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.grupos.error != null) {
          return Text(
            vm.grupos.error!,
            style: Tipografia.cuerpo1(color: ColorTheme.error),
          );
        }
        final grupos = vm.gruposFiltrados;
        if (grupos.isEmpty) {
          return Text(
            'No hay grupos activos para esta seleccion',
            style: Tipografia.cuerpo1(color: ColorTheme.secondaryDark),
          );
        }
        return ListView.builder(
          shrinkWrap: true, // Ajusta el tamaño de la lista al contenido
          physics: const NeverScrollableScrollPhysics(), // Desactiva scroll interno
          itemCount: grupos.length,
          itemBuilder: (BuildContext context, int index) {
            final grupo = grupos[index];
            return InkWell(
              child: MiniTarjeta(
                existeCampoImagen: true,
                atrTitulo: '${grupo.curso} ${grupo.anio}-${grupo.iterable}',
                atrSubTitulo: grupo.categoria,
                atrIndicadorEstado: _textoEstado(vm.estadoDe(grupo)),
                atrIndicador: 'inscripciones',
              ),
              onTap: () => _controlInscripciones(grupo),
            );
          },
        );
      },
    );
  }

  String _textoEstado(EstadoInscripcion estado) {
    switch (estado) {
      case EstadoInscripcion.abierta:
        return 'Abiertas';
      case EstadoInscripcion.programada:
        return 'Programadas';
      case EstadoInscripcion.cerrada:
        return 'Cerradas';
      case EstadoInscripcion.sinPeriodo:
        return 'Sin abrir';
    }
  }

  String _textoPeriodo(Grupoentidad grupo) {
    final apertura = grupo.fechaInscripcionApertura ?? 'sin definir';
    final cierre = grupo.fechaInscripcionCierre ?? 'sin limite';
    return 'Apertura: $apertura · Cierre: $cierre';
  }

  //dialogo del grupo: muestra su estado y ofrece abrir, cerrar o programar.
  //Los botones se deshabilitan si el grupo ya tiene una operacion en camino
  void _controlInscripciones(Grupoentidad grupo) {
    final vm = context.read<PeriodoInscripcionViewModel>();
    final ocupado = vm.procesando(grupo);
    showDialog(
      context: context,
      builder: (BuildContext contextDialogo) {
        return AlertDialog(
          title: Text('Control inscripciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('${grupo.curso} ${grupo.anio}-${grupo.iterable}'),
                subtitle: Text(grupo.categoria),
              ),
              ListTile(
                title: Text(_textoEstado(vm.estadoDe(grupo))),
                subtitle: Text(_textoPeriodo(grupo)),
              ),
            ],
          ),
          actionsOverflowAlignment: OverflowBarAlignment.center,
          actions: [
            OutlinedButton(
              onPressed:
                  ocupado
                      ? null
                      : () {
                        Navigator.of(contextDialogo).pop();
                        _confirmarAbrir(grupo);
                      },
              child: Text('Abrir'),
            ),
            OutlinedButton(
              onPressed:
                  ocupado
                      ? null
                      : () {
                        Navigator.of(contextDialogo).pop();
                        _confirmarCerrar(grupo);
                      },
              style: FilledButton.styleFrom(
                foregroundColor: ColorTheme.secondary,
                side: BorderSide(color: ColorTheme.secondary),
              ),
              child: Text('Cerrar'),
            ),
            OutlinedButton(
              onPressed:
                  ocupado
                      ? null
                      : () {
                        Navigator.of(contextDialogo).pop();
                        _programar(grupo);
                      },
              style: FilledButton.styleFrom(
                foregroundColor: ColorTheme.tertiary,
                side: BorderSide(color: ColorTheme.tertiary),
              ),
              child: Text('Programar'),
            ),
          ],
        );
      },
    );
  }

  //abrir desde hoy: el backend exige una fecha de cierre, asi que se pide
  //antes de confirmar. Para una apertura futura esta Programar
  Future<void> _confirmarAbrir(Grupoentidad grupo) async {
    final cierre = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'fecha de cierre de las inscripciones',
    );
    if (cierre == null || !mounted) return;
    _confirmar(
      titulo: 'Abrir Inscripciones',
      mensaje:
          '¿Esta seguro de abrir desde hoy y hasta el ${FormatDate.fechaACadena(cierre, '/')} las inscripciones al grupo ${grupo.curso} ${grupo.anio}-${grupo.iterable}?',
      accion:
          () => context.read<PeriodoInscripcionViewModel>().abrir(
            grupo,
            cierre: cierre,
          ),
      exito: 'Las inscripciones del grupo quedaron abiertas.',
    );
  }

  void _confirmarCerrar(Grupoentidad grupo) {
    _confirmar(
      titulo: 'Cerrar Inscripciones',
      mensaje:
          '¿Esta seguro de cerrar las inscripciones al grupo ${grupo.curso} ${grupo.anio}-${grupo.iterable}?',
      accion: () => context.read<PeriodoInscripcionViewModel>().cerrar(grupo),
      exito: 'Las inscripciones del grupo quedaron cerradas.',
    );
  }

  //rango de fechas: la apertura puede ser futura (queda programada) y el
  //cierre es obligatorio. AlertFechas confirma el rango antes de devolverlo
  void _programar(Grupoentidad grupo) {
    showDialog(
      context: context,
      builder: (BuildContext contextDialogo) {
        return AlertFechas(
          titulo: 'Inscripciones ${grupo.curso} ${grupo.anio}-${grupo.iterable}',
          contenido:
              'Asigne al grupo una fecha de apertura y una de cierre para las inscripciones',
          fechaFinalObligatoria: true,
          seleccionRango: (DateTime apertura, DateTime? cierre) {
            _ejecutar(
              () => context.read<PeriodoInscripcionViewModel>().abrir(
                grupo,
                apertura: apertura,
                cierre: cierre,
              ),
              'Las inscripciones del grupo quedaron programadas.',
            );
          },
        );
      },
    );
  }

  //dialogo de confirmacion con el context de la pantalla: el del dialogo
  //anterior ya se cerro y no sirve para abrir otro
  void _confirmar({
    required String titulo,
    required String mensaje,
    required Future<Resultado<Grupoentidad>> Function() accion,
    required String exito,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext contextDialogo) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje, textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(contextDialogo).pop();
                _ejecutar(accion, exito);
              },
              child: Text('Confirmar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(contextDialogo).pop();
              },
              style: FilledButton.styleFrom(
                foregroundColor: ColorTheme.secondary,
              ),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  //el vm ya interpreto la respuesta: la vista solo decide que mostrar
  Future<void> _ejecutar(
    Future<Resultado<Grupoentidad>> Function() accion,
    String exito,
  ) async {
    final resultado = await accion();
    if (!mounted) return;
    switch (resultado) {
      case Exito():
        await showDialog(
          context: context,
          builder:
              (_) => DialogExito(titulo: 'Operacion exitosa', mensaje: exito),
        );
      case Fallo(:final codigo, :final mensaje):
        await showDialog(
          context: context,
          builder:
              (_) => DialogError(
                titulo: 'Error en las inscripciones del grupo',
                codigo: codigo,
                //el backend manda el detalle como json, DialogError lo desglosa
                mensaje: mensaje,
              ),
        );
    }
  }
}
