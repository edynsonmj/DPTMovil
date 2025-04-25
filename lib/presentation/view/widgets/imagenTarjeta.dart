import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/viewmodels/imagenViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Imagentarjeta extends StatefulWidget {
  int? idImagen;
  Imagentarjeta({this.idImagen});

  @override
  State<StatefulWidget> createState() {
    return _ImagentarjetaState();
  }
}

class _ImagentarjetaState extends State<Imagentarjeta> {
  final Imagenviewmodel _vmImagen = Imagenviewmodel();
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      //final vmImagen = Provider.of<Imagenviewmodel>(context, listen: false);
      if (widget.idImagen != null) {
        _vmImagen.obtenerImagen(widget.idImagen!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vmImagen,
      builder: (context, _) {
        if (widget.idImagen == null) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.asset('assets/images/1.jpg', fit: BoxFit.cover),
            ),
          );
        }
        if (_vmImagen.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_vmImagen.error != null) {
          return Center(
            child: Text(
              _vmImagen.error!,
              style: Tipografia.cuerpo1(color: ColorTheme.error),
            ),
          );
        }
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child:
                _vmImagen.imagen == null
                    ? imagenDefecto()
                    : Image.memory(
                      _vmImagen.imagen!.datos,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => imagenDefecto(),
                    ),
          ),
        );
      },
    );
  }

  ///Imagen cargada si no hay otra
  Image imagenDefecto() {
    return Image.asset('assets/images/1.jpg', fit: BoxFit.cover);
  }
}
