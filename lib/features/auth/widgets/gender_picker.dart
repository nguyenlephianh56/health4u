// lib/features/auth/widgets/gender_picker.dart
//
// Mô tả: Widget 3 nút toggle chọn giới tính (Nam / Nữ / Khác).
// Tách ra file riêng vì logic toggle + animation riêng biệt.
//
// Cách dùng:
//   GenderPicker(
//     selected: _selectedGender,       // giá trị hiện tại
//     onChanged: (val) => setState(() => _selectedGender = val),
//   )

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class GenderPicker extends StatelessWidget {
  final String? selected;              // Giá trị đang chọn: "Nam"/"Nữ"/"Khác"
  final void Function(String) onChanged; // Callback khi user chọn

  const GenderPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<String> _options = ['Nam', 'Nữ', 'Khác'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((gender) {
        final isSelected = selected == gender;
        final isLast = gender == _options.last;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(gender),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              // Khoảng cách bên phải (trừ item cuối)
              margin: EdgeInsets.only(right: isLast ? 0 : 10),
              height: 52,
              decoration: BoxDecoration(
                // Xanh khi chọn, trắng khi không chọn
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.black.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                // Glow nhẹ khi được chọn
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: Text(
                  gender,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}