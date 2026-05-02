import 'package:flutter/material.dart';

// Đường dẫn đã được sửa lại thêm /constants/
import '../../../core/constants/app_colors.dart';

class CookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> meal;

  const CookingDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMealInfo(),
                  const SizedBox(height: 24),
                  const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildIngredientsList(),
                  const SizedBox(height: 24),
                  const Text('Instructions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildInstructions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: AppColors.surface,
          child: Icon(Icons.arrow_back, color: AppColors.text),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          'https://via.placeholder.com/400x300',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMealInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              meal['type'],
              style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(meal['time'], style: const TextStyle(color: Colors.grey)),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(
          meal['name'],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: AppColors.primary, size: 20),
            const SizedBox(width: 4),
            Text('${meal['cal']} kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(width: 16),
            Text(meal['macros'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientsList() {
    final ingredients = ['1/2 cup Oatmeal', '1/4 cup Mixed Berries', '1 tbsp Honey', '1/2 cup Almond Milk'];
    return Column(
      children: ingredients.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(item, style: const TextStyle(fontSize: 16)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildInstructions() {
    return const Text(
      '1. Boil almond milk in a pot.\n'
          '2. Add oatmeal and cook for 5 minutes.\n'
          '3. Top with fresh mixed berries and drizzle with honey.\n'
          '4. Serve warm and enjoy your healthy meal!',
      style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
    );
  }
}