// lib/features/nutrition/viewmodels/nutrition_viewmodel.dart
//
// State, ViewModel và Providers cho feature Nutrition.
// Tích hợp GamificationService: cộng/trừ điểm khi toggle bữa ăn.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/auth_repo.dart';
import '../../../data/models/nutrition_models.dart';
import '../../../data/services/gamification_service.dart';
import '../../gamification/viewmodels/discipline_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NutritionState {
  final bool isLoading;
  final bool isRefreshing; // load ngầm — vẫn hiện data cũ
  final String? errorMessage;
  final Map<String, DayNutrition> weekData;

  const NutritionState({
    this.isLoading = true,
    this.isRefreshing = false,
    this.errorMessage,
    this.weekData = const {},
  });

  DayNutrition dayOf(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return weekData[key] ?? DayNutrition(date: date);
  }

  NutritionState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    Map<String, DayNutrition>? weekData,
  }) =>
      NutritionState(
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        errorMessage: errorMessage,
        weekData: weekData ?? this.weekData,
      );
}