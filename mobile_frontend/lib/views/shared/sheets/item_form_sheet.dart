import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/stock_item.dart';
import '../../../utils/formatters.dart';

/// Form tambah barang (item == null) atau edit barang (item != null). Khusus Owner.
Future<void> showItemFormSheet(
  BuildContext context,
  InventoryController controller, {
  StockItem? item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ItemFormSheet(controller: controller, item: item),
  );
}

class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({required this.controller, this.item});

  final InventoryController controller;
  final StockItem? item;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.item?.name ?? '');
  final TextEditingController _qty = TextEditingController();
  late final TextEditingController _min =
      TextEditingController(text: formatQty(widget.item?.minimum ?? 5));
  late String _category = widget.item?.category ?? kCategories.first;
  late String _unit = widget.item?.unit ?? kUnits.first;

  bool get _isEdit => widget.item != null;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _min.dispose();
    super.dispose();
  }

  static final _numberFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  String? _validateNumber(String? value) {
    final n = parseNumber(value ?? '');
    if (n == null) return 'Isi dengan angka, contoh 5 atau 1,5';
    if (n < 0) return 'Tidak boleh negatif';
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    final minimum = parseNumber(_min.text) ?? 0;
    final messenger = ScaffoldMessenger.of(context);
    final String message;
    if (_isEdit) {
      widget.controller.updateItem(
        widget.item!.id,
        name: name,
        category: _category,
        unit: _unit,
        minimum: minimum,
      );
      message = 'Data $name diperbarui';
    } else {
      widget.controller.addItem(
        name: name,
        category: _category,
        qty: parseNumber(_qty.text) ?? 0,
        unit: _unit,
        minimum: minimum,
      );
      message = '$name ditambahkan';
    }
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete() async {
    final item = widget.item;
    if (item == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${item.name}?'),
        content: const Text(
          'Barang dan jumlah stoknya dihapus dari daftar. '
          'Riwayat aktivitas tetap tersimpan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    widget.controller.deleteItem(item.id);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('${item.name} dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        kCategories.contains(_category) ? kCategories : <String>[...kCategories, _category];
    final units = kUnits.contains(_unit) ? kUnits : <String>[...kUnits, _unit];

    final unitField = DropdownButtonFormField<String>(
      value: _unit,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Satuan'),
      items: units.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
      onChanged: (v) => setState(() => _unit = v ?? _unit),
    );

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
                _isEdit ? 'Edit barang' : 'Tambah barang',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama barang'),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Nama barang wajib diisi';
                  if (widget.controller.nameExists(value, exceptId: widget.item?.id)) {
                    return 'Barang ini sudah ada di daftar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories
                    .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              if (_isEdit)
                unitField
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qty,
                        textInputAction: TextInputAction.next,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [_numberFormatter],
                        decoration: const InputDecoration(labelText: 'Stok awal'),
                        validator: _validateNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 130, child: unitField),
                  ],
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _min,
                textInputAction: TextInputAction.done,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_numberFormatter],
                decoration: InputDecoration(
                  labelText: 'Batas minimum stok',
                  suffixText: _unit,
                  helperText: 'Stok dianggap menipis jika sama dengan atau di bawah angka ini.',
                  helperMaxLines: 2,
                ),
                validator: _validateNumber,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 10),
                const Text(
                  'Jumlah stok diubah lewat Stok masuk, Stok keluar, atau Opname '
                  'agar tercatat di aktivitas.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    _isEdit ? 'Simpan perubahan' : 'Simpan barang',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus barang'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
