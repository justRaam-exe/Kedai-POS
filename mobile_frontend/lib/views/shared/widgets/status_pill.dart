import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/stock_item.dart';

Color statusColor(StockStatus s) {
  if (s == StockStatus.habis) return AppColors.danger;
  if (s == StockStatus.menipis) return AppColors.warning;
  return AppColors.safe;
}

Color statusSoftColor(StockStatus s) {
  if (s == StockStatus.habis) return AppColors.dangerSoft;
  if (s == StockStatus.menipis) return AppColors.warningSoft;
  return AppColors.safeSoft;
}

IconData statusIcon(StockStatus s) {
  if (s == StockStatus.habis) return Icons.error_outline;
  if (s == StockStatus.menipis) return Icons.warning_amber_rounded;
  return Icons.check_circle_outline;
}

String statusLabel(StockStatus s) {
  if (s == StockStatus.habis) return 'Habis';
  if (s == StockStatus.menipis) return 'Menipis';
  return 'Aman';
}

/// Label status berisi ikon + teks + warna, jadi tidak bergantung pada warna saja.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusSoftColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            statusLabel(status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
