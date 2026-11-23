import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/stock_item.dart';
import '../../../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_heading.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key, required this.controller});

  final InventoryController controller;

  static IconData _icon(ActivityType t) {
    if (t == ActivityType.stockIn) return Icons.add_box_outlined;
    if (t == ActivityType.stockOut) return Icons.remove_circle_outline;
    if (t == ActivityType.opname) return Icons.fact_check_outlined;
    if (t == ActivityType.itemAdded) return Icons.add_circle_outline;
    if (t == ActivityType.itemDeleted) return Icons.delete_outline;
    return Icons.edit_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final entries = controller.activity;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SectionHeading(
          'Aktivitas terbaru',
          subtitle: 'Riwayat perubahan stok dan data barang.',
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'Belum ada aktivitas',
            message: 'Stok masuk, stok keluar, dan opname akan tercatat di sini.',
          )
        else
          ...entries.map(
            (a) => Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon(a.type), size: 20, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (a.detail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              a.detail!,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${a.actor} · ${formatActivityTime(a.time)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
