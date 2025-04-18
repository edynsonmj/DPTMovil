import 'dart:ui';

///Esquema de colores definido segun los lineamientos de diseño de la division TIC de la universidad del cauca
class ColorTheme {
  ///se usará para el diseño de header, iconos, títulos de páginas, títulos principales, subtítulos, cuadros de texto, texto en tarjetas, diseño de botones contenedores, diseño de contenedores etc
  static const Color primary = Color(0xFF000066);

  ///se empleará en el diseño de tarjetas en hover, botones en hover, cuadros de texto destacados, iconos, títulos destacados, diseño de contenedores de texto destacados, entre otros.
  static const Color primaryLight = Color(0xFF5056AC);

  ///se usará en el diseño de contenedores de texto, cuadros de texto, iconografía específica, diseño de fondos de página, entre otros.
  static const Color primaryDark = Color(0xFF07184A);

  ///se usará en el diseño de elementos con menor grado de énfasis, subtítulos o textos destacados.
  static const Color secondary = Color(0xFF9D0311);

  ///se empleará en el diseño de la miga de pan, línea de título de página, subtítulos específicos, textos destacados, iconografía específica.
  static const Color secondaryLight = Color(0xFFDB141C);

  ///se usará en el diseño de contenedores de texto, cuadros de texto, iconografía específica.
  static const Color secondaryDark = Color(0xFF690007);

  ///se usará para el botón contenedor, al igual que para el color del ícono de accesibilidad en estado hover
  static const Color accessibility = Color(0xFF249300);

  ///se empleará para los textos de cada una de las herramientas de accesibilidad.
  static const Color neutral = Color(0xFF454444);

  ///se usará para marca el posicionamiento del cursor en cada una de las herramientas para que el usuario tenga una mejor comprensión de este botón y de su ubicación dentro del mismo.
  static const Color hover = Color(0xFFF6F6F6);

  /// el cual es una variante del color primario, se usará con el fin de reforzar la identidad corporativa en subtítulos, textos destacados, diseño UI de imágenes o fotoilustraciones
  static const Color tertiary = Color(0xFF1D72D3);

  ///se empleará en el diseño de menús secundarios, luz de borde en contenedores de texto específicos, diseño UI de imágenes o fotoilustración.
  static const Color tonal = Color(0xFFECF0FF);

  ///se usará en el diseño de iconografía o texto destacado que advierta al usuario de inconsistencias en el proceso.
  static const Color error = Color(0xFFED7D31);

  static const Color one = Color(0xFFFF6C08);
  static const Color two = Color(0xFFFFB000);
  static const Color three = Color(0xFF5BAE40);
  static const Color four = Color(0xFF00AAE5);
  static const Color five = Color(0xFF5A00BA);
}
