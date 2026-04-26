// lib/features/auth/widgets/number_input_field.dart
//
// Mô tả: TextField chuyên dùng để nhập số (chiều cao, cân nặng).
// Hiển thị đơn vị (cm / kg) ở bên phải, chỉ cho nhập số thực.
//
// Cách dùng:
//   NumberInputField(
//     controller: _heightController,
//     label: 'Chiều cao',
//     unit: 'cm',
//     hint: '170',
//     prefixIcon: Icons.height_rounded,
//     min: 50, max: 250,
//   )

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class NumberInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;       // "cm" hoặc "kg"
  final String hint;
  final IconData prefixIcon;
  final double min;
  final double max;
  final String? Function(String?)? validator;

  const NumberInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.unit,
    required this.hint,
    required this.prefixIcon,
    required this.min,
    required this.max,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),

        // Input
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Chỉ cho phép nhập số và dấu chấm thập phân
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
          ],
          validator: validator ??
                  (val) {
                if (val == null || val.isEmpty) return 'Vui lòng nhập $label';
                final num = double.tryParse(val);
                if (num == null) return 'Giá trị không hợp lệ';
                if (num < min || num > max) {
                  return '$label phải từ $min đến $max';
                }
                return null;
              },
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.3),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 22),
            // Đơn vị hiển thị bên phải
            suffixIcon: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unit,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}