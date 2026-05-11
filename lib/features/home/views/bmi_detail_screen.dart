// lib/features/home/views/bmi_detail_screen.dart
//
// Màn hình quản lý cân nặng gồm 4 widget:
//   1. WeightProgressWidget   - tiến trình thay đổi cân nặng
//   2. WeightChartWidget      - biểu đồ cân nặng theo thời gian
//   3. UpdateWeightWidget     - form cập nhật cân nặng + chiều cao
//   4. WeightHistoryWidget    - lịch sử các lần đo

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bmi_viewmodel.dart';
import '../widgets/weight_progress_widget.dart';
import '../widgets/weight_chart_widget.dart';
import '../widgets/update_weight_widget.dart';
import '../widgets/weight_history_widget.dart';

class BmiDetailScreen extends ConsumerWidget {
  const BmiDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bmiViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.text),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý cân nặng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            Text(
              'Theo dõi & cập nhật chỉ số cơ thể',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: state.status == BmiStatus.loading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                children: [
                  // 1. Tiến trình cân nặng
                  WeightProgressWidget(state: state),
                  const SizedBox(height: 16),

                  // 2. Biểu đồ cân nặng
                  WeightChartWidget(history: state.history),
                  const SizedBox(height: 16),

                  // 3. Cập nhật thông tin
                  UpdateWeightWidget(state: state),
                  const SizedBox(height: 16),

                  // 4. Lịch sử cân nặng
                  WeightHistoryWidget(history: state.history),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}