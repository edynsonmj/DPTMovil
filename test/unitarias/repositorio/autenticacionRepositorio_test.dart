import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionautenticacionFalsa.dart';

//el repositorio ya recibe su conexion por constructor: se prueba con el
//doble y sin backend. Su constructor no cambia en la fase 2, asi que estos
//casos deben pasar igual antes y despues de migrar autenticacion
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionautenticacionFalsa conexion;
  late Autenticacionrepositorio repositorio;

  setUp(() {
    conexion = ConexionautenticacionFalsa();
    repositorio = Autenticacionrepositorio(conexion: conexion);
  });

  Perfilmodelo perfil({String? role}) => Perfilmodelo(
    id: '123',
    nombre: 'Ana',
    correo: 'ana@unicauca.edu.co',
    tipoId: 'CC',
    sexo: 'F',
    role: role,
  );

  group('Autenticacion (repositorio con doble):', () {
    test('$capa - $tipo - Login - 200 devuelve el perfil con su rol', () async {
      conexion.respuestaLogin = RespuestaModelo(
        codigoHttp: 200,
        datos: perfil(role: 'Coordinador'),
      );

      final respuesta = await repositorio.login('ana@unicauca.edu.co');

      expect(conexion.ultimoCorreo, 'ana@unicauca.edu.co');
      expect(respuesta.codigoHttp, 200);
      //ningun modelo sale de la capa de datos
      expect(respuesta.datos, isA<PerfilEntidad>());
      final entidad = respuesta.datos as PerfilEntidad;
      expect(entidad.correo, 'ana@unicauca.edu.co');
      //el rol es lo que habilita las opciones de la UI
      expect(entidad.role, 'Coordinador');
    });

    test('$capa - $tipo - Login - 404 pasa sin cambios', () async {
      //el 404 significa "no registrado": el menu lateral abre el registro
      final noRegistrado = RespuestaModelo(codigoHttp: 404);
      conexion.respuestaLogin = noRegistrado;

      final respuesta = await repositorio.login('nuevo@unicauca.edu.co');

      expect(respuesta, same(noRegistrado));
      expect(respuesta.codigoHttp, 404);
    });

    test('$capa - $tipo - Registro - 201 devuelve el perfil creado', () async {
      conexion.respuestaRegistro = RespuestaModelo(
        codigoHttp: 201,
        datos: perfil(role: 'Alumno'),
      );

      final respuesta = await repositorio.registro(
        PerfilEntidad(
          id: '123',
          nombre: 'Ana',
          correo: 'ana@unicauca.edu.co',
          tipoId: 'CC',
          sexo: 'F',
          facultad: 'Ingenieria',
        ),
      );

      //la peticion llego como modelo, con los datos del formulario
      expect(conexion.llamadasRegistro, 1);
      expect(conexion.ultimoRegistro?.correo, 'ana@unicauca.edu.co');
      expect(conexion.ultimoRegistro?.facultad, 'Ingenieria');
      expect(respuesta.codigoHttp, 201);
      expect(respuesta.datos, isA<PerfilEntidad>());
      expect((respuesta.datos as PerfilEntidad).role, 'Alumno');
    });
  });
}
