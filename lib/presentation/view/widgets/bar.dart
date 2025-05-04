import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:provider/provider.dart';

class Bar extends StatelessWidget implements PreferredSizeWidget {
  String title;
  Bar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      //manejo manual del leading, condicional para verificar que es posible retornar
      leading:
          ModalRoute.of(context)?.canPop == true
              ? const BackButton() //si se puede retornar muestre el boton de retorno
              : null,
      title: Text(title, style: Tipografia.h5(color: ColorTheme.primary)),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
