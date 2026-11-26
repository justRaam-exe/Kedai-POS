import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';

class WarehouseView extends StatefulWidget {
  const WarehouseView({Key? key}) : super(key: key);

  @override
  State<WarehouseView> createState() => _WarehouseViewState();
}

class _WarehouseViewState extends State<WarehouseView> {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const List<String> _units = ['pcs', 'kg', 'gram', 'liter', 'ml'];

  List _products = [];
  List _categories = [];
  int? _selectedCategoryFilter;
  bool _isLoading = true;
  bool _isFabMenuOpen = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/categories')),
        http.get(Uri.parse('$_baseUrl/products')),
      ]);

      final catJson = jsonDecode(results[0].body);
      final prodJson = jsonDecode(results[1].body);

      if (results[0].statusCode == 200 && catJson['success'] == true) {
        _categories = List.from(catJson['data'] ?? []);
      }
      if (results[1].statusCode == 200 && prodJson['success'] == true) {
        _products = List.from(prodJson['data'] ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data gudang: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generatedAutoItemCode() {
    final nextNumber = _products.length + 1;
    return 'KSR${nextNumber.toString().padLeft(3, '0')}';
  }

  String _formatRupiah(num amount) {
    final intVal = amount.round().toString();
    final chars = intVal.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  // Pop-up Add category
  void _showAddCategoryDialog() {
    setState(() => _isFabMenuOpen = false);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            'Tambah Kategori',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Masukkan nama kategori',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx)
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama Kategori tidak boleh kosong'))
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  final res = await http.post(
                    Uri.parse('$_baseUrl/categories'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'name': name}),
                  );
                  final data = jsonDecode(res.body);
                  if (res.statusCode == 200 && data['success'] == true) {
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kategori $name berhasil ditambahkan')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(data['message'] ?? 'Gagal menambah kategori')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  // Pop-up Add or Edit
  void _showProductFormDialog({Map<String, dynamic>? existingProduct}) {
    setState(() => _isFabMenuOpen = false);
    final bool isEdit = existingProduct != null;

    final nameController = TextEditingController(text: existingProduct?['name']?.toString() ?? '');
    final priceController = TextEditingController(
      text: existingProduct != null ? (existingProduct['price'] as num).round().toString() : '',
    );
    final stockController = TextEditingController(
      text: existingProduct != null ? existingProduct['stock'].toString() : '',
    );
    final minStockController = TextEditingController(
      text: existingProduct != null ? existingProduct['min_stock'].toString() : '0',
    );
    final codeController = TextEditingController(
      text: existingProduct?['item_code']?.toString() ?? '',
    );

    String selectedUnit =existingProduct?['unit']?.toString() ?? _units.first;
    if (!_units.contains(selectedUnit)) selectedUnit = _units.first;

    int? selectedCategoryId = existingProduct?['category_id'] as int?;
    if (selectedCategoryId == null && _categories.isNotEmpty) {
      selectedCategoryId = _categories.first['id'] as int;
    }

    String? imagePath = existingProduct?['image_path']?.toString();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                setModalState(() => imagePath = picked.path);
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Kelola Barang' : 'Tambah Barang',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // image field
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            if (imagePath != null && imagePath!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(imagePath!),
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 60,
                                    child: Center(child: Text('Preview gambar tidak tersedia')),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: pickImage,
                                  icon: const Icon(Icons.image, color: AppColors.primary),
                                  label: Text(
                                    imagePath == null || imagePath!.isEmpty ? 'Pilih Gambar (Opsional)' : 'Ganti gambar',
                                    style: const TextStyle(color: AppColors.textDark),
                                  ),
                                ),
                                if (imagePath != null && imagePath!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setModalState(() => imagePath = null),
                                    child: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12)

                      // Name Text Field
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama barang',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price Field
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga barang (RP)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stock Field
                      TextField(
                        controller: stockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Stok Barang',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Button list satuan barang
                      const Text('Satuan barang:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _units.map((unit) {
                          final isSelected = selectedUnit == unit;
                          return ChoiceChip(
                            label: Text(unit),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setModalState(() => selectedUnit = unit),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Category Option List
                      DropdownButtonFormField<int?>(
                        value: selectedcategoryId,
                        decoration: InputDecoration(
                          labelText: 'Kategori barang',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Tanpa kategori')),
                          ..._categories.map(
                              (cat) => DropdownMenuItem<int?>(
                                value: cat['id'] as int,
                                child: Text(cat['name'].toString()),
                              ),
                          ),
                        ],
                        onChanged: (val) => setModalState(() => selectedCategoryId = val),
                      ),
                      const SizedBox(height: 12),

                      // Num field Min stock
                      TextField(
                        controller: minStockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Batas Minimum Stok',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Kode Barang (Opsional)',
                          hintText: _generatedAutoItemCode(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                    ? null
                    : () async {
                      final name = nameController.text.trim();
                      final price = double.tryParse(priceController.text.trim()) ?? 0;
                      final stock = double.tryParse(stockController.text.trim()) ?? 0;
                      final minStock = double.tryParse(minStockController.text.trim()) ?? 0;
                      final rawCode = codeController.text.trim();
                      final finalCode = rawCode.isEmpty
                        ? (isEdit ? (existingProduct['item_code'] ?? _generatedAutoItemCode()) : _generatedAutoItemCode())
                        : rawCode.toUpperCase();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama barang wajib diisi!')),
                        );
                        return;
                      }

                      setModalState(() => isSaving = true);
                      try {
                        final payload = {
                          'name': name,
                          'price': price,
                          'stock': stock,
                          'unit': selectedUnit,
                          'category_id': selectedCategoryId,
                          'min_stock': minStock,
                          'item_code': finalCode,
                          'image_path': imagePath,
                        };

                        final http.Response res = isEdit
                          ? await http.put(
                              Uri.parse('$_baseUrl/products/${existingProduct['id']}'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode(payload),
                            )
                          : await http.post(
                              Uri.parse('$_baseUrl/products'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode(payload),
                            );
                        final data = jsonDecode(res.body);
                        if (res.statusCode == 200 && data['success'] == true) {
                          if (mounted) Navigator.pop(ctx);
                          await _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit ? 'Barang berhasil diperbarui' : 'Barang berhasil disimpan ($finalCode)',
                                ),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['message'] ?? 'Gagal menyimpan barang')),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } finally {
                        setModalState(() => isSaving = false);
                      }
                  },
                  child: Text(isSaving ? 'Menyimpan...' : 'Simpan Barang'),
                ),
              ],
            );
          },
        );
      }
    );
  }

  // Confirmed delete pop up
}