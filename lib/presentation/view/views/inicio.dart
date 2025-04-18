import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Bar(title: 'Deporte para todos'), body: contenedorSeguro());
  }

  Widget contenedorSeguro() {
    return SafeArea(
        child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tarjeta(
                      atrTitulo: 'categoria $index',
                      atrDescripcion:
                          'Aute nostrud deserunt ullamco voluptate aliqua anim anim deserunt ullamco nostrud. Labore pariatur ea amet non eu sunt. Esse labore nulla et sint consectetur sunt. Aliqua eu Lorem laboris mollit fugiat cupidatat nisi laboris et non. Quis nisi dolor esse laboris minim tempor veniam nostrud. Ex magna laboris mollit in amet officia quis tempor non.',
                      atrRutaTarjeta: AppRutas.cursos),
                ],
              );
            }));
  }
}
