import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//Asistencia de una clase en el backend actual (BK-02):
//- GET /alumnosGrupo: los alumnos del grupo (nombre, id...)
//- GET /atencionesporclase?claseid=: una fila {idClase, idPerfil, estaAtendido}
//  por alumno ya marcado; una clase sin marcas responde 200 con un objeto
//  GC-0002 ("listado vacio")
//- PUT /clase/{codigo}/asistencia: confirma la asistencia (idempotente)
//La lista de la pantalla es la de alumnos del grupo con su marca
class Conexionatencionesremoto implements Conexionatenciones {
  //el Dio compartido llega desde la raiz de composicion, con la baseUrl
  final Dio _dio;

  Conexionatencionesremoto(this._dio);

  @override
  Future<RespuestaModelo> obtenerAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int claseid,
  ) async {
    String metodo = "GET";
    String path = '/alumnosGrupo';
    try {
      final alumnos = await _dio.get(
        path,
        queryParameters: {
          'categoria': categoria,
          'curso': curso,
          'anio': anio,
          'iterable': iterable,
        },
      );
      if (alumnos.statusCode != 200) {
        return RespuestaModelo.fromResponse(alumnos, metodo);
      }
      //un grupo sin alumnos: lista vacia, no error
      if (_esListadoVacio(alumnos.data)) {
        return RespuestaModelo(codigoHttp: 200, datos: <Atencionmodelo>[]);
      }
      if (alumnos.data is! List) {
        return _noEsLista(alumnos.data, path, metodo);
      }

      path = '/atencionesporclase';
      final marcas = await _dio.get(path, queryParameters: {'claseid': claseid});
      if (marcas.statusCode != 200) {
        return RespuestaModelo.fromResponse(marcas, metodo);
      }
      final Set<String> presentes = {};
      if (marcas.data is List) {
        for (final fila in marcas.data as List) {
          if (fila['estaAtendido'] == true) {
            presentes.add(fila['idPerfil'].toString());
          }
        }
      } else if (!_esListadoVacio(marcas.data)) {
        return _noEsLista(marcas.data, path, metodo);
      }

      final atenciones =
          (alumnos.data as List).map((json) {
            return Atencionmodelo.fromJson({
              'alumno': json,
              'asistio': presentes.contains(json['id'].toString()),
            }, claseid);
          }).toList();
      return RespuestaModelo(codigoHttp: 200, datos: atenciones);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }

  @override
  Future<RespuestaModelo> registrarAtencionesClase(
    List<Atencionmodelo> atenciones,
    int idClase,
  ) async {
    String metodo = "PUT";
    String path = '/clase/$idClase/asistencia';
    try {
      //responde 200 con {codigoClase, confirmadaEn, presentes, ausentes}; la
      //app solo necesita saber que se guardo
      final response = await _dio.put(
        path,
        data: {
          'asistencias': atenciones.map((a) => a.toJson()).toList(),
          //sin ningun presente el backend exige confirmar que todos faltaron
          'confirmaTodosAusentes': !atenciones.any((a) => a.estaAtendido),
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final codigo = response.statusCode ?? 0;
      //cualquier 2xx es exito: la asistencia quedo guardada (AS-07)
      if (codigo < 200 || codigo > 299) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: codigo);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }

  bool _esListadoVacio(dynamic data) =>
      data is Map && data['codigoError'] == 'GC-0002';

  RespuestaModelo _noEsLista(dynamic data, String path, String metodo) {
    return RespuestaModelo(
      codigoHttp: 406,
      datos: data,
      error: ErrorModelo(
        codigoHttp: 406,
        mensaje: "se esperaba una lista",
        url: path,
        metodo: metodo,
      ),
    );
  }
}
