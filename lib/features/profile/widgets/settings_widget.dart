// lib/features/profile/widgets/settings_widget.dart
//
// Widget Tùy chỉnh:
//   - Nhắc nhở → mở ReminderDialog
//   - Đăng xuất → gọi vm.signOut()
//
// Package cần thêm vào pubspec.yaml:
//   flutter_local_notifications: ^18.0.0
//   timezone: ^0.9.4
// (Dùng để gửi notification đúng giờ đã set trong ReminderDialog)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'reminder_dialog.dart';

class SettingsWidget extends ConsumerWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(profileViewModelProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const Text(
            'Tùy chỉnh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),

          // ── Nhắc nhở ─────────────────────────────────────────────────
          _SettingRow(
            icon: Icons.notifications_none_rounded,
            iconColor: AppColors.primary,
            label: 'Nhắc nhở',
            onTap: () => _openReminderDialog(context),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 20,
            ),
          ),

          Divider(height: 1, color: Colors.black.withOpacity(0.07)),

          // ── Đăng xuất ────────────────────────────────────────────────
          _SettingRow(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFE53935),
            label: 'Đăng xuất',
            labelColor: const Color(0xFFE53935),
            onTap: () => _confirmSignOut(context, vm),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _openReminderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReminderDialog(),
    );
  }

  void _confirmSignOut(BuildContext context, ProfileViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đăng xuất?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await vm.signOut();
              // AuthRepo tự emit unauthenticated → GoRouter về /login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

// ── Widget 1 dòng setting ─────────────────────────────────────────────────────
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final Color    labelColor;
  final VoidCallback onTap;
  final Widget   trailing;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor = AppColors.text,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),

            trailing,
          ],
        ),
      ),
    );
  }
}