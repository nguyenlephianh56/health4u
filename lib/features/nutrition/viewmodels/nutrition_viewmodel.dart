import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. Thêm Protein, Carbs, Fat vào State để giao diện có dữ liệu hiển thị
class NutritionState {
  final int totalKcal;
  final int protein;
  final int carbs;
  final int fat;
  final List<Map<String, dynamic>> meals;

  NutritionState({
    required this.totalKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meals,
  });

  NutritionState copyWith({
    int? totalKcal,
    int? protein,
    int? carbs,
    int? fat,
    List<Map<String, dynamic>>? meals,
  }) {
    return NutritionState(
      totalKcal: totalKcal ?? this.totalKcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      meals: meals ?? this.meals,
    );
  }
}

// 2. ViewModel xử lý logic: Nhận index ngày vào để biết lấy dữ liệu nào
class NutritionViewModel extends StateNotifier<NutritionState> {
  NutritionViewModel(int selectedIndex)
      : super(NutritionState(
    totalKcal: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    meals: [],
  )) {
    _loadDataForDay(selectedIndex);
  }

  void _loadDataForDay(int index) {
    // 3. Fake dữ liệu nhảy số dựa trên index của ngày được chọn
    // (Trong thực tế, bạn sẽ fetch từ API/Database theo ngày tại đây)
    int kcal = 1380;
    int p = 94;
    int c = 138;
    int f = 46;

    if (index == 6) { // Chủ nhật (SUN)
      kcal = 1320; p = 80; c = 144; f = 48;
    } else if (index == 3) { // Thứ năm (THU - Ngày mặc định)
      kcal = 1380; p = 99; c = 138; f = 41;
    } else { // Các ngày khác (cộng trừ 1 chút dựa vào index để thấy nhảy số)
      kcal = 1200 + (index * 50);
      p = 80 + (index * 5);
      c = 110 + (index * 8);
      f = 35 + (index * 3);
    }

    final initialMeals = [
      {
        'type': 'BREAKFAST',
        // Thêm chữ (Day X) để bạn thấy thực đơn cũng tự nhảy khi bấm lịch
        'name': 'Whole Grain Pancakes (Day ${index + 1})',
        'cal': 350,
        'time': '20m',
        'macros': 'P: 14g  C: 58g  F: 8g',
      },
      {
        'type': 'DINNER',
        'name': 'Asian Chicken Stir-Fry',
        'cal': 420,
        'time': '20m',
        'macros': 'P: 36g  C: 38g  F: 12g',
      },
      {
        'type': 'SNACK',
        'name': 'Protein Bar',
        'cal': 190,
        'time': '0m',
        'macros': 'P: 20g  C: 15g  F: 6g',
      },
      {
        'type': 'LUNCH',
        'name': 'Red Lentil Soup',
        'cal': 420,
        'time': '30m',
        'macros': 'P: 24g  C: 27g  F: 20g',
      },
    ];

    state = state.copyWith(
      totalKcal: kcal,
      protein: p,
      carbs: c,
      fat: f,
      meals: initialMeals,
    );
  }
}

// 4. Providers
// Mặc định là index=3 (cho THU) khớp ảnh
final selectedDayIndexProvider = StateProvider<int>((ref) => 3);

// SỬA QUAN TRỌNG: Lắng nghe selectedDayIndexProvider để reload ViewModel
final nutritionViewModelProvider =
StateNotifierProvider<NutritionViewModel, NutritionState>((ref) {
  // Bất cứ khi nào index thay đổi (do bạn bấm trên UI), dòng này sẽ chạy lại
  final selectedIndex = ref.watch(selectedDayIndexProvider);

  // Truyền index mới vào ViewModel để load lại số calo/thực đơn
  return NutritionViewModel(selectedIndex);
});