import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';

class SalesView extends StatefulWidget {
  const SalesView({Key? key}) : super(key: key);

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  static const String _baseUrl = 'http://localhost:3000/api';

  List _products = [];
  final Map<int, Map<String, dynamic>> _cart = {};
  bool _isLoadingProducts = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products'));
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['success'] == true) {
        setState(() {
          _products = List.from(decoded['data'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    final int id = product['id'];
    final double stock = (product['stock'] as num).toDouble();
    final currentQty = (_cart[id]?['qty'] ?? 0).toDouble();

    if (stock <= 0 || currentQty + 1 > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok ${product['name']} tidak mencukupi')),
      );
      return;
    }
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id]!['qty'] = currentQty + 1;
      } else {
        _cart[id] = {
          'product_id': id,
          'product_name': product['name'],
          'price': (product['price'] as num).toDouble(),
          'unit': product['unit'] ?? 'pcs',
          'qty': 1.0,
        };
      }
    });
  }

  void _updateQty(int productId, double delta) {
    if (!_cart.containsKey(productId)) return;
    final currentQty = (_cart[productId]!['qty'] as num).toDouble();
    final newQty = currentQty + delta;

    final product = _products.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => {'stock': newQty},
    );
    final maxStock = (product['stock'] as num).toDouble();

    if (newQty > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Melebihi stok tersedia!')),
      );
      return;
    }

    setState(() {
      if (newQty <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId]!['qty'] = newQty;
      }
    });
  }

  double get _totalBelanja {
    double total = 0;
    for (final item in _cart.values) {
      total += (item['price'] as double) * (item['qty'] as double);
    }
    return total;
  }

  String _formatRupiah(double amount) {
    final intVal = amount.round().toString();
    final chars = intVal.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  void _openCheckoutModal() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose 1 first!')),
      );
      return;
    }
    String selectedMethod = 'qris';
    final cashController = TextEditingController(text: _totalBelanja.round().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double paidCash = double.tryParse(cashController.text.trim()) ?? 0;
            final double changeCash = selectedMethod == 'cash' ? (paidCash >= _totalBelanja ? paidCash - _totalBelanja : 0) : 0;

            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Pembayaran Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total tagihan', style: TextStyle(fontSize: 15)),
                          Text(
                            _formatRupiah(_totalBelanja),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pilih Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('QRIS')),
                            selected: selectedMethod == 'qris',
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: selectedMethod == 'qris' ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              setModalState(() => selectedMethod = 'qris');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('CASH')),
                            selected: selectedMethod == 'cash',
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: selectedMethod == 'cash' ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              setModalState(() => selectedMethod = 'cash');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedMethod == 'qris')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'Selesaikan Pembayaran untuk langsung menandai transaksi lunas',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      )
                    else ...[
                      TextField(
                        controller: cashController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Uang Diterima',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            _formatRupiah(changeCash),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ],
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
                  onPressed: _isSubmitting ? null : () async {
                    final double paidAmount = selectedMethod == 'qris' ? _totalBelanja : (double.tryParse(cashController.text.trim()) ?? 0);
                    if (selectedMethod == 'cash' && paidAmount < _totalBelanja) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uang tunai kurang dari total belanja!')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    await _submitTransaction(
                      paymentMethod: selectedMethod,
                      paidAmount: paidAmount,
                    );
                  },
                  child: Text(
                    selectedMethod == 'qris' ? 'selesaikan pembayaran' : 'bayar tunai',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitTransaction({
    required String paymentMethod,
    required double paidAmount,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'payment_method' : paymentMethod,
        'paid_amount' : paidAmount,
        'items' : _cart.values.toList(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: {'Content-Type' : 'application/json'},
        body: jsonEncode(payload)
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['success'] == true) {
        final txData = decoded['data'];
        setState(() {
          _cart.clear();
        });
        await _fetchProducts(); //Refresh for new stock

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Transaksi Berhasil!'),
            content: Text(
              'No. Invoice: ${txData['invoice_code']}\n'
                  'Metode: ${paymentMethod.toUpperCase()}\n'
                  'Total: ${_formatRupiah((txData['total_amount'] as num).toDouble())}\n'
                  'Kembalian: ${_formatRupiah((txData['change_amount'] as num).toDouble())}',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          )
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded['message'] ?? 'Gagal Memproses Transaksi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error koneksi transaksi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_products.isEmpty) {
      return const Center(
        child: Text('Belum ada produk, Tambahkan barang di menu stok gudang terlebih dahulu'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        childAspectRatio: 0.95,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        final double price = (p['price'] as num).toDouble();
        final double stock = (p['stock'] as num).toDouble();
        final String unit = p['unit'] ?? 'pcs';
      },
    )
  }
}