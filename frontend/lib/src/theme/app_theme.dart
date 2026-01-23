import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: const Color.fromARGB(255, 245, 231, 223), // = BACKGROUND !!!!!!
    onSurface: const Color.fromARGB(255, 39, 6, 6),
    primary: const Color.fromARGB(255, 98, 29, 22), // e.g. start button
    onPrimary: const Color.fromARGB(255, 245, 231, 223), 
    secondary: const Color.fromARGB(255, 228, 210, 200), // app bar, direction panel, canvas bgk
    //primaryContainer: const Color.fromARGB(255, 229, 190, 178), // direction panel
    primaryContainer: const Color.fromARGB(255, 235, 219, 209), // direction panel
    secondaryContainer: const Color.fromARGB(255, 185, 152, 141), // direction card
    onSecondaryFixed: const Color.fromARGB(255, 185, 134, 118), // selected direction card
    tertiary:const Color.fromARGB(255, 22, 114, 0), // editable text
    onTertiary: const Color.fromARGB(255, 36, 17, 9) // APP BAR TEXT
    
  ),
  fontFamily: GoogleFonts.quantico().fontFamily,
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 24, 15, 13), // = BACKGROUND !!!!!!
    onSurface: const Color.fromARGB(255, 245, 231, 223),
    primary: const Color.fromARGB(255, 241, 206, 195), // e.g. start button
    onPrimary: const Color.fromARGB(255, 84, 3, 27), 
    secondary: const Color.fromARGB(255, 31, 21, 19), // app bar, direction panel, canvas bgk
    onSecondary: const Color.fromARGB(255, 236, 224, 216),
    primaryContainer: const Color.fromARGB(255, 40, 21, 19), // direction panel
    secondaryContainer: const Color.fromARGB(255, 61, 38, 27), // direction card
    onSecondaryFixed: const Color.fromARGB(255, 116, 84, 75), // selected direction card
    tertiary:Color.fromARGB(255, 100, 170, 83), // editable text
    onTertiary: const Color.fromARGB(255, 185, 152, 141) //
  ),
  fontFamily: GoogleFonts.quantico().fontFamily,
);