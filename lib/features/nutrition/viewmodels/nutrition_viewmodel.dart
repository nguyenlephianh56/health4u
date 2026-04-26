import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/recipe_model.dart'; // Import Model từ tầng data

// 1. Logic chọn ngày
final selectedDayIndexProvider = StateProvider<int>((ref) => 0);
// 2. Logic trạng thái hoàn thành món ăn
final isMealEatenProvider = StateProvider<bool>((ref) => false);
// 3. Logic cung cấp danh sách món ăn (Mô phỏng dữ liệu 4 bữa/ngày)
final dailyMealsProvider = Provider<List<RecipeModel>>((ref) {
  return [
    RecipeModel(
        title: "Bánh kếp ngũ cốc nguyên cám",
        mealType: "BỮA SÁNG",
        calories: "350",
        prepTime: "20p",
        imageUrl: "https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=500&q=80"
    ),
    RecipeModel(
        title: "Thịt gà xào rau củ kiểu Á",
        mealType: "BỮA TRƯA",
        calories: "420",
        prepTime: "25p",
        imageUrl: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500&q=80"
    ),
    RecipeModel(
        title: "Các loại hạt tổng hợp",
        mealType: "BỮA PHỤ",
        calories: "190",
        prepTime: "0p",
        imageUrl: "https://images.unsplash.com/photo-1536591375315-186b5186b432?w=500&q=80"
    ),
    RecipeModel(
        title: "Salad bò và rau củ",
        mealType: "BỮA TỐI",
        calories: "420",
        prepTime: "25p",
        imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&q=80"
    ),
  ];
});
// 4. Logic tính tổng Calo trong ngày (Dựa vào list món ăn)
final dailyNutritionStatsProvider = Provider<Map<String, String>>((ref) {
  // Giả lập logic tính toán từ ViewModel
  return {
    "protein": "91g",
    "carbs": "136g",
    "fat": "50g",
    "totalKcal": "1380",
  };
});