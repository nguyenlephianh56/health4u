// lib/features/nutrition/viewmodels/cooking_detail_viewmodel.dart
//
// Providers cho CookingDetailScreen.
// Tách ra để View không chứa business logic / provider declarations.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Tab hiện tại: 0 = Nguyên liệu, 1 = Các bước, 2 = Mẹo
final selectedTabProvider = StateProvider<int>((ref) => 0);

// Trạng thái đã ăn của từng món (key = recipe id)
final eatenProvider = StateProvider.family<bool, String>((ref, id) => false);