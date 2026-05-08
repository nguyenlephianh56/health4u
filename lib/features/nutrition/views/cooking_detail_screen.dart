import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0); // 0: Nguyên liệu, 1: Các bước, 2: Mẹo
final mealCompletedProvider = StateProvider<bool>((ref) => false);

class CookingDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> meal;

  const CookingDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final isCompleted = ref.watch(mealCompletedProvider);

    final tags = (meal['tags'] as List?)?.cast<String>() ??
        ['#omega-3', '#giàu-đạm', '#không-gluten'];

    final ingredients = (meal['ingredients'] as List?)?.cast<Map<String, dynamic>>() ??
        [
          {'name': 'Salmon Fillet', 'type': 'Protein', 'amount': '150 g', 'dot': const Color(0xFF3B82F6)},
          {'name': 'Brown Rice', 'type': 'Grains', 'amount': '100 g', 'dot': const Color(0xFFF59E0B)},
          {'name': 'Edamame', 'type': 'Protein', 'amount': '50 g', 'dot': const Color(0xFF3B82F6)},
          {'name': 'Cucumber', 'type': 'Vegetables', 'amount': '60 g', 'dot': const Color(0xFF22C55E)},
          {'name': 'Soy Sauce', 'type': 'Spices', 'amount': '15 ml', 'dot': const Color(0xFFEC4899)},
          {'name': 'Sesame Oil', 'type': 'Fats', 'amount': '5 ml', 'dot': const Color(0xFFEF4444)},
          {'name': 'Sesame Seeds', 'type': 'Spices', 'amount': '5 g', 'dot': const Color(0xFFEC4899)},
        ];

    final steps = (meal['steps'] as List?)?.cast<String>() ??
        [
          'Nấu gạo lứt theo hướng dẫn trên bao bì.',
          'Ướp cá hồi với muối và tiêu.',
          'Áp chảo cá hồi mặt da xuống đến khi giòn.',
          'Xếp cơm, cá hồi và rau vào tô.',
        ];

    final tips = (meal['tips'] as List?)?.cast<String>() ??
        [
          'Áp mặt da trước sẽ giúp da giòn tự nhiên.',
        ];

    return Scaffold(
      backgroundColor: const Color(0xFFDDF0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _HeaderSection(
                imageUrl: meal['image']?.toString() ??
                    'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
                title: meal['name']?.toString() ?? 'Cơm cá hồi sốt Teriyaki',
                prepTime: meal['time']?.toString() ?? '25 phút chuẩn bị',
                tags: tags,
                onBack: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  children: [
                    _NutritionRow(
                      calories: meal['cal']?.toString() ?? '490',
                      protein: meal['protein']?.toString() ?? '38',
                      carbs: meal['carb']?.toString() ?? '50',
                      fat: meal['fat']?.toString() ?? '14',
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(mealCompletedProvider.notifier).state = !isCompleted;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted
                              ? const Color(0xFFD4ECFF)
                              : const Color(0xFF0D86CF),
                          foregroundColor: isCompleted
                              ? const Color(0xFF0D86CF)
                              : Colors.white,
                          elevation: 0,
                          side: isCompleted
                              ? const BorderSide(color: Color(0xFF0D86CF), width: 2)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: 24,
                          color: isCompleted ? const Color(0xFF0D86CF) : Colors.white,
                        ),
                        label: Text(
                          isCompleted
                              ? 'Hoàn thành món! +10 điểm'
                              : 'Đánh dấu đã ăn (+10 điểm)',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
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
                            onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                          ),
                          _TabButton(
                            label: 'Các bước',
                            icon: Icons.restaurant_menu_outlined,
                            selected: selectedTab == 1,
                            onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                          ),
                          _TabButton(
                            label: 'Mẹo',
                            icon: Icons.lightbulb_outline,
                            selected: selectedTab == 2,
                            onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (selectedTab == 0)
                      ...ingredients.map(
                            (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _IngredientTile(
                            name: item['name'].toString(),
                            type: item['type'].toString(),
                            amount: item['amount'].toString(),
                            dotColor: item['dot'] as Color,
                          ),
                        ),
                      ),
                    if (selectedTab == 1)
                      ...List.generate(
                        steps.length,
                            (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StepTile(index: i + 1, text: steps[i]),
                        ),
                      ),
                    if (selectedTab == 2)
                      ...tips.map(
                            (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TipTile(text: tip),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String prepTime;
  final List<String> tags;
  final VoidCallback onBack;

  const _HeaderSection({
    required this.imageUrl,
    required this.title,
    required this.prepTime,
    required this.tags,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(imageUrl, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0xB3000000), Color(0x22000000)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _CircleGlassButton(icon: Icons.arrow_back, onTap: onBack),
                    const Spacer(),
                  ],
                ),
                const Spacer(),
                Row(
                  children: tags
                      .map(
                        (t) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        prepTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  const _NutritionRow({
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
        const SizedBox(width: 10),
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
        const SizedBox(width: 10),
        Expanded(
          child: _NutritionCard(
            icon: '⚡',
            value: carbs,
            unit: 'g',
            label: 'Tinh bột',
            valueColor: const Color(0xFFF59E0B),
            bg: const Color(0xFFE7F1F3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NutritionCard(
            icon: '🫒',
            value: fat,
            unit: 'g',
            label: 'Chất béo',
            valueColor: const Color(0xFFEF4444),
            bg: const Color(0xFFE7E6F5),
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
      height: 120,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? const Color(0xFF0D86CF) : const Color(0xFF334155),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFF0D86CF) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final String name;
  final String type;
  final String amount;
  final Color dotColor;

  const _IngredientTile({
    required this.name,
    required this.type,
    required this.amount,
    required this.dotColor,
  });

  String _typeLabelVi(String t) {
    switch (t.toLowerCase()) {
      case 'protein':
        return 'Đạm';
      case 'grains':
        return 'Ngũ cốc';
      case 'vegetables':
        return 'Rau củ';
      case 'spices':
        return 'Gia vị';
      case 'fats':
        return 'Chất béo';
      default:
        return t;
    }
  }

  Color _typeBg(String t) {
    switch (t.toLowerCase()) {
      case 'protein':
        return const Color(0xFFE4ECFF);
      case 'grains':
        return const Color(0xFFFFEFD8);
      case 'vegetables':
        return const Color(0xFFDCFCE7);
      case 'spices':
        return const Color(0xFFFCE7F3);
      case 'fats':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  Color _typeText(String t) {
    switch (t.toLowerCase()) {
      case 'protein':
        return const Color(0xFF3B82F6);
      case 'grains':
        return const Color(0xFFF59E0B);
      case 'vegetables':
        return const Color(0xFF22C55E);
      case 'spices':
        return const Color(0xFFEC4899);
      case 'fats':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF475569);
    }
  }

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
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _typeBg(type),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _typeLabelVi(type),
              style: TextStyle(
                color: _typeText(type),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  final String text;

  const _StepTile({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0D86CF),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
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
            child: Text(
              text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipTile extends StatelessWidget {
  final String text;

  const _TipTile({required this.text});

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
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}