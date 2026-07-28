import 'package:flutter/material.dart';

class TemaAppMensajeria {
  // Color base
  static const Color magentaPastel = Color(0xFFF6A6E8);

  // Tonos cálidos principales
  static const Color duraznoSuave = Color(0xFFFFCB9A);
  static const Color amarilloCrema = Color(0xFFFFF5B7);
  static const Color coralClaro = Color(0xFFFF9E9E);

  // Neutros cálidos de apoyo
  static const Color beigeArena = Color(0xFFEAD2AC);
  static const Color terracotaClaro = Color(0xFFD1806C);

  static ThemeData obtenerTema() {
    return ThemeData(
      primaryColor: magentaPastel,
      scaffoldBackgroundColor: amarilloCrema,
      colorScheme: const ColorScheme.light(
        primary: magentaPastel,
        secondary: coralClaro,
        surface: beigeArena,
        error: terracotaClaro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: magentaPastel,
        // Usamos un color oscuro cálido para contraste con el magenta pastel
        foregroundColor: Colors.black87, 
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coralClaro,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: beigeArena,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: coralClaro, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: terracotaClaro),
      ),
    );
  }
}
