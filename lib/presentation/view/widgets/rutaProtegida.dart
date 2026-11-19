import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//pantalla de una ruta con rol (AS-01, AU-10): si el rol de la sesion no esta
//entre los permitidos muestra "Acceso restringido" en vez de [child]. El
//provider de la ruta va dentro de [child], asi que sin permiso no se crea su
//vm ni sale ninguna peticion. Se reconstruye si cambia el rol (cerrar sesion)
class RutaProtegida extends StatelessWidget {
  final Set<String> roles;
  final Widget child;

  const RutaProtegida({super.key, required this.roles, required this.child});

  @override
  Widget build(BuildContext context) {
    final rol = context.select<AutenticacionViewModel, String?>(
      (vm) => vm.perfilSesion?.role,
    );
    if (roles.contains(rol)) return child;
    return Scaffold(
      appBar: Bar(title: 'Acceso restringido'),
      drawer: Builder(builder: (context) => Menulateral()),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No tienes acceso a esta pantalla',
                  style: Tipografia.h6(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  rol == null
                      ? 'Inicia sesión desde el menú para continuar.'
                      : 'Tu rol ($rol) no puede abrirla.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRutas.categorias,
                        (_) => false,
                      ),
                  child: const Text('Ir a categorías'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
