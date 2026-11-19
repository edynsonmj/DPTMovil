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
        return Container(
            color: const Color(0xFF000066),
            child: Column(
            children: [
              _encabezado(vm),
              _separador(),


              // AQUÍ: perfil o inicio de sesión


              _separador(),
              Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 12,
                    ),
                    children: [
                      _itemMenu(
                        icon: Icons.home_outlined,
                        titulo: 'Inicio',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRutas.inicio,
                          );
                        },
                      ),

                      _itemMenu(
                        icon: Icons.grid_view_rounded,
                        titulo: 'Categorías',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRutas.categorias,
                          );
                        },
                      ),

                      if (vm.perfilSesion?.role == Roles.alumno)
                        _itemMenu(
                          icon: Icons.chat_bubble_outline,
                          titulo: 'Inscripciones',
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
                        _itemMenu(
                          icon: Icons.groups_outlined,
                          titulo: 'Grupos asignados',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRutas.gruposAsignados,
                              arguments: vm.perfilSesion!.id,
                            );
                          },
                        ),

                      if (vm.perfilSesion?.role == Roles.coordinador) ...[
                        _itemMenu(
                          icon: Icons.groups_outlined,
                          titulo: 'Instructores',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRutas.instructores,
                            );
                          },
                        ),

                        _itemMenu(
                          icon: Icons.assignment_ind_outlined,
                          titulo: 'Inscripciones',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRutas.InscripcionesGenerales,
                            );
                          },
                        ),

                        _itemMenu(
                          icon: Icons.bar_chart_rounded,
                          titulo: 'Estadísticas',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRutas.estadisticasGenerales,
                            );
                          },
                        ),
                      ],





                    ],

              ),),

              if (vm.perfilSesion != null)
                _piePerfil(vm, context)
              else
                _iniciarSesion(vm, context)


            ],

          ),
        );
      },
    );
  }

  Widget _encabezado(AutenticacionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: const Text(
              'U',
              style: TextStyle(
                color: Color(0xFF08086B),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vm.perfilSesion?.role.toString() ?? 'Invitado',
                  style: const TextStyle(
                    color: Color(0xFFB5B5E8),
                    fontSize: 9,
                  ),
                ),
                const Text(
                  'Deporte Para Todos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMenu({
    required IconData icon,
    required String titulo,
    String? descripcion,
    required VoidCallback onTap,
    bool seleccionado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: seleccionado
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF000066),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 8,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 31,
                  height: 31,

                  child: Icon(
                    icon,
                    size: 17,
                    color: seleccionado
                        ? const Color(0xFF08086B)
                        : Colors.white,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: seleccionado
                              ? const Color(0xFF08086B)
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (descripcion != null)
                        Text(
                          descripcion,
                          style: TextStyle(
                            color: seleccionado
                                ? const Color(0xFF55558A)
                                : const Color(0xFFB5B5D8),
                            fontSize: 8,
                          ),
                        ),
                    ],
                  ),
                ),

                if (!seleccionado)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _separador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Container(
        height: 0.7,
        color: const Color(0xFF25257D),
      ),
    );
  }

  Widget _piePerfil(
      AutenticacionViewModel vm,
      BuildContext context,
      ) {
    final perfil = vm.perfilSesion;

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFE6E6FF),
            backgroundImage: vm.fotoPerfil != null
                ? NetworkImage('${vm.fotoPerfil!}=s200')
                : null,
            child: vm.fotoPerfil == null
                ? const Text(
              'U',
              style: TextStyle(
                color: Color(0xFF08086B),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfil?.nombre ?? 'Invitado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  perfil?.role.toString() ?? 'Sin sesión',
                  style: const TextStyle(
                    color: Color(0xFFB5B5D8),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),

          if (perfil != null)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 17,
              ),

              color: const Color(0xFF17176F),
              onSelected: (value) async {
                if (value == 'logout') {
                  await vm.logout();

                  if (!context.mounted) return;

                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRutas.categorias,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.white),

                  ),

                ),

              ],
            ),
        ],
      ),
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
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: vm.fotoPerfil != null
            ? NetworkImage(vm.fotoPerfil! + "=s200")
            : null,
        child: vm.fotoPerfil == null
            ? Icon(Icons.account_circle_rounded)
            : null,
      ),
      title: Text(
        '${vm.perfilSesion!.nombre} - ${vm.perfilSesion!.correo} - ${vm.perfilSesion?.role}',
      ),
      onTap: () {},
    );
  }

  Widget _iniciarSesion(AutenticacionViewModel vm, BuildContext context) {
    return ListTile(
      leading: Icon(Icons.account_circle_rounded, color: Colors.white,),
      title: const Text(
        'Iniciar Sesión',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600
        ),
      ),
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
