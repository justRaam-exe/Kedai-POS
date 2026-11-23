import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/stock_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/stock_tile.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.controller,
    required this.isOwner,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.onItemTap,
    required this.onAddItem,
  });

  final InventoryController controller;
  final bool isOwner;
  final StatusFilter statusFilter;
  final ValueChanged<StatusFilter> onStatusFilterChanged;
  final ValueChanged<StockItem> onItemTap;
  final VoidCallback onAddItem;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _category; // null = semua kategori

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _statusLabel(StatusFilter f) {
    if (f == StatusFilter.attention) return 'Perlu perhatian';
    if (f == StatusFilter.low) return 'Menipis';
    if (f == StatusFilter.empty) return 'Habis';
    return 'Semua status';
  }

  bool _matches(StockItem e) {
    final f = widget.statusFilter;
    if (f == StatusFilter.attention && !e.needsAttention) return false;
    if (f == StatusFilter.low && e.status != StockStatus.menipis) return false;
    if (f == StatusFilter.empty && e.status != StockStatus.habis) return false;
    if (_category != null && e.category != _category) return false;
    final q = _query.trim().toLowerCase();
    return q.isEmpty || e.name.toLowerCase().contains(q);
  }

  void _resetFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _category = null;
    });
    widget.onStatusFilterChanged(StatusFilter.all);
  }

  Widget _chipRow(List<Widget> chips) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primarySoft,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primaryDark : AppColors.textDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.controller.sortedItems;
    final shown = all.where(_matches).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${shown.length} dari ${all.length} barang',
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
            if (widget.isOwner)
              FilledButton.icon(
                onPressed: widget.onAddItem,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah barang'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Cari nama barang',
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
        const SizedBox(height: 10),
        _chipRow([
          for (final f in StatusFilter.values)
            _chip(
              _statusLabel(f),
              widget.statusFilter == f,
              () => widget.onStatusFilterChanged(f),
            ),
        ]),
        _chipRow([
          _chip('Semua kategori', _category == null, () => setState(() => _category = null)),
          for (final c in kCategories)
            _chip(c, _category == c, () => setState(() => _category = c)),
        ]),
        const SizedBox(height: 8),
        if (all.isEmpty)
          EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Belum ada barang',
            message: widget.isOwner
                ? 'Tambahkan bahan baku pertama untuk mulai memantau stok.'
                : 'Minta Owner menambahkan barang terlebih dahulu.',
            actionLabel: widget.isOwner ? 'Tambah barang' : null,
            onAction: widget.isOwner ? widget.onAddItem : null,
          )
        else if (shown.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Barang tidak ditemukan',
            message: 'Coba kata kunci lain atau tampilkan semua barang.',
            actionLabel: 'Reset filter',
            onAction: _resetFilters,
          )
        else
          ...shown.map((e) => StockTile(item: e, onTap: () => widget.onItemTap(e))),
      ],
    );
  }
}
