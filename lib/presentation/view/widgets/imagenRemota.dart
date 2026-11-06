import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//imagen del backend. Image.network no pasa por el Dio compartido, asi que no
//recibe el JWT de InterceptorToken: sin esta cabecera /imagenStream responde
//401. Escucha la sesion para volver a pedirla si cambia el token. Para fotos
//de otros servidores (Google) se sigue usando NetworkImage, sin el JWT
class ImagenRemota extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? height;
  final double? width;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  const ImagenRemota(
    this.url, {
    super.key,
    this.fit,
    this.height,
    this.width,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final autorizacion = context.select<AutenticacionViewModel, String?>(
      (vm) => vm.autorizacion,
    );
    return Image.network(
      url,
      fit: fit,
      height: height,
      width: width,
      headers: autorizacion == null ? null : {'Authorization': autorizacion},
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
