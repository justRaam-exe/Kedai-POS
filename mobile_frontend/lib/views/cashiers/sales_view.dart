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
  }
}