// lib/data/models/recipe_model.dart
//
// Mô tả: Data class ánh xạ document từ Firestore collection "recipes".
// Dùng ở: AdminViewModel, NutritionViewModel, MealPlanScreen.

enum IngredientCategory {
  meat,       // 🥩 Thịt & Hải sản
  vegetable,  // 🥦 Rau & Củ quả
  dairy,      // 🥛 Sữa & Trứng
  grain,      // 🌾 Ngũ cốc & Tinh bột
  seasoning,  // 🧂 Gia vị & Dầu ăn
  other,      // 📦 Khác
}

extension IngredientCategoryX on IngredientCategory {
  String get label {
    switch (this) {
      case IngredientCategory.meat:      return '🥩 Thịt & Hải sản';
      case IngredientCategory.vegetable: return '🥦 Rau & Củ quả';
      case IngredientCategory.dairy:     return '🥛 Sữa & Trứng';
      case IngredientCategory.grain:     return '🌾 Ngũ cốc & Tinh bột';
      case IngredientCategory.seasoning: return '🧂 Gia vị & Dầu ăn';
      case IngredientCategory.other:     return '📦 Khác';
    }
  }

  // Lưu vào Firestore dạng String
  String get value {
    switch (this) {
      case IngredientCategory.meat:      return 'meat';
      case IngredientCategory.vegetable: return 'vegetable';
      case IngredientCategory.dairy:     return 'dairy';
      case IngredientCategory.grain:     return 'grain';
      case IngredientCategory.seasoning: return 'seasoning';
      case IngredientCategory.other:     return 'other';
    }
  }

  // Đọc từ Firestore String → enum
  static IngredientCategory fromValue(String? value) {
    switch (value) {
      case 'meat':      return IngredientCategory.meat;
      case 'vegetable': return IngredientCategory.vegetable;
      case 'dairy':     return IngredientCategory.dairy;
      case 'grain':     return IngredientCategory.grain;
      case 'seasoning': return IngredientCategory.seasoning;
      default:          return IngredientCategory.other;
    }
  }
}

class IngredientItem {
  final String id;
  final String name;
  final double amount;
  final String unit;
  // ✅ Thêm field category để phân nhóm trong Grocery List
  final IngredientCategory category;

  const IngredientItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    this.category = IngredientCategory.other, // mặc định "Khác"
  });

  // Firestore → Model
  factory IngredientItem.fromMap(Map<String, dynamic> map) {
    return IngredientItem(
      id:       map['id']?.toString() ?? '',
      name:     map['name']?.toString() ?? '',
      amount:   (map['amount'] as num?)?.toDouble() ?? 0,
      unit:     map['unit']?.toString() ?? '',
      category: IngredientCategoryX.fromValue(map['category']?.toString()),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toMap() => {
    'id':       id,
    'name':     name,
    'amount':   amount,
    'unit':     unit,
    'category': category.value, // lưu string vào Firestore
  };
}

class RecipeNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const RecipeNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory RecipeNutrition.fromMap(Map<String, dynamic> map) {
    return RecipeNutrition(
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein:  (map['protein']  as num?)?.toDouble() ?? 0,
      carbs:    (map['carbs']    as num?)?.toDouble() ?? 0,
      fat:      (map['fat']      as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'calories': calories,
    'protein':  protein,
    'carbs':    carbs,
    'fat':      fat,
  };
}

class RecipeFlags {
  final bool isVegan;
  final bool isVegetarian;

  const RecipeFlags({
    required this.isVegan,
    required this.isVegetarian,
  });

  factory RecipeFlags.fromMap(Map<String, dynamic> map) {
    return RecipeFlags(
      isVegan:       (map['is_vegan']       as bool?) ?? false,
      isVegetarian:  (map['is_vegetarian']  as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'is_vegan':      isVegan,
    'is_vegetarian': isVegetarian,
  };
}

class RecipeModel {
  final String id;           // Firestore document ID (auto-generated)
  final String name;
  final String mealType;     // "Breakfast" | "Lunch" | "Dinner" | "Snack"
  final RecipeNutrition nutrition;
  final int prepTimeMin;
  final List<String> instructions; // Mỗi phần tử = 1 bước
  final RecipeFlags flags;
  final List<IngredientItem> ingredients;
  final String imageUrl;

  const RecipeModel({
    required this.id,
    required this.name,
    required this.mealType,
    required this.nutrition,
    required this.prepTimeMin,
    required this.instructions,
    required this.flags,
    required this.ingredients,
    required this.imageUrl,
  });

  // Firestore document → RecipeModel
  factory RecipeModel.fromFirestore(String docId, Map<String, dynamic> data) {
    // instructions lưu là List<String> trong Firestore
    final rawInstructions = data['instructions'];
    List<String> instructionList = [];
    if (rawInstructions is List) {
      instructionList = rawInstructions.map((e) => e.toString()).toList();
    } else if (rawInstructions is String) {
      // Fallback nếu dữ liệu cũ lưu dạng String
      instructionList = [rawInstructions];
    }

    return RecipeModel(
      id:           docId,
      name:         data['name']?.toString() ?? '',
      mealType:     data['meal_type']?.toString() ?? 'Breakfast',
      nutrition:    RecipeNutrition.fromMap(
          (data['nutrition'] as Map<String, dynamic>?) ?? {}),
      prepTimeMin:  (data['prep_time_min'] as num?)?.toInt() ?? 0,
      instructions: instructionList,
      flags:        RecipeFlags.fromMap(
          (data['flags'] as Map<String, dynamic>?) ?? {}),
      ingredients:  ((data['ingredients'] as List?) ?? [])
          .map((e) => IngredientItem.fromMap(
          Map<String, dynamic>.from(e)))
          .toList(),
      imageUrl:     data['image_url']?.toString() ?? '',
    );
  }

  // RecipeModel → Firestore document
  Map<String, dynamic> toFirestore() => {
    'name':          name,
    'meal_type':     mealType,
    'nutrition':     nutrition.toMap(),
    'prep_time_min': prepTimeMin,
    'instructions':  instructions,   // List<String>
    'flags':         flags.toMap(),
    'ingredients':   ingredients.map((e) => e.toMap()).toList(),
    'image_url':     imageUrl,
  };
}