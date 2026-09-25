import 'package:flutter/material.dart';

const pokeRed = Color(0xFFE3350D);
const pokeYellow = Color(0xFFFFCB05);
const pokeBlue = Color(0xFF3B4CCA);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: pokeRed,
    brightness: brightness,
    primary: brightness == Brightness.light ? pokeRed : null,
    secondary: pokeBlue,
    tertiary: pokeYellow,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
  );
}
