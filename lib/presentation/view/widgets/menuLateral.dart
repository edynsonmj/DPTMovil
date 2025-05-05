import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:provider/provider.dart';

class Menulateral extends StatelessWidget {
  PerfilEntidad? perfil;

  Menulateral({super.key, this.perfil});
  @override
  Widget build(BuildContext context) {
    return miMenu(context);
  }

  SafeArea miMenu(BuildContext context) {
    return SafeArea(child: Drawer(child: _contenido(context)));
  }

  Widget _contenido(context) {
    return Consumer<AutenticacionViewModel>(
      builder: (context, vm, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: ColorTheme.primary),
              child: Text(
                'Menú de navegación',
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
            if (vm.perfilSesion?.role == Roles.coordinador ||
                vm.perfilSesion?.role == Roles.instructor)
              ListTile(
                leading: Icon(Icons.people_rounded),
                title: Text('Alumnos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRutas.alumnos);
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

  Widget _cerrarSesion(AutenticacionViewModel vm, context) {
    return ListTile(
      leading: Icon(Icons.login_rounded),
      title: Text('Cerrar sesión'),
      onTap: () async {
        await vm.logout(); // asegúrate de tener esta función implementada
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

  Widget _iniciarSesion(AutenticacionViewModel vm, context) {
    return ListTile(
      leading: Icon(Icons.account_circle_rounded),
      title: Text('Iniciar sesión'),
      onTap: () async {
        //PASO 1
        //Realizar login con google, si no encuentra sesion desplegara la interfaz de inicio de sesion de google
        final resultado = await vm.loginGoogle();
        if (!context.mounted) return;
        //si resultado es false, ha fallado el login con google
        if (!resultado) {
          if (vm.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(vm.error!)));
          }
          Navigator.pop(context);
          return;
        }
        //PASO 2
        //El login con google ha funcionado, el viewmodel internamente cargara la informacion suministrada por google
        //ahora se realiza la verificacion, con el backend DPT
        final respuesta = await vm.login();
        if (!context.mounted) return;

        //si respuesta es 200, significa que en el sistema se encontraba el usuario a verificar.
        //el view model cargara la sesion en perfilSesion -> tenemos sesion activa
        if (respuesta.codigoHttp == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Email autenticado"),
              backgroundColor: ColorTheme.four,
            ),
          );
          Navigator.pop(context);
          return;
        }

        //si la respuesta es 404, no se encontro el usuario en el sistema, por tanto procede un registro
        if (respuesta.codigoHttp == 404) {
          final registro = await Navigator.pushNamed(
            context,
            AppRutas.autenticacionRegistro,
          );
          //si el formulario de registro retorna positivo, se ha registrado y cargado la sesion
          if (registro == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Te has registrado exitosamente'),
                backgroundColor: ColorTheme.primaryLight,
              ),
            );
            //si hay un error en el registro o se ha cancelado por parte del usuario se obtiene false
          } else {
            //en este caso se eliminan los datos que se pueden haber generado durante el proceso para dejar el view model disponible a un nuevo intento de sesion
            vm.logout();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ha fallado el registro, intenta nuevamente'),
                backgroundColor: ColorTheme.error,
              ),
            );
          }
          return;
        }

        //si el codigo es diferente a 200 y 404, entonces es un error diferente, reportarlo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${respuesta.codigoHttp}")),
        );
      },
    );
  }

  Widget _sesion(AutenticacionViewModel vm) {
    //Consumo el viewmodel del provider
    return Consumer<AutenticacionViewModel>(
      builder: (context, vm, _) {
        // Si hay sesión activa, mostrar perfil
        if (vm.perfilSesion != null) {
          return ListTile(
            leading: Icon(Icons.account_circle_rounded),
            title: Text(
              '${vm.perfilSesion!.nombre} - ${vm.perfilSesion!.correo}',
            ),
            onTap: () {},
          );
        }

        // Si no hay sesión activa, de inicio de sesión
        return ListTile(
          leading: Icon(Icons.account_circle_rounded),
          title: Text('Iniciar sesión'),
          onTap: () async {
            //PASO 1
            //Realizar login con google, si no encuentra sesion desplegara la interfaz de inicio de sesion de google
            final resultado = await vm.loginGoogle();
            if (!context.mounted) return;
            //si resultado es false, ha fallado el login con google
            if (!resultado) {
              if (vm.error != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(vm.error!)));
              }
              Navigator.pop(context);
              return;
            }
            //PASO 2
            //El login con google ha funcionado, el viewmodel internamente cargara la informacion suministrada por google
            //ahora se realiza la verificacion, con el backend DPT
            final respuesta = await vm.login();
            if (!context.mounted) return;

            //si respuesta es 200, significa que en el sistema se encontraba el usuario a verificar.
            //el view model cargara la sesion en perfilSesion -> tenemos sesion activa
            if (respuesta.codigoHttp == 200) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Email autenticado"),
                  backgroundColor: ColorTheme.four,
                ),
              );
              Navigator.pop(context);
              return;
            }

            //si la respuesta es 404, no se encontro el usuario en el sistema, por tanto procede un registro
            if (respuesta.codigoHttp == 404) {
              final registro = await Navigator.pushNamed(
                context,
                AppRutas.autenticacionRegistro,
              );
              //si el formulario de registro retorna positivo, se ha registrado y cargado la sesion
              if (registro == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Te has registrado exitosamente'),
                    backgroundColor: ColorTheme.primaryLight,
                  ),
                );
                //si hay un error en el registro o se ha cancelado por parte del usuario se obtiene false
              } else {
                //en este caso se eliminan los datos que se pueden haber generado durante el proceso para dejar el view model disponible a un nuevo intento de sesion
                vm.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ha fallado el registro, intenta nuevamente'),
                    backgroundColor: ColorTheme.error,
                  ),
                );
              }
              return;
            }

            //si el codigo es diferente a 200 y 404, entonces es un error diferente, reportarlo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${respuesta.codigoHttp}")),
            );
          },
        );
      },
    );
  }
}
