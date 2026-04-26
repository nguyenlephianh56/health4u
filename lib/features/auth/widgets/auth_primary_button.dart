// lib/features/auth/widgets/auth_primary_button.dart
//
// Mô tả: Nút bấm chính (Đăng nhập / Tạo tài khoản) dùng chung
// cho toàn bộ màn hình Auth. Tự động hiện loading spinner
// khi isLoading = true.
//
// Cách dùng:
//   AuthPrimaryButton(
//     label: 'Đăng nhập',
//     isLoading: state.status == AuthStatus.loading,
//     onPressed: _handleLogin,
//   )

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        // Khi isLoading = true, onPressed = null → nút tự disable
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
        // Hiện spinner khi đang xử lý
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
        // Hiện text khi bình thường
            : Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}