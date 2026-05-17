// lib/features/profile/widgets/profile_header_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileHeaderWidget extends ConsumerWidget {
  const ProfileHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final vm    = ref.read(profileViewModelProvider.notifier);
    final user  = state.user;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hàng avatar + tên ──────────────────────────────────────────
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _pickAndUploadAvatar(context, vm),
                child: Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: ClipOval(
                        child: state.isUploadingAvatar
                            ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        )
                            : user?.avatarUrl != null &&
                            user!.avatarUrl!.isNotEmpty
                            ? Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _defaultAvatar(),
                        )
                            : _defaultAvatar(),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Tên + edit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.name ?? '...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => _showEditNameDialog(
                          context, vm, user?.name ?? ''),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit name',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_rounded,
                              size: 13,
                              color: Colors.white.withOpacity(0.65)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Hàng tag danh hiệu ─────────────────────────────────────────
          const SizedBox(height: 14),
          _TagRow(activeTagName: user?.activeTagName),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => const Icon(
    Icons.person_rounded,
    color: Colors.white,
    size: 36,
  );

  Future<void> _pickAndUploadAvatar(
      BuildContext context, ProfileViewModel vm) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;
    await vm.uploadAvatar(File(picked.path));
  }

  void _showEditNameDialog(
      BuildContext context, ProfileViewModel vm, String currentName) {
    final ctrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sửa tên',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên của bạn',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await vm.updateName(ctrl.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

// ── Widget hiển thị tag — tách riêng để dễ maintain ──────────────────────────
class _TagRow extends StatelessWidget {
  final String? activeTagName;

  const _TagRow({this.activeTagName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.sell_outlined,
            size: 14, color: Colors.white.withOpacity(0.55)),
        const SizedBox(width: 8),
        activeTagName != null && activeTagName!.isNotEmpty
        // Có tag → pill nổi bật màu trắng mờ + dot secondary
            ? Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.35), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dot màu secondary làm điểm nhấn
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                activeTagName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        )
        // Chưa có tag → pill viền đứt nét, mờ, gợi ý trang bị
            : Container(
          padding: const EdgeInsets.fromLTRB(7, 5, 11, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 0.5,
              // Dart không có borderStyle dashed trực tiếp;
              // dùng opacity thấp để gợi ý trạng thái trống
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded,
                  size: 13, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(
                'Chưa trang bị danh hiệu',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}