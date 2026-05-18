// lib/features/grocery/widgets/grocery_category_section.dart
//
// Widget hiển thị 1 nhóm nguyên liệu (vd: Rau & Củ quả)
// Có thể collapse/expand, hiện badge đã mua / tổng

import 'package:flutter/material.dart';

import '../../../data/models/recipe_model.dart';
import '../viewmodels/grocery_state.dart';
import 'grocery_item_tile.dart';
import 'grocery_category_config.dart';

class GroceryCategorySection extends StatefulWidget {
  final IngredientCategory category;
  final List<AggregatedItem> items;
  final void Function(String name, String unit) onToggle;

  const GroceryCategorySection({
    super.key,
    required this.category,
    required this.items,
    required this.onToggle,
  });

  @override
  State<GroceryCategorySection> createState() =>
      _GroceryCategorySectionState();
}

class _GroceryCategorySectionState extends State<GroceryCategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final info = GroceryCategoryConfig.of(widget.category);
    final boughtCount = widget.items.where((i) => i.isBought).length;
    final total = widget.items.length;
    final allDone = boughtCount == total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Section Header ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: info.lightColor,
                borderRadius: _expanded
                    ? const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                )
                    : BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(info.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      info.label,
                      style: TextStyle(
                        color: info.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Badge đếm
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: allDone
                          ? info.color
                          : info.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$boughtCount/$total',
                      style: TextStyle(
                        color: allDone ? Colors.white : info.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mũi tên collapse
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: info.color.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Item list (collapsible) ───────────────────────────────────────
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                for (int i = 0; i < widget.items.length; i++) ...[
                  GroceryItemTile(
                    item: widget.items[i],
                    accentColor: info.color,
                    onToggle: () => widget.onToggle(
                      widget.items[i].name,
                      widget.items[i].unit,
                    ),
                  ),
                  if (i < widget.items.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Colors.grey.withOpacity(0.15),
                    ),
                ],
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}