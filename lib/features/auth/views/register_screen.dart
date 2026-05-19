// lib/features/auth/views/register_screen.dart
//
// Mô tả: Màn hình đăng ký tài khoản mới.
//
// Vai trò trong MVVM:
//   → VIEW: Chỉ lo xây dựng UI, validate form cục bộ.
//   → Gọi viewModel.register() khi user bấm "Tạo tài khoản".
//   → Lắng nghe AuthState để hiện loading / lỗi / điều hướng.
//
// Widgets dùng (từ thư mục widgets/):
//   - AuthTextField       → auth_text_field.dart
//   - AuthPrimaryButton   → auth_primary_button.dart
//   - AuthErrorBanner     → auth_error_banner.dart
//   - GenderPicker        → gender_picker.dart
//   - DobPickerField      → dob_picker_field.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/gender_picker.dart';
import '../widgets/dob_picker_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các TextField
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State cục bộ của View (UI-only, không liên quan nghiệp vụ)
  String? _selectedGender;
  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Gọi ViewModel để đăng ký ────────────────────────────────────────────
  void _handleRegister() {
    // 1. Validate tất cả TextField
    if (!_formKey.currentState!.validate()) return;

    // 2. Validate riêng Giới tính và Ngày sinh (không phải TextField)
    if (_selectedGender == null) {
      _showSnackBar('Vui lòng chọn giới tính');
      return;
    }
    if (_selectedDob == null) {
      _showSnackBar('Vui lòng chọn ngày sinh');
      return;
    }

    // 3. Giao cho ViewModel xử lý — View không biết gì về Firebase
    ref.read(authViewModelProvider.notifier).register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      gender: _selectedGender!,
      dob: _formatDobForFirestore(_selectedDob!), // "YYYY-MM-DD"
    );
  }

  // ── Lắng nghe state → điều hướng khi thành công ─────────────────────────
  void _listenToAuthState(AuthState? prev, AuthState next) {
    if (next.status == AuthStatus.success) {
      // Sau đăng ký → sang InfoSetupScreen để điền chiều cao, cân nặng...
      // Router tự redirect khi AuthRepo state = needsSetup
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Format DateTime → "YYYY-MM-DD" để lưu vào Firestore
  String _formatDobForFirestore(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Validators ──────────────────────────────────────────────────────────

  String? _validateName(String? val) {
    if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ và tên';
    if (val.trim().length < 2) return 'Họ tên phải ít nhất 2 ký tự';
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(val)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (val.length < 8) return 'Mật khẩu phải ít nhất 8 ký tự';
    if (!RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(val)) {
      return 'Mật khẩu phải có cả chữ và số';
    }
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (val != _passwordController.text) return 'Mật khẩu không khớp';
    return null;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Lắng nghe state → điều hướng khi success
    ref.listen(authViewModelProvider, _listenToAuthState);

    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Nút back + progress bar
                    _buildTopBar(),
                    const SizedBox(height: 28),

                    // Tiêu đề
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // ── Họ và tên ──────────────────────────────────────
                    _FieldLabel(label: 'Họ và tên'),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: _nameController,
                      label: '',            // label đã render ở trên
                      hint: 'Nguyễn Văn A',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),

                    // ── Giới tính ──────────────────────────────────────
                    _FieldLabel(label: 'Giới tính'),
                    const SizedBox(height: 8),
                    // Widget GenderPicker tách riêng → gender_picker.dart
                    GenderPicker(
                      selected: _selectedGender,
                      onChanged: (val) =>
                          setState(() => _selectedGender = val),
                    ),
                    const SizedBox(height: 20),

                    // ── Ngày sinh ──────────────────────────────────────
                    _FieldLabel(label: 'Ngày tháng năm sinh'),
                    const SizedBox(height: 8),
                    // Widget DobPickerField tách riêng → dob_picker_field.dart
                    DobPickerField(
                      selectedDate: _selectedDob,
                      onDateSelected: (date) =>
                          setState(() => _selectedDob = date),
                    ),
                    const SizedBox(height: 20),

                    // ── Gmail ──────────────────────────────────────────
                    _FieldLabel(label: 'Gmail'),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: _emailController,
                      label: '',
                      hint: 'example@gmail.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),

                    // ── Mật khẩu ──────────────────────────────────────
                    _FieldLabel(label: 'Mật khẩu'),
                    const SizedBox(height: 4),
                    // Ghi chú nhỏ về mã hoá
                    _buildPasswordHint(),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: _passwordController,
                      label: '',
                      hint: 'Ít nhất 8 ký tự, có cả chữ và số',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      // Icon con mắt toggle ẩn/hiện password
                      suffixIcon: _buildEyeIcon(
                        isObscure: _obscurePassword,
                        onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),

                    // ── Xác nhận mật khẩu ─────────────────────────────
                    _FieldLabel(label: 'Xác nhận mật khẩu'),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: '',
                      hint: 'Nhập lại mật khẩu',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
                      // Icon con mắt riêng cho confirm password
                      suffixIcon: _buildEyeIcon(
                        isObscure: _obscureConfirmPassword,
                        onTap: () => setState(() =>
                        _obscureConfirmPassword =
                        !_obscureConfirmPassword),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 12),

                    // ── Banner lỗi Firebase ────────────────────────────
                    if (authState.errorMessage != null) ...[
                      AuthErrorBanner(message: authState.errorMessage!),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 16),

                    // ── Nút Tạo tài khoản ─────────────────────────────
                    AuthPrimaryButton(
                      label: 'Tạo tài khoản',
                      isLoading: isLoading,
                      onPressed: _handleRegister,
                    ),

                    const SizedBox(height: 20),
                    _buildLoginLink(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI builders nhỏ ─────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        // Nút back
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bước 1 / 2 — Thông tin cơ bản',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.5,
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
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tạo tài khoản\nmới 👋',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Điền đầy đủ thông tin để bắt đầu hành trình sức khỏe.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black.withOpacity(0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordHint() {
    return Row(
      children: [
        Icon(Icons.info_outline,
            size: 13, color: Colors.black.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(
          'Mật khẩu sẽ được mã hoá SHA-256 trước khi lưu.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  /// Icon con mắt dùng chung cho password và confirm password
  Widget _buildEyeIcon({
    required bool isObscure,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        isObscure
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: AppColors.primary.withOpacity(0.7),
        size: 22,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () =>
              context.go(AppRoutes.login),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widget nhỏ: Label phía trên mỗi field ───────────────────────────────────
// Tách thành widget riêng để dùng lại trong cùng file, tránh lặp code
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    );
  }
}