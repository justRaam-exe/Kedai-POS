import 'package:flutter/material.dart';

class AppColors {
  // --- Warna brand asli (tidak diubah) ---
  static const Color primary = Color(0xFFFF7B00); // oranye brand (dekoratif)
  static const Color accent = Color(0xFFFFBD31);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color greyLight = Color(0xFFF5F5F5);

  // --- Token tambahan ---
  // Oranye lebih gelap untuk tombol, ikon, dan teks agar kontras dengan putih >= 4.5:1.
  static const Color primaryDark = Color(0xFFC2410C);
  static const Color primarySoft = Color(0xFFFFF0E2);
  static const Color bannerStart = Color(0xFFB93A0B);
  static const Color bannerEnd = Color(0xFFC2410C);

  static const Color surface = Color(0xFFFFFBF6);
  static const Color border = Color(0xFFF0ECE7);
  static const Color textMuted = Color(0xFF666666);

  // Status stok (teks + latar lembut, semuanya lolos kontras 4.5:1).
  static const Color safe = Color(0xFF187548);
  static const Color safeSoft = Color(0xFFE6F4EC);
  static const Color warning = Color(0xFF8A5300);
  static const Color warningSoft = Color(0xFFFFF3D6);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFDECEA);
}
