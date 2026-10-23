import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmRegistrarClaseTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Registrar clase";

  //todos los casos fallan en la validacion del vm, antes de llamar al
  //servicio: no necesitan backend aunque el vm use la conexion remota
  void prueba1SinFecha(Clasesviewmodel vm) {
    String caso = "error sin fecha";
    test('$capa - $tipo - $metodo - $caso', () async {
      Resultado<void> resultado = await vm.registrarClase(
        fecha: null,
        horasTexto: "2",
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).mensaje, contains('fecha'));
      expect(resultado.origen, 'ViewModel');
    });
  }

  void prueba2HorasVacias(Clasesviewmodel vm) {
    String caso = "error horas vacias";
    test('$capa - $tipo - $metodo - $caso', () async {
      Resultado<void> resultado = await vm.registrarClase(
        fecha: DateTime.now(),
        horasTexto: "",
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).mensaje, contains('horas'));
    });
  }

  //el campo solo acepta digitos en la ui, pero el vm no debe depender de eso:
  //antes la vista hacia int.parse y aqui lanzaba FormatException
  void prueba3HorasNoNumericas(Clasesviewmodel vm) {
    String caso = "error horas no numericas";
    test('$capa - $tipo - $metodo - $caso', () async {
      Resultado<void> resultado = await vm.registrarClase(
        fecha: DateTime.now(),
        horasTexto: "dos",
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).mensaje, contains('horas'));
    });
  }

  void prueba4HorasEnCero(Clasesviewmodel vm) {
    String caso = "error horas en cero";
    test('$capa - $tipo - $metodo - $caso', () async {
      Resultado<void> resultado = await vm.registrarClase(
        fecha: DateTime.now(),
        horasTexto: "0",
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).mensaje, contains('horas'));
    });
  }

  //datos validos pero sin inicializarGrupo: el vm no sabe a que grupo
  //pertenece la clase y no debe enviar la peticion
  void prueba5GrupoNoInicializado(Clasesviewmodel vm) {
    String caso = "error grupo no inicializado";
    test('$capa - $tipo - $metodo - $caso', () async {
      Resultado<void> resultado = await vm.registrarClase(
        fecha: DateTime.now(),
        horasTexto: "2",
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).mensaje, contains('Grupo'));
      //fase 4c: aqui se comprobaba que la lista del vm no cambiara
      //(vm.cargando, vm.clases). La lista paso a DetalleGrupoViewModel y
      //este vm solo registra, asi que esos dos asserts se quitaron
    });
  }

  void _imprimirRespuesta(Resultado resultado) {
    if (resultado is Fallo) {
      print('codigo: ${resultado.codigo}');
      print('error mensaje: ${resultado.mensaje}');
      print('error origen: ${resultado.origen}');
    } else {
      print('exito');
    }
  }
}
