import 'package:flutter/material.dart';

/// Vermelho levemente rosado do fundo e o tom mais claro das pokébolas.
const pokeBackground = Color(0xFFE05A70);
const pokeBackgroundLight = Color(0xFFEB7A8D);
const pokeBar = Color(0xFFC7405A);
const pokeRed = Color(0xFFD63A55);
const pokeYellow = Color(0xFFFFCB05);
const pokeBlue = Color(0xFF3B4CCA);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: pokeRed,
    primary: pokeRed,
    secondary: pokeBlue,
    tertiary: pokeYellow,
    surface: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: pokeBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: pokeBar,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: pokeBackgroundLight.withValues(alpha: 0.5),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: pokeYellow,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.white,
        side: const BorderSide(color: pokeRed, width: 1.5),
      ),
    ),
  );
}
