import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/stock_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_card.dart';
import '../widgets/quick_action.dart';
import '../widgets/section_heading.dart';
import '../widgets/stock_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.isOwner,
    required this.onOpenInventory,
    required this.onOpenOpname,
    required this.onStockMovement,
    required this.onItemTap,
  });

  final InventoryController controller;
  final bool isOwner;
  final ValueChanged<StatusFilter> onOpenInventory;
  final VoidCallback onOpenOpname;

  /// true = stok masuk, false = stok keluar.
  final ValueChanged<bool> onStockMovement;
  final ValueChanged<StockItem> onItemTap;

  static const int _maxAttention = 5;

  @override
  Widget build(BuildContext context) {
    final attention = controller.attentionItems;
    final attentionCount = attention.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _GreetingBanner(isOwner: isOwner, attentionCount: attentionCount),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: QuickAction(
                icon: Icons.add_box_outlined,
                label: 'Stok masuk',
                onTap: () => onStockMovement(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickAction(
                icon: Icons.remove_circle_outline,
                label: 'Stok keluar',
                onTap: () => onStockMovement(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickAction(
                icon: Icons.fact_check_outlined,
                label: 'Mulai opname',
                onTap: onOpenOpname,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeading(
          'Perlu diperhatikan',
          subtitle: attentionCount == 0 ? null : 'Ketuk barang untuk mencatat stok masuk.',
          trailing: attentionCount > _maxAttention
              ? TextButton(
                  onPressed: () => onOpenInventory(StatusFilter.attention),
                  child: Text('Lihat semua ($attentionCount)'),
                )
              : null,
        ),
        const SizedBox(height: 10),
        if (attention.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Semua stok aman',
            message: 'Tidak ada barang yang menipis atau habis saat ini.',
            color: AppColors.safe,
            softColor: AppColors.safeSoft,
          )
        else
          ...attention
              .take(_maxAttention)
              .map((e) => StockTile(item: e, onTap: () => onItemTap(e))),
        const SizedBox(height: 14),
        const SectionHeading('Ringkasan persediaan'),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: MetricCard(
                label: 'Jenis barang',
                value: '${controller.totalCount}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.primaryDark,
                onTap: () => onOpenInventory(StatusFilter.all),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Stok aman',
                value: '${controller.safeCount}',
                icon: Icons.check_circle_outline,
                color: AppColors.safe,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: MetricCard(
                label: 'Stok menipis',
                value: '${controller.lowCount}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                onTap: () => onOpenInventory(StatusFilter.low),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Stok habis',
                value: '${controller.emptyCount}',
                icon: Icons.error_outline,
                color: AppColors.danger,
                onTap: () => onOpenInventory(StatusFilter.empty),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({required this.isOwner, required this.attentionCount});

  final bool isOwner;
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bannerStart, AppColors.bannerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwner ? 'Halo, Owner!' : 'Halo, Kasir!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  attentionCount == 0
                      ? 'Semua stok aman hari ini.'
                      : '$attentionCount barang perlu diperhatikan hari ini.',
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.ramen_dining_rounded, size: 46, color: Colors.white),
        ],
      ),
    );
  }
}
