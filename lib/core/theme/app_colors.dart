import 'package:flutter/material.dart';

/// Палитра приложения (из ТЗ).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A73E8); // синий
  static const Color accent = Color(0xFF34A853); // зелёный

  static const Color textLight = Color(0xFF121212); // текст на светлом фоне
  static const Color textOnDark = Color(0xFFFFFFFF); // текст на тёмном фоне

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);

  static const Color error = Color(0xFFD93025);
  static const Color warning = Color(0xFFF9AB00);
  static const Color success = accent;
}
