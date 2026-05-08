// lib/features/admin/views/workout_tab_view.dart
//
// Tab Workouts: nút Add + danh sách + sửa + xóa

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_state.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../widgets/workout_list_item.dart';
import '../widgets/workout_form_dialog.dart';
import '../../../data/models/workout_model.dart';

class WorkoutTabView extends StatelessWidget {
  final AdminState state;
  final AdminViewModel vm;

  const WorkoutTabView({
    super.key,
    required this.state,
    required this.vm,
  });

  void _openAddDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WorkoutFormDialog(
        workout: null,
        onSave: (workout) => vm.addWorkout(workout),
      ),
    );
  }

  void _openEditDialog(BuildContext context, WorkoutModel workout) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WorkoutFormDialog(
        workout: workout,
        onSave: (updated) => vm.updateWorkout(updated),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WorkoutModel workout) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa bài tập?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc muốn xóa "${workout.title}" không?\nHành động này không thể hoàn tác.',
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Pop TRƯỚC rồi mới xóa
              await vm.deleteWorkout(workout.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nút Add New Workout
        _AddBtn(
          label: 'Add New Workout',
          onTap: () => _openAddDialog(context),
        ),
        const SizedBox(height: 16),

        // Danh sách
        if (state.workouts.isEmpty)
          const _EmptyState(
            message: 'Chưa có bài tập nào.\nBấm "Add New Workout" để thêm!',
          )
        else
          ...state.workouts.map(
                (workout) => WorkoutListItem(
              workout:  workout,
              onEdit:   () => _openEditDialog(context, workout),
              onDelete: () => _confirmDelete(context, workout),
            ),
          ),
      ],
    );
  }
}

// ── Nút Add ───────────────────────────────────────────────────────────────────
class _AddBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }
}