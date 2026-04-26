// lib/features/auth/widgets/dob_picker_field.dart
//
// Mô tả: Widget hiển thị ô chọn ngày sinh (trông như TextField nhưng
// khi bấm sẽ mở DatePicker của Flutter). Tách ra vì có logic
// riêng với showDatePicker.
//
// Cách dùng:
//   DobPickerField(
//     selectedDate: _selectedDob,
//     onDateSelected: (date) => setState(() => _selectedDob = date),
//   )

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DobPickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  const DobPickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  // Format DateTime → "DD/MM/YYYY" để hiển thị
  String _displayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // Mặc định mở ở năm 20 tuổi về trước
      initialDate: selectedDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 10), // Phải ít nhất 10 tuổi
      locale: const Locale('vi'),         // Tiếng Việt
      builder: (context, child) {
        // Theme DatePicker theo màu của app
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,     // Header & nút OK
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    // Chỉ cập nhật nếu user thực sự chọn (không bấm Cancel)
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      // AbsorbPointer ngăn child bắt event (tránh click đôi)
      child: AbsorbPointer(
        child: Container(
          width: double.infinity,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  // Hiện ngày đã chọn hoặc placeholder
                  selectedDate != null
                      ? _displayDate(selectedDate!)
                      : 'DD/MM/YYYY',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: selectedDate != null
                        ? AppColors.text
                        : Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              // Mũi tên xuống (gợi ý có thể bấm)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}