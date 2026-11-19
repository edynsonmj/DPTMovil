import 'package:dpt_movil/config/routes/accesoRutas.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:flutter_test/flutter_test.dart';

//tabla de acceso por rol de las rutas (AS-01, AU-10): sigue lo que la
//interfaz ya ofrece a cada rol
void main() {
  const String capa = "rutas";
  const String tipo = "unitaria";

  group('Acceso a las rutas por rol:', () {
    test('$capa - $tipo - permite - las publicas se abren con cualquier rol y sin sesion', () {
      for (final ruta in [AppRutas.categorias, AppRutas.cursos, AppRutas.autenticacionRegistro, AppRutas.inicio]) {
        for (final rol in [Roles.coordinador, Roles.instructor, Roles.alumno, null]) {
          expect(AccesoRutas.permite(ruta, rol), isTrue, reason: '$ruta con $rol');
        }
      }
    });

    test('$capa - $tipo - permite - las del coordinador solo con su rol', () {
      for (final ruta in [
        AppRutas.InscripcionesGenerales,
        AppRutas.InscripcionesParticulares,
        AppRutas.instructores,
        AppRutas.estadisticasGenerales,
        AppRutas.editarCategoria,
        AppRutas.formularioCurso,
        AppRutas.grupoFormulario,
        AppRutas.curso,
      ]) {
        expect(AccesoRutas.permite(ruta, Roles.coordinador), isTrue, reason: ruta);
        for (final rol in [Roles.instructor, Roles.alumno, null]) {
          expect(AccesoRutas.permite(ruta, rol), isFalse, reason: '$ruta con $rol');
        }
      }
    });

    test('$capa - $tipo - permite - el grupo y sus clases para coordinador e instructor', () {
      for (final ruta in [AppRutas.grupo, AppRutas.clase, AppRutas.formularioClase]) {
        expect(AccesoRutas.permite(ruta, Roles.coordinador), isTrue, reason: ruta);
        expect(AccesoRutas.permite(ruta, Roles.instructor), isTrue, reason: ruta);
        expect(AccesoRutas.permite(ruta, Roles.alumno), isFalse, reason: ruta);
        expect(AccesoRutas.permite(ruta, null), isFalse, reason: ruta);
      }
    });

    test('$capa - $tipo - permite - las del menu de cada rol solo para ese rol', () {
      expect(AccesoRutas.permite(AppRutas.gruposAsignados, Roles.instructor), isTrue);
      expect(AccesoRutas.permite(AppRutas.gruposAsignados, Roles.alumno), isFalse);
      expect(AccesoRutas.permite(AppRutas.gruposDisponiblesInscripcion, Roles.alumno), isTrue);
      expect(AccesoRutas.permite(AppRutas.gruposDisponiblesInscripcion, Roles.coordinador), isFalse);
    });

    test('$capa - $tipo - dictaClase - coordinador e instructor si; alumno y sin sesion no', () {
      expect(AccesoRutas.dictaClase(Roles.coordinador), isTrue);
      expect(AccesoRutas.dictaClase(Roles.instructor), isTrue);
      expect(AccesoRutas.dictaClase(Roles.alumno), isFalse);
      expect(AccesoRutas.dictaClase(null), isFalse);
    });
  });
}
