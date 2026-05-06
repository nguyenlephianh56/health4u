// lib/features/auth/widgets/auth_text_field.dart
//
// Mô tả: Widget TextField tùy chỉnh dùng chung cho toàn bộ màn hình Auth.
// Tái sử dụng ở LoginScreen, RegisterScreen, InfoSetupScreen.
//
// Cách dùng:
//   AuthTextField(
//     controller: _emailController,
//     label: 'Gmail',
//     hint: 'example@gmail.com',
//     prefixIcon: Icons.mail_outline_rounded,
//   )

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;           // true → hiển thị dấu chấm (password)
  final Widget? suffixIcon;         // dùng để truyền icon con mắt vào
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label phía trên input
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),

        // Input field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enableIMEPersonalizedLearning: true,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.3),
              fontSize: 15,
            ),
            // Icon bên trái
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.primary,
              size: 22,
            ),
            // Icon bên phải (con mắt nếu là password)
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            // Border mặc định
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            // Border khi không focus
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            // Border khi đang focus → viền xanh
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            // Border khi có lỗi validate
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            // Border khi đang focus + có lỗi
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}