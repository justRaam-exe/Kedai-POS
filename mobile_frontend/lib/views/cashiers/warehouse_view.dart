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
}