// lib/features/profile/widgets/reminder_dialog.dart
//
// Popup cài đặt nhắc nhở bữa ăn + uống nước.
// Lưu vào Firestore collection "reminders".
//
// Flutter local notifications:
//   Package: flutter_local_notifications (thêm vào pubspec.yaml)
//   Dùng để hiện notification đúng giờ đã set.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/notification_service.dart';

class ReminderDialog extends StatefulWidget {
  const ReminderDialog({super.key});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Meal reminders state ──────────────────────────────────────────────────
  bool _mealEnabled = true;
  TimeOfDay _breakfast = const TimeOfDay(hour: 7,  minute: 0);
  TimeOfDay _lunch     = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _dinner    = const TimeOfDay(hour: 18, minute: 30);
  TimeOfDay _snack     = const TimeOfDay(hour: 21, minute: 0);

  // ── Water reminders state ─────────────────────────────────────────────────
  bool _waterEnabled = true;
  List<TimeOfDay> _waterTimes = [
    const TimeOfDay(hour: 8, minute: 0),
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // ── Load reminders từ Firestore ───────────────────────────────────────────
  Future<void> _loadReminders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _db
        .collection('reminders')
        .where('user_id', isEqualTo: uid)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final type = data['type'] as String?;
      final timeStr = data['reminder_time'] as String? ?? '00:00';
      final parts = timeStr.split(':');
      final time = TimeOfDay(
        hour:   int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
      final isActive = data['is_active'] as bool? ?? true;

      if (mounted) {
        setState(() {
          switch (type) {
            case 'Meal_Breakfast':
              _mealEnabled = isActive;
              _breakfast   = time;
              break;
            case 'Meal_Lunch':
              _lunch = time;
              break;
            case 'Meal_Dinner':
              _dinner = time;
              break;
            case 'Meal_Snack':
              _snack = time;
              break;
            case 'Water':
              _waterEnabled = isActive;
              // Thêm vào list nếu chưa có
              if (_waterTimes.isEmpty) {
                _waterTimes = [time];
              }
              break;
          }
        });
      }
    }
  }

  // ── Lưu reminders lên Firestore ───────────────────────────────────────────
  Future<void> _saveReminders() async {
    setState(() => _isSaving = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Xóa reminders cũ của user này
      final oldSnap = await _db
          .collection('reminders')
          .where('user_id', isEqualTo: uid)
          .get();
      final batch = _db.batch();
      for (final doc in oldSnap.docs) {
        batch.delete(doc.reference);
      }

      // Tạo mới meal reminders
      final mealItems = [
        {'type': 'Meal_Breakfast', 'time': _breakfast, 'msg': 'Đến giờ ăn sáng rồi! 🌅'},
        {'type': 'Meal_Lunch',     'time': _lunch,     'msg': 'Đến giờ ăn trưa rồi! ☀️'},
        {'type': 'Meal_Dinner',    'time': _dinner,    'msg': 'Đến giờ ăn tối rồi! 🌙'},
        {'type': 'Meal_Snack',     'time': _snack,     'msg': 'Đến giờ ăn xế rồi! 🍎'},
      ];
      for (final item in mealItems) {
        final t = item['time'] as TimeOfDay;
        batch.set(_db.collection('reminders').doc(), {
          'user_id':       uid,
          'type':          item['type'],
          'reminder_time': '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          'message':       item['msg'],
          'repeat_days':   ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          'is_active':     _mealEnabled,
        });
      }

      // Tạo mới water reminders
      for (final t in _waterTimes) {
        batch.set(_db.collection('reminders').doc(), {
          'user_id':       uid,
          'type':          'Water',
          'reminder_time': '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          'message':       'Uống nước đi nào! 💧',
          'repeat_days':   ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          'is_active':     _waterEnabled,
        });
      }

      await batch.commit();

      await NotificationService().syncRemindersFromFirestore(uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã lưu cài đặt nhắc nhở'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Chọn giờ ─────────────────────────────────────────────────────────────
  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nhắc nhở bữa ăn ─────────────────────────────────
                    _buildSectionTitle(
                      'Nhắc nhở bữa ăn',
                      subtitle: 'Nhắc nhở ghi lại bữa ăn hàng ngày',
                      value: _mealEnabled,
                      onToggle: (v) => setState(() => _mealEnabled = v),
                    ),
                    if (_mealEnabled) ...[
                      _buildTimeRow('Bữa sáng', _breakfast,
                              () async {
                            final t = await _pickTime(_breakfast);
                            if (t != null) setState(() => _breakfast = t);
                          }),
                      _buildTimeRow('Bữa trưa', _lunch,
                              () async {
                            final t = await _pickTime(_lunch);
                            if (t != null) setState(() => _lunch = t);
                          }),
                      _buildTimeRow('Bữa tối', _dinner,
                              () async {
                            final t = await _pickTime(_dinner);
                            if (t != null) setState(() => _dinner = t);
                          }),
                      _buildTimeRow('Bữa phụ', _snack,
                              () async {
                            final t = await _pickTime(_snack);
                            if (t != null) setState(() => _snack = t);
                          }),
                    ],

                    const SizedBox(height: 8),
                    Divider(color: Colors.black.withOpacity(0.08)),
                    const SizedBox(height: 8),

                    // ── Nhắc nhở uống nước ───────────────────────────────
                    _buildSectionTitle(
                      'Nhắc nhở uống nước',
                      subtitle: 'Giữ nước trong cơ thể suốt ngày',
                      value: _waterEnabled,
                      onToggle: (v) => setState(() => _waterEnabled = v),
                    ),
                    if (_waterEnabled) ...[
                      ...List.generate(_waterTimes.length, (i) {
                        return _buildTimeRow(
                          'Lần ${i + 1}',
                          _waterTimes[i],
                              () async {
                            final t = await _pickTime(_waterTimes[i]);
                            if (t != null) {
                              setState(() => _waterTimes[i] = t);
                            }
                          },
                          onRemove: _waterTimes.length > 1
                              ? () => setState(() => _waterTimes.removeAt(i))
                              : null,
                        );
                      }),

                      // Nút thêm giờ uống nước
                      GestureDetector(
                        onTap: () {
                          setState(() => _waterTimes
                              .add(const TimeOfDay(hour: 8, minute: 0)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Thêm nhắc nhở uống nước',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Nút lưu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveReminders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text(
                          'Lưu cài đặt',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Text(
            '🔔  Cài đặt nhắc nhở',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, {
        required String subtitle,
        required bool value,
        required void Function(bool) onToggle,
      }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onToggle,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
      String label,
      TimeOfDay time,
      VoidCallback onTap, {
        VoidCallback? onRemove,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}