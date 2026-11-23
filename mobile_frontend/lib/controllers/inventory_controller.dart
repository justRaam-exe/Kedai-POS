import 'package:flutter/foundation.dart';

import '../models/stock_item.dart';
import '../utils/formatters.dart';

/// State inventaris di memori (data contoh).
///
/// Semua perubahan data lewat kelas ini, jadi saat backend siap cukup
/// method di sini yang diganti menjadi pemanggilan API; tampilan tidak perlu diubah.
class InventoryController extends ChangeNotifier {
  InventoryController({required this.actor}) {
    _seed();
  }

  /// Nama peran pengguna ("Owner" / "Kasir"), dicatat di riwayat aktivitas.
  final String actor;

  final List<StockItem> _items = <StockItem>[];
  final List<ActivityEntry> _activity = <ActivityEntry>[];
  final Map<String, double> _counts = <String, double>{};
  int _idSeq = 0;
  int _opnameRound = 0;

  // ---------------------------------------------------------------- baca

  List<StockItem> get items => List<StockItem>.unmodifiable(_items);
  List<ActivityEntry> get activity => List<ActivityEntry>.unmodifiable(_activity);

  int get totalCount => _items.length;
  int get lowCount => _items.where((e) => e.status == StockStatus.menipis).length;
  int get emptyCount => _items.where((e) => e.status == StockStatus.habis).length;
  int get safeCount => _items.where((e) => e.status == StockStatus.aman).length;
  int get attentionCount => lowCount + emptyCount;

  static int _rank(StockStatus s) {
    if (s == StockStatus.habis) return 0;
    if (s == StockStatus.menipis) return 1;
    return 2;
  }

  /// Habis dulu, lalu menipis, lalu aman; urut nama di dalam tiap kelompok.
  List<StockItem> get sortedItems {
    final list = List<StockItem>.of(_items);
    list.sort((a, b) {
      final r = _rank(a.status).compareTo(_rank(b.status));
      if (r != 0) return r;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  List<StockItem> get itemsByName {
    final list = List<StockItem>.of(_items);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<StockItem> get attentionItems => sortedItems.where((e) => e.needsAttention).toList();

  StockItem? byId(String? id) {
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool nameExists(String name, {String? exceptId}) {
    final target = name.trim().toLowerCase();
    return _items.any((e) => e.id != exceptId && e.name.trim().toLowerCase() == target);
  }

  // ------------------------------------------------------------- barang

  void addItem({
    required String name,
    required String category,
    required double qty,
    required String unit,
    required double minimum,
  }) {
    final item = _create(name.trim(), category, qty, unit, minimum);
    _items.add(item);
    _log(ActivityType.itemAdded, 'Barang baru: ${item.name}',
        detail: 'Stok awal ${formatQty(qty)} $unit');
    notifyListeners();
  }

  void updateItem(
    String id, {
    required String name,
    required String category,
    required String unit,
    required double minimum,
  }) {
    final item = byId(id);
    if (item == null) return;
    item.name = name.trim();
    item.category = category;
    item.unit = unit;
    item.minimum = minimum;
    _log(ActivityType.itemEdited, 'Data barang diperbarui: ${item.name}');
    notifyListeners();
  }

  void deleteItem(String id) {
    final item = byId(id);
    if (item == null) return;
    _items.remove(item);
    _counts.remove(id);
    _log(ActivityType.itemDeleted, 'Barang dihapus: ${item.name}');
    notifyListeners();
  }

  // --------------------------------------------------------- stok masuk/keluar

  void recordStockIn(StockItem item, double amount, {String note = ''}) {
    item.qty += amount;
    _log(ActivityType.stockIn, 'Stok masuk: ${item.name}',
        detail: _withNote('+${formatQty(amount)} ${item.unit}', note));
    notifyListeners();
  }

  void recordStockOut(StockItem item, double amount, {String note = ''}) {
    final remaining = item.qty - amount;
    item.qty = remaining < 0 ? 0.0 : remaining;
    _log(ActivityType.stockOut, 'Stok keluar: ${item.name}',
        detail: _withNote('−${formatQty(amount)} ${item.unit}', note));
    notifyListeners();
  }

  // ------------------------------------------------------------- opname

  /// Berubah setiap sesi opname selesai/direset, dipakai sebagai bagian key
  /// baris agar kolom isian ikut kosong kembali.
  int get opnameRound => _opnameRound;

  int get countedTotal => _counts.length;
  double? countOf(String id) => _counts[id];

  void setCount(String id, double value) {
    if (_counts[id] == value) return;
    _counts[id] = value;
    notifyListeners();
  }

  void clearCount(String id) {
    if (_counts.remove(id) != null) notifyListeners();
  }

  void resetOpname() {
    if (_counts.isEmpty) return;
    _counts.clear();
    _opnameRound++;
    notifyListeners();
  }

  List<OpnameDiff> get pendingOpname {
    final result = <OpnameDiff>[];
    for (final item in _items) {
      final counted = _counts[item.id];
      if (counted != null) result.add(OpnameDiff(item, counted));
    }
    return result;
  }

  /// Menerapkan hasil hitung fisik ke stok. Mengembalikan jumlah barang yang diproses.
  int applyOpname({String note = ''}) {
    final diffs = pendingOpname;
    for (final d in diffs) {
      final unit = d.item.unit;
      final String detail;
      if (d.matches) {
        detail = 'Sesuai: ${formatQty(d.counted)} $unit';
      } else {
        detail = 'Sistem ${formatQty(d.item.qty)} → fisik ${formatQty(d.counted)} $unit '
            '(selisih ${formatSigned(d.diff)})';
      }
      _log(ActivityType.opname, 'Opname: ${d.item.name}', detail: _withNote(detail, note));
      d.item.qty = d.counted;
    }
    _counts.clear();
    _opnameRound++;
    notifyListeners();
    return diffs.length;
  }

  // ----------------------------------------------------------- internal

  String _withNote(String detail, String note) {
    final n = note.trim();
    return n.isEmpty ? detail : '$detail · $n';
  }

  void _log(ActivityType type, String title, {String? detail, DateTime? time}) {
    _activity.insert(
      0,
      ActivityEntry(
        type: type,
        title: title,
        detail: detail,
        actor: actor,
        time: time ?? DateTime.now(),
      ),
    );
  }

  StockItem _create(String name, String category, double qty, String unit, double minimum) {
    _idSeq++;
    return StockItem(
      id: 'item-$_idSeq',
      name: name,
      category: category,
      qty: qty,
      unit: unit,
      minimum: minimum,
    );
  }

  void _seed() {
    _items.addAll([
      _create('Kerupuk seblak', 'Bahan utama', 8, 'kg', 3),
      _create('Makaroni', 'Bahan utama', 2, 'kg', 3),
      _create('Sosis', 'Protein', 42, 'pcs', 10),
      _create('Bakso', 'Protein', 0, 'pcs', 10),
      _create('Cabai merah', 'Bumbu', 1.5, 'kg', 2),
      _create('Mie', 'Bahan utama', 12, 'bungkus', 5),
      _create('Sawi', 'Sayuran', 4, 'ikat', 2),
    ]);
    final now = DateTime.now();
    _activity.addAll([
      ActivityEntry(
        type: ActivityType.stockOut,
        title: 'Stok keluar: Kerupuk seblak',
        detail: '−2 kg · Dipakai produksi',
        actor: 'Kasir',
        time: now.subtract(const Duration(hours: 2)),
      ),
      ActivityEntry(
        type: ActivityType.stockIn,
        title: 'Stok masuk: Sosis',
        detail: '+20 pcs · Belanja mingguan',
        actor: 'Owner',
        time: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ]);
  }
}
