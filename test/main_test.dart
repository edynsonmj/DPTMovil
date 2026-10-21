// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/local/ConexionCategoriaLocal.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/data/repositories/imagenRepositorio.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'local/categorias/insertarCategoriaLocal.dart';
import 'local/categorias/obtenerCategoriasLocal.dart';
import 'local/viewModel/categoria/vmListarCategoriaLocalTest.dart';
import 'remoto/categorias/insertarCategoriaTest.dart';
import 'remoto/categorias/listarCategoriaTest.dart';
import 'remoto/imagenes/obtenerImagenTest.dart';
import 'remoto/viewModel/categoria/vmActualizarCategoriaTest.dart';
import 'remoto/viewModel/clase/vmRegistrarClaseTest.dart';
import 'remoto/viewModel/atencion/vmAtencionTest.dart';
import 'remoto/viewModel/grupo/vmListarGruposTest.dart';
import 'remoto/viewModel/categoria/vmEliminarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmListarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmGuardarCategoriaTest.dart';
import 'remoto/viewModel/categoria/vmGuardarFormularioCategoriaTest.dart';

void main() {
  //probarRepositorioCategoriaRemota();
  //el local va primero: cada vm resuelve su conexion al construirse, asi que
  //se construye con la config en SERVICIO_LOCAL antes de pasarla a remoto
  probarViewModelCategoriaLocal();
  probarViewModelCategoria();
  probarViewModelClase();
  probarViewModelAtencion();
  probarViewModelGrupo();
}
probarViewModelGrupo(){
  //no hay fake local de grupos. El caso hace una peticion real, pero solo
  //comprueba el estado del vm, no los datos de la bd
  ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_REMOTO;
  ConfigServicio.ip = "localhost";
  group('Listar grupos de un curso:', () {
    VmListarGruposTest test = VmListarGruposTest();
    test.prueba1EstadoDuranteCarga(Gruposviewmodel.new);
  });
}
probarViewModelAtencion(){
  //no hay fake local de atenciones: el vm usa la conexion remota, aunque
  //estos casos no llegan a hacer peticiones. Un vm por caso, como en la ruta
  ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_REMOTO;
  ConfigServicio.ip = "localhost";
  group('Atenciones de clase (sin backend):', () {
    VmAtencionTest test = VmAtencionTest();
    test.prueba1RegistrarSinCargar(Atencionviewmodel.new);
    test.prueba2ClaseSinCodigo(Atencionviewmodel.new);
    test.prueba3MarcarSinLista(Atencionviewmodel.new);
  });
}
probarViewModelClase(){
  //no hay fake local de clases: el vm se construye con la conexion remota,
  //aunque estos casos no llegan a hacer peticiones
  ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_REMOTO;
  ConfigServicio.ip = "localhost";
  Clasesviewmodel vm = Clasesviewmodel();
  group('Registrar clase (validaciones):', () {
    VmRegistrarClaseTest test = VmRegistrarClaseTest();
    test.prueba1SinFecha(vm);
    test.prueba2HorasVacias(vm);
    test.prueba3HorasNoNumericas(vm);
    test.prueba4HorasEnCero(vm);
    test.prueba5GrupoNoInicializado(vm);
  });
}
probarViewModelCategoriaLocal(){
  ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_LOCAL;
  CategoriaViewModel vm = CategoriaViewModel();
  group('Listar categorias locales:', () {
    VmListarCategoriaLocalTest test = VmListarCategoriaLocalTest();
    test.prueba1ListaVacia204(vm);
    test.prueba2EntradasVacias(vm);
  });
}
probarViewModelCategoria(){
  //la configuracion debe ir antes de construir el vm: el vm crea su propio
  //servicio, y la conexion captura la baseUrl al momento de construirse
  ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_REMOTO;
  ConfigServicio.ip = "localhost";
  CategoriaViewModel vm = CategoriaViewModel();
  grupoVMCategoriaRegistrar(vm);
}
grupoVMCategoriaRegistrar(CategoriaViewModel vm){
  group('Listar categorias remotas:', () {
    VmListarCategoriaTest test = VmListarCategoriaTest();
    test.prueba1codigo200(vm);
    test.prueba2ReflejaInsercion(vm);
    test.prueba3ListaEntradas(vm);
  });
  group('Guardar categoria remota:', () {
    VmGuardarCategoriaTest test = VmGuardarCategoriaTest();
    test.prueba1codigo201(vm);
    test.prueba2SinImagen(vm);
    test.prueba3SinTitulo(vm);
    test.prueba4SinDescripcion(vm);
  });
  group('Actualizar categoria remota:', () {
    VmActualizarCategoriaTest test = VmActualizarCategoriaTest();
    test.prueba1codigo200(vm);
    test.prueba2CambioImagen(vm);
    test.prueba3Inexistente(vm);
    test.prueba4DescripcionVacia(vm);
    test.prueba5TituloVacio(vm);
    test.prueba6SinImagen(vm);
  });
  group('Guardar categoria desde formulario:', () {
    VmGuardarFormularioCategoriaTest test = VmGuardarFormularioCategoriaTest();
    test.prueba1CrearExito(vm);
    test.prueba2CrearSinImagen(vm);
    test.prueba3CrearRecortaEspacios(vm);
    test.prueba4EditarSinImagenNueva(vm);
    test.prueba5EditarConImagenNueva(vm);
    test.prueba6EditarSinNingunaImagen(vm);
    test.prueba7EditarUsaTituloOriginal(vm);
    test.prueba8UrlImagen(vm);
  });
  group('Eliminar categoria remota:', () {
    VmEliminarCategoriaTest test = VmEliminarCategoriaTest();
    test.prueba1codigo200(vm);
    test.prueba2Inexistente(vm);
    test.prueba3TituloVacio(vm);
  });
}

probarRepositorioCategoriaLocal() {
  String ip = '192.168.100.66';
  CategoriaRepositorio repositorio = configuracionCategoriaRepositorio(
    true,
    ip,
  );
  group('Obtener categorias:', () {
    Obtenercategoriaslocal test = Obtenercategoriaslocal();
    test.prueba1ObtenerLista(repositorio);
    test.prueba2ListaTipo(repositorio);
  });
  group('insertar Categoria: ', () {
    Insertarcategorialocal test = Insertarcategorialocal();
    test.prueba1InsercionExitosa(repositorio);
    test.prueba2InsercionRepetida(repositorio);
    test.prueba3InsercionIncompleta(repositorio);
  });
}

probarRepositorioImagenRemota() {
  String ip = "localhost";
  Imagenrepositorio repo = configuracionImagenRepositorio(ip);
  grupoObtenerImagenRemota(repo);
}

probarRepositorioCategoriaRemota() {
  String ip = 'localhost';
  CategoriaRepositorio repositorio = configuracionCategoriaRepositorio(
    false,
    ip,
  );
  grupoInsercionCategoriaRemota(repositorio);
  grupoObtenerCateogoriaRemota(repositorio);
}

grupoInsercionCategoriaRemota(CategoriaRepositorio repositorio) {
  print("hola");
  group('Insertar Categoria:', () {
    Random random = Random();
    InsertarCategoriaTest test = InsertarCategoriaTest();
    test.prueba1(random, repositorio);
    test.prueba2Exito(random, repositorio);
    test.prueba3(random, repositorio);
    test.prueba4(random, repositorio);
    test.prueba5(random, repositorio);
  });
}

grupoObtenerCateogoriaRemota(CategoriaRepositorio repositorio) {
  group('Obtener Categoria:', () {
    ListarCategoriaTest test = ListarCategoriaTest();
    test.prueba1codigo200(repositorio);
    test.prueba2codigo204(repositorio);
  });
}

grupoObtenerImagenRemota(Imagenrepositorio repositorio) {
  group('Obtener imagen remota:', () {
    Obtenerimagentest test = Obtenerimagentest();
    test.prueba1codigo200(repositorio);
  });
}

CategoriaRepositorio configuracionCategoriaRepositorio(bool local, String? ip) {
  CategoriaRepositorio repositorio;
  if (local) {
    ConfigServicio.tipoFabricaServicio =
        ConexionFabricaAbstracta.SERVICIO_LOCAL;
    repositorio = CategoriaRepositorio(cliente: ConexionCategoriaLocal());
  } else {
    ConfigServicio.tipoFabricaServicio =
        ConexionFabricaAbstracta.SERVICIO_REMOTO;
    ConfigServicio.ip = ip;
    repositorio = CategoriaRepositorio(cliente: ConexionCategoriaRemota());
  }
  return repositorio;
}

Imagenrepositorio configuracionImagenRepositorio(String? ip) {
  Imagenrepositorio repositorio;

  ConfigServicio.tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_REMOTO;
  ConfigServicio.ip = ip;
  repositorio = Imagenrepositorio(conexion: Conexionimagenremoto());

  return repositorio;
}
