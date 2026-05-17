// lib/features/grocery/widgets/grocery_item_tile.dart

import 'package:flutter/material.dart';

import '../viewmodels/grocery_state.dart';

class GroceryItemTile extends StatelessWidget {
  final AggregatedItem item;
  final Color accentColor;
  final VoidCallback onToggle;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Format số: bỏ .0 nếu là số nguyên
    final amountStr = item.totalAmount == item.totalAmount.roundToDouble()
        ? item.totalAmount.toInt().toString()
        : item.totalAmount.toStringAsFixed(1);

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Checkbox tròn ──────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isBought
                      ? accentColor
                      : Colors.grey.withOpacity(0.4),
                  width: 2,
                ),
                color: item.isBought ? accentColor : Colors.transparent,
              ),
              child: item.isBought
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 16)
                  : null,
            ),

            const SizedBox(width: 14),

            // ── Tên nguyên liệu ────────────────────────────────────────────
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: item.isBought
                      ? Colors.grey.withOpacity(0.55)
                      : const Color(0xFF1F2937),
                  decoration:
                  item.isBought ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey.withOpacity(0.55),
                ),
              ),
            ),

            // ── Số lượng + số bữa ──────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountStr ${item.unit}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: item.isBought
                        ? Colors.grey.withOpacity(0.5)
                        : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.mealCount} bữa',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}