import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../auth/login_view.dart';
import 'sales_view.dart';
import 'warehouse_view.dart';

class CashierDashboard extends StatelessWidget {
  const CashierDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List menuItems = [
      {'title': 'Sales', 'icon': Icons.point_of_sale, 'color': AppColors.primary, 'view': const SalesView()},
      {'title': 'Stok Gudang', 'icon':Icons.inventory, 'color': AppColors.accent, 'view': const WarehouseView()},
      {'title': 'History', 'icon':Icons.history, 'color': AppColors.primary, 'view': const HistoryView()},
      {'title': 'Kustomisasi Struk', 'icon':Icons.receipt, 'color': AppColors.primary, 'view': const ReceiptCustomizationView()},
      {'title': 'Tutup Harian', 'icon':Icons.assessment, 'color': AppColors.primary, 'view': const DailyClosingView()},
      {'title': 'Setelan', 'icon':Icons.settings, 'color': AppColors.primary, 'view': const SettingView()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Kasir - Kedai Seblak Rheya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar Akun',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Menu Kasir',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => item['view']),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: item['color'].withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item['icon'], size: 48, color: item['color']),
                          const SizedBox(height: 12),
                          Text(
                            item['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
          ],
        )
      ),
    );
  }
}