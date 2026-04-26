// lib/features/auth/widgets/auth_error_banner.dart
//
// Mô tả: Banner hiển thị thông báo lỗi (màu đỏ nhạt) phía trên nút bấm.
// Chỉ hiện khi có lỗi từ Firebase, tự ẩn khi không có lỗi.
//
// Cách dùng:
//   if (state.errorMessage != null)
//     AuthErrorBanner(message: state.errorMessage!)

import 'package:flutter/material.dart';

class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE53935),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}