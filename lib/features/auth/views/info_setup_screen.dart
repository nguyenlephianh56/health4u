// lib/features/auth/views/info_setup_screen.dart
//
// Mô tả: Màn hình nhập thông tin bổ sung sau khi đăng ký.
// Thu thập: height_cm, weight_kg, activity_level, goal
// và lưu vào Firestore qua InfoSetupViewModel.
//
// Vai trò MVVM:
//   → VIEW: Chỉ lo UI + validate form + lắng nghe state
//   → KHÔNG gọi Firestore trực tiếp
//   → Gọi viewModel.saveInfo() khi user bấm "Hoàn tất"
//
// Widgets dùng (từ thư mục widgets/):
//   - NumberInputField  → number_input_field.dart
//   - OptionCard        → option_card.dart
//   - SectionTitle      → section_title.dart
//   - AuthPrimaryButton → auth/widgets/auth_primary_button.dart
//   - AuthErrorBanner   → auth/widgets/auth_error_banner.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../viewmodels/info_setup_viewmodel.dart';
import '../viewmodels/info_setup_state.dart';
import '../widgets/number_input_field.dart';
import '../widgets/option_card.dart';
import '../widgets/section_title.dart';
import '../../auth/widgets/auth_primary_button.dart';
import '../../auth/widgets/auth_error_banner.dart';

// ─── Dữ liệu tĩnh cho các lựa chọn ──────────────────────────────────────────

class _ActivityOption {
  final String emoji;
  final String value;   // giá trị lưu vào Firestore
  final String subtitle;
  const _ActivityOption(this.emoji, this.value, this.subtitle);
}

class _GoalOption {
  final String emoji;
  final String value;
  final String subtitle;
  const _GoalOption(this.emoji, this.value, this.subtitle);
}

const _activityOptions = [
  _ActivityOption('🛋️', 'Ít vận động',      'Hầu như không tập, công việc văn phòng'),
  _ActivityOption('🚶', 'Vận động vừa',     '3–5 buổi/tuần, đi bộ hoặc đạp xe'),
  _ActivityOption('🏃', 'Vận động mạnh',    '6–7 buổi/tuần, tập gym hoặc thể thao'),
];

const _goalOptions = [
  _GoalOption('📈', 'Tăng cân', 'Tăng cơ, cải thiện thể hình'),
  _GoalOption('⚖️', 'Giữ cân',  'Duy trì cân nặng hiện tại'),
  _GoalOption('📉', 'Giảm cân', 'Đốt mỡ, giảm cân lành mạnh'),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class InfoSetupScreen extends ConsumerStatefulWidget {
  const InfoSetupScreen({super.key});

  @override
  ConsumerState<InfoSetupScreen> createState() => _InfoSetupScreenState();
}

class _InfoSetupScreenState extends ConsumerState<InfoSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // State cục bộ UI — chỉ quản lý lựa chọn đang active
  String? _selectedActivity;
  String? _selectedGoal;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ── Gọi ViewModel lưu thông tin ─────────────────────────────────────────
  void _handleSave() {
    // 1. Validate TextField (chiều cao, cân nặng)
    if (!_formKey.currentState!.validate()) return;

    // 2. Validate lựa chọn activity + goal
    if (_selectedActivity == null) {
      _showSnack('Vui lòng chọn mức độ vận động');
      return;
    }
    if (_selectedGoal == null) {
      _showSnack('Vui lòng chọn mục tiêu của bạn');
      return;
    }

    // 3. Giao cho ViewModel — View không biết gì về Firestore
    ref.read(infoSetupViewModelProvider.notifier).saveInfo(
      heightCm: double.parse(_heightController.text),
      weightKg: double.parse(_weightController.text),
      activityLevel: _selectedActivity!,
      goal: _selectedGoal!,
    );
  }

  // ── Lắng nghe state → điều hướng khi success ────────────────────────────
  void _listenState(InfoSetupState? prev, InfoSetupState next) {
    if (next.status == InfoSetupStatus.success) {
      // Hiện thông báo thành công → router tự vào home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Đăng ký thành công! Chào mừng bạn 🎉',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.listen(infoSetupViewModelProvider, _listenState);

    final state = ref.watch(infoSetupViewModelProvider);
    final isLoading = state.status == InfoSetupStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // ── Header ────────────────────────────────────
                          _buildHeader(),
                          const SizedBox(height: 32),

                          // ── SECTION 1: Thông số cơ thể ───────────────
                          SectionTitle(
                            step: '01',
                            title: 'Thông số cơ thể',
                            subtitle: 'Nhập chiều cao và cân nặng hiện tại',
                          ),
                          const SizedBox(height: 16),

                          // Chiều cao + Cân nặng nằm ngang
                          Row(
                            children: [
                              Expanded(
                                child: NumberInputField(
                                  controller: _heightController,
                                  label: 'Chiều cao',
                                  unit: 'cm',
                                  hint: '170',
                                  prefixIcon: Icons.height_rounded,
                                  min: 50,
                                  max: 250,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: NumberInputField(
                                  controller: _weightController,
                                  label: 'Cân nặng',
                                  unit: 'kg',
                                  hint: '65',
                                  prefixIcon: Icons.monitor_weight_outlined,
                                  min: 20,
                                  max: 300,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                          _buildDivider(),
                          const SizedBox(height: 28),

                          // ── SECTION 2: Mức vận động ───────────────────
                          SectionTitle(
                            step: '02',
                            title: 'Mức độ vận động',
                            subtitle: 'Mô tả thói quen tập luyện hằng ngày',
                          ),
                          const SizedBox(height: 16),

                          // 3 OptionCard cho activity level
                          ...List.generate(_activityOptions.length, (i) {
                            final opt = _activityOptions[i];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: i < _activityOptions.length - 1 ? 10 : 0,
                              ),
                              child: OptionCard(
                                emoji: opt.emoji,
                                title: opt.value,
                                subtitle: opt.subtitle,
                                isSelected: _selectedActivity == opt.value,
                                onTap: () => setState(
                                        () => _selectedActivity = opt.value),
                              ),
                            );
                          }),

                          const SizedBox(height: 32),
                          _buildDivider(),
                          const SizedBox(height: 28),

                          // ── SECTION 3: Mục tiêu ───────────────────────
                          SectionTitle(
                            step: '03',
                            title: 'Mục tiêu của bạn',
                            subtitle: 'Hệ thống sẽ cá nhân hóa theo mục tiêu này',
                          ),
                          const SizedBox(height: 16),

                          // 3 OptionCard cho goal
                          ...List.generate(_goalOptions.length, (i) {
                            final opt = _goalOptions[i];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: i < _goalOptions.length - 1 ? 10 : 0,
                              ),
                              child: OptionCard(
                                emoji: opt.emoji,
                                title: opt.value,
                                subtitle: opt.subtitle,
                                isSelected: _selectedGoal == opt.value,
                                onTap: () =>
                                    setState(() => _selectedGoal = opt.value),
                              ),
                            );
                          }),

                          const SizedBox(height: 28),

                          // ── Banner lỗi Firestore ──────────────────────
                          if (state.errorMessage != null) ...[
                            AuthErrorBanner(message: state.errorMessage!),
                            const SizedBox(height: 16),
                          ],

                          // ── Nút Hoàn tất ──────────────────────────────
                          AuthPrimaryButton(
                            label: 'Hoàn tất thiết lập 🎉',
                            isLoading: isLoading,
                            onPressed: _handleSave,
                          ),

                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI builders nhỏ ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar: bước 2/2
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước 2 / 2 — Thiết lập hồ sơ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 1.0, // bước 2/2 = 100%
                      backgroundColor: Color(0x1A000000),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Icon + title
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
              child: Text('📊', style: TextStyle(fontSize: 28))),
        ),

        const SizedBox(height: 18),

        const Text(
          'Hoàn thiện\nhồ sơ của bạn',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Thông tin này giúp hệ thống cá nhân hóa thực đơn và lịch tập riêng cho bạn.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.5),
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child:
            Divider(color: Colors.black.withOpacity(0.08), thickness: 1)),
      ],
    );
  }
}