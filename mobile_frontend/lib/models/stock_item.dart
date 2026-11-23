enum StockStatus { aman, menipis, habis }

/// Filter status di halaman Inventaris.
enum StatusFilter { all, attention, low, empty }

enum ActivityType { stockIn, stockOut, opname, itemAdded, itemEdited, itemDeleted }

/// Satu sumber kebenaran untuk kategori dan satuan, dipakai oleh form
/// maupun chip filter agar selalu konsisten.
const List<String> kCategories = [
  'Bahan utama',
  'Protein',
  'Bumbu',
  'Sayuran',
  'Pelengkap',
  'Minuman',
  'Kemasan',
];

const List<String> kUnits = ['kg', 'gram', 'pcs', 'bungkus', 'ikat', 'botol', 'liter'];

class StockItem {
  StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.qty,
    required this.unit,
    this.minimum = 5,
  });

  final String id;
  String name;
  String category;
  double qty;
  String unit;
  double minimum;

  StockStatus get status {
    if (qty <= 0) return StockStatus.habis;
    if (qty <= minimum) return StockStatus.menipis;
    return StockStatus.aman;
  }

  bool get needsAttention => status != StockStatus.aman;
}

class ActivityEntry {
  ActivityEntry({
    required this.type,
    required this.title,
    required this.actor,
    required this.time,
    this.detail,
  });

  final ActivityType type;
  final String title;
  final String? detail;
  final String actor;
  final DateTime time;
}

/// Hasil hitung fisik satu barang pada sesi opname.
class OpnameDiff {
  OpnameDiff(this.item, this.counted);

  final StockItem item;
  final double counted;

  double get diff => counted - item.qty;
  bool get matches => diff.abs() < 0.0005;
}
