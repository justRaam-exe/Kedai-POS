import 'package:flutter/material.dart';

import '../../constants/api_config.dart';
import '../../constants/app_colors.dart';
import '../../controllers/inventory_controller.dart';
import '../../models/stock_item.dart';
import '../auth/login_view.dart';
import 'pages/activity_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/inventory_page.dart';
import 'pages/opname_page.dart';
import 'sheets/item_form_sheet.dart';
import 'sheets/stock_detail_sheet.dart';
import 'sheets/stock_movement_sheet.dart';

/// Kerangka aplikasi setelah login: app bar, 4 tab, dan penghubung antarhalaman.
/// Dipakai bersama oleh Owner (isOwner: true) dan Kasir (isOwner: false).
class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key, required this.isOwner});

  final bool isOwner;

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  static const List<String> _titles = ['Beranda', 'Inventaris', 'Opname', 'Aktivitas'];

  late final InventoryController _controller =
      InventoryController(actor: _role);

  int _tab = 0;
  StatusFilter _statusFilter = StatusFilter.all;

  String get _role => widget.isOwner ? 'Owner' : 'Kasir';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openInventory(StatusFilter filter) {
    setState(() {
      _statusFilter = filter;
      _tab = 1;
    });
  }

  void _openItem(StockItem item) =>
      showStockDetailSheet(context, _controller, item, isOwner: widget.isOwner);

  void _stockMovement(bool incoming) =>
      showStockMovementSheet(context, _controller, incoming: incoming);

  void _addItem() => showItemFormSheet(context, _controller);

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk membuka aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final attention = _controller.attentionCount;

        final pages = <Widget>[
          DashboardPage(
            controller: _controller,
            isOwner: widget.isOwner,
            onOpenInventory: _openInventory,
            onOpenOpname: () => setState(() => _tab = 2),
            onStockMovement: _stockMovement,
            onItemTap: _openItem,
          ),
          InventoryPage(
            controller: _controller,
            isOwner: widget.isOwner,
            statusFilter: _statusFilter,
            onStatusFilterChanged: (f) => setState(() => _statusFilter = f),
            onItemTap: _openItem,
            onAddItem: _addItem,
          ),
          OpnamePage(controller: _controller),
          ActivityPage(controller: _controller),
        ];

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[_tab],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  ApiConfig.demoData ? 'Mode $_role · Data contoh' : 'Mode $_role',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Akun',
                icon: const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.person, color: AppColors.primaryDark, size: 20),
                ),
                onSelected: (v) {
                  if (v == 'logout') _confirmLogout();
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'Masuk sebagai $_role',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 12),
                        Text('Keluar'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: IndexedStack(index: _tab, children: pages),
          bottomNavigationBar: NavigationBar(
            height: 68,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primarySoft,
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primaryDark),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text('$attention'),
                  isLabelVisible: attention > 0,
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                selectedIcon: Badge(
                  label: Text('$attention'),
                  isLabelVisible: attention > 0,
                  child: const Icon(Icons.inventory_2, color: AppColors.primaryDark),
                ),
                label: 'Inventaris',
              ),
              const NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check, color: AppColors.primaryDark),
                label: 'Opname',
              ),
              const NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.history_rounded, color: AppColors.primaryDark),
                label: 'Aktivitas',
              ),
            ],
          ),
        );
      },
    );
  }
}
