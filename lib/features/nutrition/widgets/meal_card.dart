import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../views/cooking_detail_screen.dart';

class MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealCard({
    super.key,
    required this.meal,
  });

  static String _translateMealType(String type) {
    switch (type.toUpperCase()) {
      case 'BREAKFAST':
        return 'BỮA SÁNG';
      case 'LUNCH':
        return 'BỮA TRƯA';
      case 'DINNER':
        return 'BỮA TỐI';
      case 'SNACK':
        return 'BỮA PHỤ';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String mealType =
    _translateMealType((meal['type'] ?? 'BREAKFAST').toString());

    final String mealName = (meal['name'] ?? '').toString();
    final String mealTime = (meal['time'] ?? '20m').toString();

    final String protein = (meal['protein'] ?? '24g').toString();
    final String carb = (meal['carb'] ?? '6g').toString();
    final String fat = (meal['fat'] ?? '18g').toString();
    final String cal = (meal['cal'] ?? 350).toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CookingDetailScreen(meal: meal),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD9EAF8),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 78,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  image: DecorationImage(
                    image: NetworkImage(
                      meal['image']?.toString() ??
                          'https://via.placeholder.com/150',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type + Time
                  Row(
                    children: [
                      Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF7E5F),
                              Color(0xFFFEB47B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFCF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          mealType,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE3A328),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),

                      const Spacer(),

                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF7E8A9A),
                        size: 13,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        mealTime,
                        style: const TextStyle(
                          color: Color(0xFF7E8A9A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Title
                  Text(
                    mealName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Macros
                  Row(
                    children: [
                      _MacroPill(
                        "P",
                        protein,
                        const Color(0xFF5B7CFF),
                        const Color(0xFFE8F0FF),
                      ),

                      const SizedBox(width: 4),

                      _MacroPill(
                        "C",
                        carb,
                        const Color(0xFFE3A328),
                        const Color(0xFFFFF0D9),
                      ),

                      const SizedBox(width: 4),

                      _MacroPill(
                        "F",
                        fat,
                        const Color(0xFFEE5A56),
                        const Color(0xFFFFE2E0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Calories
                  Row(
                    children: [
                      Text(
                        cal,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          height: 1,
                        ),
                      ),

                      const SizedBox(width: 2),

                      const Text(
                        "kcal",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color bgColor;

  const _MacroPill(
      this.label,
      this.value,
      this.textColor,
      this.bgColor,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 2.5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),

          const SizedBox(width: 2),

          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}