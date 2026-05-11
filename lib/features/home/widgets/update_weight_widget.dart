// lib/features/home/widgets/update_weight_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bmi_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';

class UpdateWeightWidget extends ConsumerStatefulWidget {
  final BmiState state;
  const UpdateWeightWidget({super.key, required this.state});

  @override
  ConsumerState<UpdateWeightWidget> createState() =>
      _UpdateWeightWidgetState();
}

class _UpdateWeightWidgetState extends ConsumerState<UpdateWeightWidget> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.state.currentWeight != null
          ? widget.state.currentWeight!.toStringAsFixed(1)
          : '',
    );
    _heightCtrl = TextEditingController(
      text: widget.state.heightCm != null
          ? widget.state.heightCm!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  // BMI dự kiến khi user đang nhập
  double? _previewBmi() {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w == null || h == null || h == 0) return null;
    final hm = h / 100;
    return w / (hm * hm);
  }

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);

    if (w == null || h == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhập đầy đủ cân nặng và chiều cao'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (w < 20 || w > 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cân nặng phải từ 20 đến 300 kg'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (h < 50 || h > 250) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chiều cao phải từ 50 đến 250 cm'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await ref.read(bmiViewModelProvider.notifier).saveWeightAndHeight(
      weightKg: w,
      heightCm: h,
    );

    if (mounted) {
      // ✅ Refresh HomeViewModel để BMI card trên Home đồng bộ ngay
      ref.invalidate(homeViewModelProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Đã cập nhật thành công!'),
        ]),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(bmiViewModelProvider).isSaving;
    final preview  = _previewBmi();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
          // Header
          const Row(
            children: [
              Text('✏️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'Cập nhật thông tin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2 trường nhập
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _weightCtrl,
                  label: 'Cân nặng hiện tại (kg)',
                  hint: '70',
                  unit: 'kg',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  controller: _heightCtrl,
                  label: 'Chiều cao (cm)',
                  hint: '170',
                  unit: 'cm',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // BMI dự kiến
          if (preview != null)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'BMI dự kiến',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    preview.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Nút lưu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                AppColors.primary.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'Lưu thay đổi',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TextField nhỏ ─────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  final void Function(String) onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
          ],
          enableIMEPersonalizedLearning: true,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.25), fontSize: 18),
            suffixText: unit,
            suffixStyle: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}