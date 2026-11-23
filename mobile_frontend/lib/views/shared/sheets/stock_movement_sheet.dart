import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/stock_item.dart';
import '../../../utils/formatters.dart';

/// Form stok masuk (incoming = true) atau stok keluar (incoming = false).
/// Jika [item] diberikan, barang sudah terpilih dan tidak perlu memilih lagi.
Future<void> showStockMovementSheet(
  BuildContext context,
  InventoryController controller, {
  required bool incoming,
  StockItem? item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _StockMovementSheet(controller: controller, incoming: incoming, item: item),
  );
}

class _StockMovementSheet extends StatefulWidget {
  const _StockMovementSheet({
    required this.controller,
    required this.incoming,
    this.item,
  });

  final InventoryController controller;
  final bool incoming;
  final StockItem? item;

  @override
  State<_StockMovementSheet> createState() => _StockMovementSheetState();
}

class _StockMovementSheetState extends State<_StockMovementSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  late String? _itemId = widget.item?.id;

  StockItem? get _selected => widget.controller.byId(_itemId);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final n = parseNumber(value ?? '');
    if (n == null) return 'Isi jumlah dengan angka, contoh 2 atau 1,5';
    if (n <= 0) return 'Jumlah harus lebih dari 0';
    final selected = _selected;
    if (!widget.incoming && selected != null && n > selected.qty + 0.0005) {
      return 'Melebihi stok tersedia (${formatQty(selected.qty)} ${selected.unit})';
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final item = _selected;
    final amount = parseNumber(_amount.text);
    if (item == null || amount == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final note = _note.text.trim();
    if (widget.incoming) {
      widget.controller.recordStockIn(item, amount, note: note);
    } else {
      widget.controller.recordStockOut(item, amount, note: note);
    }
    Navigator.pop(context);
    final sign = widget.incoming ? '+' : '−';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${widget.incoming ? 'Stok masuk' : 'Stok keluar'} dicatat: '
          '${item.name} $sign${formatQty(amount)} ${item.unit}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incoming = widget.incoming;
    final selected = _selected;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                incoming ? 'Catat stok masuk' : 'Catat stok keluar',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                incoming
                    ? 'Barang yang baru dibeli atau diterima.'
                    : 'Barang yang terpakai, rusak, atau dibuang.',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              if (widget.item != null)
                _SelectedItemCard(item: widget.item!, controller: widget.controller)
              else
                DropdownButtonFormField<String>(
                  value: _itemId,
                  isExpanded: true,
                  hint: const Text('Pilih barang'),
                  decoration: const InputDecoration(labelText: 'Barang'),
                  items: widget.controller.sortedItems
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(
                            '${e.name} · ${formatQty(e.qty)} ${e.unit}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  validator: (v) => v == null ? 'Pilih barang dulu' : null,
                  onChanged: (v) => setState(() => _itemId = v),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amount,
                autofocus: widget.item != null,
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: incoming ? 'Jumlah masuk' : 'Jumlah keluar',
                  suffixText: selected?.unit,
                  helperText: !incoming && selected != null
                      ? 'Tersedia: ${formatQty(selected.qty)} ${selected.unit}'
                      : null,
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _note,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: incoming ? 'Contoh: belanja di pasar' : 'Contoh: dipakai produksi',
                ),
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    incoming ? 'Simpan stok masuk' : 'Simpan stok keluar',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedItemCard extends StatelessWidget {
  const _SelectedItemCard({required this.item, required this.controller});

  final StockItem item;
  final InventoryController controller;

  @override
  Widget build(BuildContext context) {
    // Baca data terbaru supaya jumlah yang tampil tidak basi.
    final current = controller.byId(item.id) ?? item;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.fastfood_outlined, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              current.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            'Stok: ${formatQty(current.qty)} ${current.unit}',
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
