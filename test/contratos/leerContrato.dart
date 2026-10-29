import 'dart:convert';
import 'dart:io';

//json del contrato acordado (o propuesto) con el backend, ya decodificado.
//La ruta es relativa al directorio de trabajo, como assets/images/1.jpg en
//los tests remotos: correr flutter test desde la raiz del proyecto
dynamic leerContrato(String modulo, String nombre) => jsonDecode(
  File('test/contratos/$modulo/$nombre.json').readAsStringSync(),
);
