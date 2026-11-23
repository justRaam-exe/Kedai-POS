import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/stock_item.dart';
import '../../../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_heading.dart';

/// Opname dilakukan sebagai satu sesi:
/// 1. hitung barang, isi jumlah fisik (kolom awalnya kosong supaya benar-benar dihitung),
/// 2. periksa selisih, 3. simpan sekaligus setelah konfirmasi.
class OpnamePage extends StatefulWidget {
  const OpnamePage({super.key, required this.controller});

  final InventoryController controller;

  @override
  State<OpnamePage> createState() => _OpnamePageState();
}

class _OpnamePageState extends State<OpnamePage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final c = widget.controller;
    final diffs = c.pendingOpname;
    if (diffs.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _OpnameConfirmDialog(diffs: diffs),
    );
    if (note == null) return; // dibatalkan
    final n = c.applyOpname(note: note);
    messenger.showSnackBar(SnackBar(content: Text('Opname tersimpan. Stok $n barang diperbarui.')));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final all = c.itemsByName;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty ? all : all.where((e) => e.name.toLowerCase().contains(q)).toList();
    final counted = c.countedTotal;
    final total = all.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              const SectionHeading(
                'Hitung stok fisik',
                subtitle: 'Hitung barang yang ada di kedai, lalu isi jumlahnya. '
                    'Selisih dengan catatan sistem dihitung otomatis.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$counted dari $total barang dihitung',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  if (counted > 0)
                    TextButton(onPressed: c.resetOpname, child: const Text('Kosongkan')),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : counted / total,
                  minHeight: 8,
                  backgroundColor: AppColors.primarySoft,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari barang yang mau dihitung',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (all.isEmpty)
                const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Belum ada barang untuk dihitung',
                  message: 'Owner perlu menambahkan barang di menu Inventaris.',
                )
              else if (shown.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Barang tidak ditemukan',
                  message: 'Coba kata kunci lain.',
                )
              else
                ...shown.map(
                  (e) => _OpnameRow(
                    key: ValueKey('${e.id}-${c.opnameRound}'),
                    item: e,
                    counted: c.countOf(e.id),
                    onCounted: (v) => c.setCount(e.id, v),
                    onCleared: () => c.clearCount(e.id),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: counted == 0 ? null : _finish,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                counted == 0
                    ? 'Isi jumlah fisik untuk menyimpan'
                    : 'Simpan hasil opname ($counted)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpnameRow extends StatefulWidget {
  const _OpnameRow({
    super.key,
    required this.item,
    required this.counted,
    required this.onCounted,
    required this.onCleared,
  });

  final StockItem item;
  final double? counted;
  final ValueChanged<double> onCounted;
  final VoidCallback onCleared;

  @override
  State<_OpnameRow> createState() => _OpnameRowState();
}

class _OpnameRowState extends State<_OpnameRow> {
  late final TextEditingController _text = TextEditingController(
    text: widget.counted == null ? '' : formatQty(widget.counted!),
  );
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final t = value.trim();
    if (t.isEmpty) {
      setState(() => _error = null);
      widget.onCleared();
      return;
    }
    final n = parseNumber(t);
    if (n == null || n < 0) {
      setState(() => _error = 'Isi dengan angka, contoh 5 atau 1,5');
      widget.onCleared();
      return;
    }
    setState(() => _error = null);
    widget.onCounted(n);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final counted = widget.counted;
    final diff = counted == null ? null : OpnameDiff(item, counted);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sistem: ${formatQty(item.qty)} ${item.unit}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DiffBadge(diff: diff, unit: item.unit),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              onChanged: _onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(
                labelText: 'Jumlah fisik',
                suffixText: item.unit,
                errorText: _error,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon + teks + warna: "Sesuai", "Kurang 2 kg", "Lebih 1 kg", atau "Belum dihitung".
class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.diff, required this.unit});

  final OpnameDiff? diff;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final d = diff;
    if (d == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Text('Belum dihitung', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
    }
    final Color fg;
    final Color bg;
    final IconData icon;
    final String label;
    if (d.matches) {
      fg = AppColors.safe;
      bg = AppColors.safeSoft;
      icon = Icons.check_circle_outline;
      label = 'Sesuai';
    } else if (d.diff < 0) {
      fg = AppColors.danger;
      bg = AppColors.dangerSoft;
      icon = Icons.arrow_downward_rounded;
      label = 'Kurang ${formatQty(d.diff.abs())} $unit';
    } else {
      fg = AppColors.warning;
      bg = AppColors.warningSoft;
      icon = Icons.arrow_upward_rounded;
      label = 'Lebih ${formatQty(d.diff)} $unit';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// Konfirmasi sebelum stok ditimpa. Mengembalikan catatan (boleh kosong) saat disimpan,
/// atau null jika dibatalkan.
class _OpnameConfirmDialog extends StatefulWidget {
  const _OpnameConfirmDialog({required this.diffs});

  final List<OpnameDiff> diffs;

  @override
  State<_OpnameConfirmDialog> createState() => _OpnameConfirmDialogState();
}

class _OpnameConfirmDialogState extends State<_OpnameConfirmDialog> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mismatches = widget.diffs.where((d) => !d.matches).toList();

    return AlertDialog(
      title: const Text('Simpan hasil opname?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.diffs.length} barang dihitung, ${mismatches.length} ada selisih.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (mismatches.isEmpty)
              const Text('Semua jumlah sesuai dengan catatan sistem.')
            else
              for (final d in mismatches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${d.item.name}: ${formatQty(d.item.qty)} → ${formatQty(d.counted)} '
                    '${d.item.unit} (${formatSigned(d.diff)})',
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
            const SizedBox(height: 10),
            const Text(
              'Stok di sistem akan diganti sesuai jumlah fisik. '
              'Barang yang belum dihitung tidak berubah.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: opname akhir bulan',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Periksa lagi')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _note.text.trim()),
          child: const Text('Simpan & perbarui'),
        ),
      ],
    );
  }
}
