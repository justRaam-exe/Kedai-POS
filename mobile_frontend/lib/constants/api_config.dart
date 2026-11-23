import 'package:flutter/foundation.dart';

/// Konfigurasi koneksi dan mode tampilan.
///
/// Alamat API dapat diganti tanpa mengubah kode:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Menampilkan label "Data contoh" di app bar selama data inventaris
  /// masih berupa data lokal (belum terhubung ke backend).
  static const bool demoData = true;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // Emulator Android mengakses komputer host lewat 10.0.2.2, bukan localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static Uri get login => Uri.parse('$baseUrl/api/auth/login');
}
