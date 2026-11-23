/// Mengubah input pengguna seperti "2", "1,5" atau "1.5" menjadi angka.
/// Mengembalikan null jika tidak valid.
double? parseNumber(String text) {
  final cleaned = text.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

/// 8 -> "8", 1.5 -> "1,5" (koma desimal gaya Indonesia).
String formatQty(double value) {
  final rounded = double.parse(value.toStringAsFixed(2));
  if (rounded == 0) return '0';
  if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
  return rounded.toString().replaceAll('.', ',');
}

/// Menambahkan tanda + atau − di depan angka.
String formatSigned(double value) {
  final text = formatQty(value.abs());
  if (text == '0') return '0';
  return value > 0 ? '+$text' : '−$text';
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// "Hari ini, 14.05" / "Kemarin, 09.30" / "12 Nov, 16.20".
String formatActivityTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final clock = '${two(time.hour)}.${two(time.minute)}';
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(time.year, time.month, time.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hari ini, $clock';
  if (diff == 1) return 'Kemarin, $clock';
  return '${time.day} ${_months[time.month - 1]}, $clock';
}
