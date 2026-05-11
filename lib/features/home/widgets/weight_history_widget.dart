// lib/features/home/widgets/weight_history_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/bmi_viewmodel.dart';

class WeightHistoryWidget extends StatelessWidget {
  final List<WeightRecord> history;
  const WeightHistoryWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Lịch sử cân nặng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Empty state
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có lịch sử.\nCập nhật cân nặng để bắt đầu theo dõi!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ),
            )
          else
          // Hiện danh sách từ mới → cũ
            ...List.generate(history.length, (i) {
              // Đảo ngược: mới nhất trên cùng
              final idx    = history.length - 1 - i;
              final record = history[idx];

              // Thay đổi so với lần trước
              double? delta;
              if (idx > 0) {
                delta = record.weightKg - history[idx - 1].weightKg;
              }

              final isFirst = idx == 0;
              final dateStr = DateFormat('dd/MM/yyyy').format(record.date);

              return _HistoryRow(
                date:     dateStr,
                weight:   record.weightKg,
                delta:    delta,
                isFirst:  isFirst,
              );
            }),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String  date;
  final double  weight;
  final double? delta;    // null = lần đầu tiên
  final bool    isFirst;

  const _HistoryRow({
    required this.date,
    required this.weight,
    required this.delta,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Ngày
          Text(
            date,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const Spacer(),

          // Cân nặng
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 10),

          // Thay đổi (delta)
          SizedBox(
            width: 70,
            child: isFirst
            // Lần đầu → badge "Bắt đầu"
                ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Bắt đầu',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            )
                : delta == null
                ? const SizedBox()
                : Row(
              children: [
                Icon(
                  delta! > 0
                      ? Icons.trending_up_rounded
                      : delta! < 0
                      ? Icons.trending_down_rounded
                      : Icons.remove_rounded,
                  size: 14,
                  color: delta! > 0
                      ? const Color(0xFFEA580C)
                      : delta! < 0
                      ? const Color(0xFF16A34A)
                      : Colors.black38,
                ),
                const SizedBox(width: 2),
                Text(
                  '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: delta! > 0
                        ? const Color(0xFFEA580C)
                        : delta! < 0
                        ? const Color(0xFF16A34A)
                        : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}