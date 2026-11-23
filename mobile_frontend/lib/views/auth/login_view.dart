import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_config.dart';
import '../../constants/app_colors.dart';
import '../cashiers/cashier_dashboard.dart';
import '../owners/owner_dashboard.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  bool _isLoading = false;
  bool _hidePin = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      final response = await http
          .post(
            ApiConfig.login,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': _usernameController.text.trim(),
              'pin_code': _pinController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        final role = data['data']['role'];
        if (role == 'kasir') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(builder: (_) => const CashierDashboard()),
          );
        } else if (role == 'owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(builder: (_) => const OwnerDashboard()),
          );
        } else {
          _message('Peran akun tidak dikenali. Hubungi owner.');
        }
      } else {
        _message(data['message'] ?? 'Login gagal. Periksa username dan PIN.');
      }
    } catch (_) {
      if (mounted) {
        _message('Tidak dapat terhubung ke server. Periksa koneksi dan alamat API.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _formCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'Lupa PIN? Hubungi owner kedai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bannerStart, AppColors.bannerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.4)),
            ),
            child: const Icon(Icons.ramen_dining_rounded, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kedai Seblak Rheya',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manajemen stok & opname',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selamat datang!',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masuk dengan username dan PIN dari owner.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              onFieldSubmitted: (_) => _pinFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Username wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pinController,
              focusNode: _pinFocus,
              obscureText: _hidePin,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: 'PIN (4 angka)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hidePin ? 'Tampilkan PIN' : 'Sembunyikan PIN',
                  onPressed: () => setState(() => _hidePin = !_hidePin),
                  icon: Icon(
                    _hidePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) => (v ?? '').trim().length != 4 ? 'PIN harus 4 angka' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text(
                        'Masuk',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
