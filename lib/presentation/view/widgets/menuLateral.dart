import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Menulateral extends StatelessWidget {
  final PerfilEntidad? perfil;

  const Menulateral({super.key, this.perfil});

  @override
  Widget build(BuildContext context) {
    return miMenu(context);
  }

  SafeArea miMenu(BuildContext context) {
    return SafeArea(child: Drawer(child: _contenido(context)));
  }

  Widget _contenido(BuildContext context) {
    return Consumer<AutenticacionViewModel>(
      builder: (context, vm, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: ColorTheme.primary),
              child: Text(
                'Menu de navegacion',
                style: Tipografia.h3(color: Colors.white),
              ),
            ),
            (vm.perfilSesion == null)
                ? _iniciarSesion(vm, context)
                : _mostrarSesion(vm),
            ListTile(
              leading: Icon(Icons.home_rounded),
              title: Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRutas.inicio);
              },
            ),
            ListTile(
              leading: Icon(Icons.category_rounded),
              title: Text('Categorias'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRutas.categorias);
              },
            ),
            if (vm.perfilSesion?.role == Roles.alumno)
              ListTile(
                leading: Icon(Icons.check_box_rounded),
                title: Text('Inscripciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRutas.gruposDisponiblesInscripcion,
                    arguments: vm.perfilSesion!.id,
                  );
                },
              ),
            if (vm.perfilSesion?.role == Roles.instructor)
              ListTile(
                leading: Icon(Icons.check_box_rounded),
                title: Text('Grupos asignados'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRutas.gruposAsignados,
                    arguments: vm.perfilSesion!.id,
                  );
                },
              ),
            if (vm.perfilSesion?.role == Roles.coordinador)
              ListTile(
                leading: Icon(Icons.person_rounded),
                title: Text('Instructores'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRutas.instructores);
                },
              ),
            if (vm.perfilSesion?.role == Roles.coordinador)
              ListTile(
                leading: Icon(Icons.how_to_reg_rounded),
                title: Text('Inscripciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRutas.InscripcionesGenerales);
                },
              ),
            if (vm.perfilSesion?.role == Roles.coordinador)
              ListTile(
                leading: Icon(Icons.bar_chart_rounded),
                title: Text('Estadisticas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRutas.estadisticasGenerales);
                },
              ),
            if (vm.perfilSesion != null) _cerrarSesion(vm, context),
          ],
        );
      },
    );
  }

  Widget _cerrarSesion(AutenticacionViewModel vm, BuildContext context) {
    return ListTile(
      leading: Icon(Icons.login_rounded),
      title: Text('Cerrar sesion'),
      onTap: () async {
        await vm.logout();
        if (!context.mounted) return;
        Navigator.pop(context);
        Navigator.pushNamed(context, AppRutas.categorias);
      },
    );
  }

  Widget _mostrarSesion(AutenticacionViewModel vm) {
    return ListTile(
      leading: Icon(Icons.account_circle_rounded),
      title: Text(
        '${vm.perfilSesion!.nombre} - ${vm.perfilSesion!.correo} - ${vm.perfilSesion?.role}',
      ),
      onTap: () {},
    );
  }

  Widget _iniciarSesion(AutenticacionViewModel vm, BuildContext context) {
    return ListTile(
      leading: Icon(Icons.account_circle_rounded),
      title: Text('Iniciar sesion'),
      onTap: () async {
        final metodo = await _seleccionarMetodoInicioSesion(context);
        if (!context.mounted || metodo == null) {
          return;
        }

        if (metodo == _MetodoInicioSesion.google) {
          final resultado = await vm.loginGoogle();
          if (!context.mounted) return;

          if (!resultado) {
            final mensajeError =
                vm.error ?? 'No fue posible iniciar con Google o el acceso fue cancelado.';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(mensajeError)));
            return;
          }
        } else {
          final correo = await _solicitarCorreo(context);
          if (!context.mounted || correo == null) {
            return;
          }

          final preparado = vm.prepararLoginConCorreo(correo);
          if (!preparado) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(vm.error!)));
            return;
          }
        }

        await _procesarLoginBackend(vm, context);
      },
    );
  }

  Future<void> _procesarLoginBackend(
    AutenticacionViewModel vm,
    BuildContext context,
  ) async {
    final respuesta = await vm.login();
    if (!context.mounted) return;

    if (respuesta.codigoHttp == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email autenticado'),
          backgroundColor: ColorTheme.four,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (respuesta.codigoHttp == 404) {
      final registro = await Navigator.pushNamed(
        context,
        AppRutas.autenticacionRegistro,
      );
      if (!context.mounted) return;

      if (registro == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Te has registrado exitosamente'),
            backgroundColor: ColorTheme.primaryLight,
          ),
        );
      } else {
        await vm.logout();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ha fallado el registro, intenta nuevamente'),
            backgroundColor: ColorTheme.error,
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${respuesta.codigoHttp}')),
    );
  }

  Future<_MetodoInicioSesion?> _seleccionarMetodoInicioSesion(
    BuildContext context,
  ) {
    return showDialog<_MetodoInicioSesion>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Iniciar sesion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.login_rounded),
                title: Text('Continuar con Google'),
                onTap: () {
                  Navigator.pop(dialogContext, _MetodoInicioSesion.google);
                },
              ),
              ListTile(
                leading: Icon(Icons.email_rounded),
                title: Text('Continuar con correo'),
                onTap: () {
                  Navigator.pop(dialogContext, _MetodoInicioSesion.correo);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _solicitarCorreo(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();

        return AlertDialog(
          title: Text('Ingresa tu correo'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'correo@ejemplo.com',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: Text('Continuar'),
            ),
          ],
        );
      },
    );
  }
}

enum _MetodoInicioSesion { google, correo }
