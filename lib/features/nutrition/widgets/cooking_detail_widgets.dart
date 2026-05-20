// lib/features/nutrition/widgets/cooking_detail_widgets.dart
//
// Tất cả các widget con dùng trong CookingDetailScreen.
// Được public hoá (bỏ dấu _) để có thể import từ view.

import 'package:flutter/material.dart';

// ── Header ────────────────────────────────────────────────────────────────────
class HeaderSection extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String prepTime;
  final List<String> tags;
  final VoidCallback onBack;

  const HeaderSection({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.prepTime,
    required this.tags,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF0D86CF),
              child: const Icon(Icons.restaurant, size: 80, color: Colors.white54),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent],
                stops: [0.0, 0.55],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleGlassButton(icon: Icons.arrow_back, onTap: onBack),
                  ],
                ),
                const Spacer(),
                if (tags.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: tags
                          .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t.startsWith('#') ? t : '#$t',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        prepTime,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nút Đã Ăn ────────────────────────────────────────────────────────────────
class MarkEatenButton extends StatelessWidget {
  final bool isEaten;
  final VoidCallback onTap;

  const MarkEatenButton({super.key, required this.isEaten, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: isEaten ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isEaten ? const Color(0xFFD4ECFF) : const Color(0xFF0D86CF),
          foregroundColor:
          isEaten ? const Color(0xFF0D86CF) : Colors.white,
          disabledBackgroundColor: const Color(0xFFD4ECFF),
          disabledForegroundColor: const Color(0xFF0D86CF),
          elevation: 0,
          side: isEaten
              ? const BorderSide(color: Color(0xFF0D86CF), width: 2)
              : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        icon: Icon(
          isEaten ? Icons.check_circle : Icons.check_circle_outline,
          size: 24,
        ),
        label: Text(
          isEaten ? 'Đã đánh dấu xong! (+10 điểm)' : 'Đánh dấu đã ăn (+10 điểm)',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Nutrition Row ─────────────────────────────────────────────────────────────
class NutritionRow extends StatelessWidget {
  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  const NutritionRow({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NutritionCard(
            icon: '🔥',
            value: calories,
            unit: 'kcal',
            label: 'Calo',
            valueColor: const Color(0xFF16A34A),
            bg: const Color(0xFFCFECEE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NutritionCard(
            icon: '💪',
            value: protein,
            unit: 'g',
            label: 'Đạm',
            valueColor: const Color(0xFF3B82F6),
            bg: const Color(0xFFD6E8FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NutritionCard(
            icon: '⚡',
            value: carbs,
            unit: 'g',
            label: 'Tinh bột',
            valueColor: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFF3D0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NutritionCard(
            icon: '🫒',
            value: fat,
            unit: 'g',
            label: 'Chất béo',
            valueColor: const Color(0xFFEF4444),
            bg: const Color(0xFFFFE4E4),
          ),
        ),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String icon;
  final String value;
  final String unit;
  final String label;
  final Color valueColor;
  final Color bg;

  const _NutritionCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.valueColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────
class CookingTabBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const CookingTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFD3E5F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Nguyên liệu',
            icon: Icons.inventory_2_outlined,
            selected: selectedTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabButton(
            label: 'Các bước',
            icon: Icons.restaurant_menu_outlined,
            selected: selectedTab == 1,
            onTap: () => onTabChanged(1),
          ),
          _TabButton(
            label: 'Mẹo',
            icon: Icons.lightbulb_outline,
            selected: selectedTab == 2,
            onTap: () => onTabChanged(2),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF0D86CF)
                      : const Color(0xFF64748B)),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF0D86CF)
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab: Nguyên liệu ──────────────────────────────────────────────────────────
class IngredientsTab extends StatelessWidget {
  final List<Map<String, dynamic>> ingredients;

  const IngredientsTab({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return const EmptyTabState(message: 'Chưa có thông tin nguyên liệu');
    }
    return Column(
      children: ingredients
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IngredientTile(
          name:     item['name']?.toString() ?? '',
          category: item['category']?.toString() ?? 'other',
          amount:   '${item['amount']} ${item['unit']}',
        ),
      ))
          .toList(),
    );
  }
}

// ── Tab: Các bước ─────────────────────────────────────────────────────────────
class StepsTab extends StatelessWidget {
  final List<String> steps;

  const StepsTab({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const EmptyTabState(message: 'Chưa có hướng dẫn nấu ăn');
    }
    return Column(
      children: List.generate(
        steps.length,
            (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: StepTile(index: i + 1, text: steps[i]),
        ),
      ),
    );
  }
}

// ── Tab: Mẹo ─────────────────────────────────────────────────────────────────
class TipsTab extends StatelessWidget {
  final List<String> tips;
  final String healthNote;

  const TipsTab({super.key, required this.tips, required this.healthNote});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TipTile(text: tip),
        )),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF9BCBF2), width: 1),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: '🌿 Ghi chú sức khỏe: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
                TextSpan(
                  text: healthNote,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ingredient Tile ───────────────────────────────────────────────────────────
class IngredientTile extends StatelessWidget {
  final String name;
  final String category;
  final String amount;

  const IngredientTile({
    super.key,
    required this.name,
    required this.category,
    required this.amount,
  });

  String get _label {
    switch (category) {
      case 'meat':      return 'Thịt & Hải sản';
      case 'vegetable': return 'Rau củ';
      case 'dairy':     return 'Sữa & Trứng';
      case 'grain':     return 'Ngũ cốc';
      case 'seasoning': return 'Gia vị';
      case 'protein':   return 'Đạm';
      case 'grains':    return 'Ngũ cốc';
      case 'vegetables':return 'Rau củ';
      case 'spices':    return 'Gia vị';
      case 'fats':      return 'Chất béo';
      default:          return 'Khác';
    }
  }

  Color get _dotColor {
    switch (category) {
      case 'meat':
      case 'protein':   return const Color(0xFF3B82F6);
      case 'vegetable':
      case 'vegetables':return const Color(0xFF22C55E);
      case 'dairy':     return const Color(0xFF8B5CF6);
      case 'grain':
      case 'grains':    return const Color(0xFFF59E0B);
      case 'seasoning':
      case 'spices':    return const Color(0xFFEC4899);
      case 'fats':      return const Color(0xFFEF4444);
      default:          return const Color(0xFF94A3B8);
    }
  }

  Color get _tagBg {
    switch (category) {
      case 'meat':
      case 'protein':   return const Color(0xFFE4ECFF);
      case 'vegetable':
      case 'vegetables':return const Color(0xFFDCFCE7);
      case 'dairy':     return const Color(0xFFF3E8FF);
      case 'grain':
      case 'grains':    return const Color(0xFFFFEFD8);
      case 'seasoning':
      case 'spices':    return const Color(0xFFFCE7F3);
      case 'fats':      return const Color(0xFFFEE2E2);
      default:          return const Color(0xFFE2E8F0);
    }
  }

  Color get _tagText => _dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9BCBF2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tagBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(_label,
                style: TextStyle(
                    color: _tagText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text(amount,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155))),
        ],
      ),
    );
  }
}

// ── Step Tile ─────────────────────────────────────────────────────────────────
class StepTile extends StatelessWidget {
  final int index;
  final String text;

  const StepTile({super.key, required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFF0D86CF)),
          alignment: Alignment.center,
          child: Text('$index',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF9BCBF2), width: 1),
            ),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

// ── Tip Tile ──────────────────────────────────────────────────────────────────
class TipTile extends StatelessWidget {
  final String text;

  const TipTile({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFBEDFF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9BCBF2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}

// ── Empty Tab State ───────────────────────────────────────────────────────────
class EmptyTabState extends StatelessWidget {
  final String message;

  const EmptyTabState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: Colors.black45, fontSize: 14)),
      ),
    );
  }
}

// ── Nút tròn back ─────────────────────────────────────────────────────────────
class CircleGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircleGlassButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}