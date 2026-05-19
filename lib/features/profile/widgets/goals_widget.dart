// lib/features/profile/widgets/goals_widget.dart
//
// Widget mục tiêu: goal, activity_level, calo, dinh dưỡng, nước
// Bấm vào "Mục tiêu" hoặc "Hoạt động" → bottom sheet để thay đổi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/profile_state.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../../data/models/user_model.dart';

// ─── Dữ liệu tĩnh (đồng bộ với info_setup_screen.dart) ──────────────────────

class _ActivityOption {
  final String emoji;
  final String value;
  final String subtitle;
  const _ActivityOption(this.emoji, this.value, this.subtitle);
}

class _GoalOption {
  final String emoji;
  final String value;
  final String subtitle;
  const _GoalOption(this.emoji, this.value, this.subtitle);
}

const _activityOptions = [
  _ActivityOption('🛋️', 'Ít vận động',   'Hầu như không tập, công việc văn phòng'),
  _ActivityOption('🚶', 'Vận động vừa',  '3–5 buổi/tuần, đi bộ hoặc đạp xe'),
  _ActivityOption('🏃', 'Vận động mạnh', '6–7 buổi/tuần, tập gym hoặc thể thao'),
];

const _goalOptions = [
  _GoalOption('📈', 'Tăng cân', 'Tăng cơ, cải thiện thể hình'),
  _GoalOption('⚖️', 'Giữ cân',  'Duy trì cân nặng hiện tại'),
  _GoalOption('📉', 'Giảm cân', 'Đốt mỡ, giảm cân lành mạnh'),
];

String _activityEmoji(String value) {
  return _activityOptions
      .firstWhere((o) => o.value == value,
      orElse: () => const _ActivityOption('🏃', '', ''))
      .emoji;
}


// ─── GoalsWidget (ConsumerWidget để gọi ViewModel) ───────────────────────────

class GoalsWidget extends ConsumerWidget {
  final UserModel user;
  final DailyTrackingData tracking;

  const GoalsWidget({
    super.key,
    required this.user,
    required this.tracking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      title: 'Mục tiêu',
      child: Column(
        children: [
          // ── Mục tiêu (có thể chỉnh) ──────────────────────────────────────
          _GoalRow(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF0284C7),
            label: 'Mục tiêu',
            value: user.goalLabel,
            tappable: true,
            onTap: () => _showGoalSheet(context, ref, user.goal ?? ''),
          ),
          _divider(),

          // ── Hoạt động (có thể chỉnh) ─────────────────────────────────────
          _GoalRow(
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF7C3AED),
            label: 'Hoạt động',
            value: '${_activityEmoji(user.activityLevel ?? '')} ${user.activityLevel ?? '—'}',
            tappable: true,
            onTap: () => _showActivitySheet(context, ref, user.activityLevel ?? ''),
          ),
          _divider(),

          // ── Calo ─────────────────────────────────────────────────────────
          _GoalRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFEA580C),
            label: 'Calo',
            value: '${tracking.consumedKcal.toInt()} / '
                '${tracking.targetKcal.toInt()} kcal',
          ),
          _divider(),

          // ── Dinh dưỡng ───────────────────────────────────────────────────
          _GoalRow(
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFF16A34A),
            label: 'Dinh dưỡng',
            value: '${tracking.protein.toInt()}g / '
                '${tracking.carbs.toInt()}g / '
                '${tracking.fat.toInt()}g',
            subtitle: 'Protein / Carbs / Fat',
          ),
          _divider(),

          // ── Nước ─────────────────────────────────────────────────────────
          _GoalRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Nước',
            value: '${tracking.targetWaterMl} ml / ngày',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 0.5,
    color: Colors.black.withOpacity(0.07),
  );

  // ── Bottom sheet: chọn Mục tiêu ──────────────────────────────────────────
  void _showGoalSheet(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectionSheet(
        title: 'Chọn mục tiêu',
        subtitle: 'Hệ thống sẽ cá nhân hóa theo mục tiêu này',
        options: _goalOptions
            .map((o) => _SheetOption(o.emoji, o.value, o.subtitle))
            .toList(),
        current: current,
        onSelected: (val) {
          ref.read(profileViewModelProvider.notifier).updateGoal(val);
        },
      ),
    );
  }

  // ── Bottom sheet: chọn Mức độ hoạt động ─────────────────────────────────
  void _showActivitySheet(
      BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectionSheet(
        title: 'Mức độ vận động',
        subtitle: 'Mô tả thói quen tập luyện hằng ngày',
        options: _activityOptions
            .map((o) => _SheetOption(o.emoji, o.value, o.subtitle))
            .toList(),
        current: current,
        onSelected: (val) {
          ref
              .read(profileViewModelProvider.notifier)
              .updateActivityLevel(val);
        },
      ),
    );
  }
}

// ─── Bottom sheet dùng chung ─────────────────────────────────────────────────

class _SheetOption {
  final String emoji;
  final String value;
  final String subtitle;
  const _SheetOption(this.emoji, this.value, this.subtitle);
}

class _SelectionSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<_SheetOption> options;
  final String current;
  final ValueChanged<String> onSelected;

  const _SelectionSheet({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.current,
    required this.onSelected,
  });

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 20),

          // Option cards
          ...widget.options.map((opt) {
            final isSelected = _selected == opt.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selected = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.07)
                        : Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 1.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Emoji
                      Text(opt.emoji,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.value,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Check icon
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Nút lưu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelected(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Lưu thay đổi',
                style:
                TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget 1 dòng mục tiêu ────────────────────────────────────────────────────
class _GoalRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final bool tappable;
  final VoidCallback? onTap;

  const _GoalRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.tappable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tappable ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Value + chevron
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  tappable
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: tappable
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card dùng chung ───────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}