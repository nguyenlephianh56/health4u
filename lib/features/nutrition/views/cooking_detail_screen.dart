import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/recipe_model.dart';
import '../viewmodels/nutrition_viewmodel.dart';
import '../widgets/nutrition_label.dart';

class CookingDetailScreen extends ConsumerWidget {
  final RecipeModel recipe;
  const CookingDetailScreen({super.key, required this.recipe});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEaten = ref.watch(isMealEatenProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 3,
        child: CustomScrollView(
          slivers: [
            // Header Image & Nút Swap Dish
            SliverAppBar(
              expandedHeight: 280.0,
              pinned: true,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(recipe.imageUrl, fit: BoxFit.cover),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 16, color: Colors.black),
                            SizedBox(width: 4),
                            Text("Đổi món", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      ref.read(isMealEatenProvider.notifier).state = false;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
            // Nội dung chi tiết
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(recipe.prepTime, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Sử dụng NutritionLabel Widget
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          NutritionLabel(label: "Calories", value: recipe.calories, unit: "kcal", iconColor: Colors.cyan, icon: Icons.local_fire_department),
                          const NutritionLabel(label: "Protein", value: "14", unit: "g", iconColor: Colors.orange, icon: Icons.fitness_center),
                          const NutritionLabel(label: "Carbs", value: "58", unit: "g", iconColor: Colors.purple, icon: Icons.grass),
                          const NutritionLabel(label: "Fat", value: "8", unit: "g", iconColor: Colors.redAccent, icon: Icons.water_drop),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nút xác nhận hoàn thành
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEaten ? AppColors.background : AppColors.primary,
                          foregroundColor: isEaten ? AppColors.primary : AppColors.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => ref.read(isMealEatenProvider.notifier).state = !isEaten,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isEaten ? Icons.check_circle : Icons.check),
                            const SizedBox(width: 8),
                            Text(isEaten ? "Đã ăn xong! +10 điểm" : "Đánh dấu đã ăn (+10 điểm)", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}