import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../controllers/inventory_controller.dart';
import '../../../models/stock_item.dart';
import '../../../utils/formatters.dart';
import '../widgets/status_pill.dart';
import 'item_form_sheet.dart';
import 'stock_movement_sheet.dart';

/// Ringkasan satu barang + aksi cepat (stok masuk, stok keluar, edit).
/// Dibuka saat baris barang diketuk, untuk Owner maupun Kasir.
Future<void> showStockDetailSheet(
  BuildContext context,
  InventoryController controller,
  StockItem item, {
  required bool isOwner,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      void openNext(Future<void> Function() open) {
        Navigator.pop(sheetContext);
        open();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusPill(status: item.status),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stok saat ini',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        Text(
                          '${formatQty(item.qty)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Batas minimum',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      Text(
                        '${formatQty(item.minimum)} ${item.unit}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.needsAttention) ...[
              const SizedBox(height: 10),
              Text(
                item.status == StockStatus.habis
                    ? 'Stok sudah habis. Catat stok masuk setelah belanja.'
                    : 'Stok sudah di bawah batas minimum. Sebaiknya belanja lagi.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: statusColor(item.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => openNext(
                        () => showStockMovementSheet(
                          context,
                          controller,
                          incoming: true,
                          item: item,
                        ),
                      ),
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Stok masuk'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => openNext(
                        () => showStockMovementSheet(
                          context,
                          controller,
                          incoming: false,
                          item: item,
                        ),
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Stok keluar'),
                    ),
                  ),
                ),
              ],
            ),
            if (isOwner) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => openNext(
                  () => showItemFormSheet(context, controller, item: item),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit data barang'),
              ),
            ],
          ],
        ),
      );
    },
  );
}
