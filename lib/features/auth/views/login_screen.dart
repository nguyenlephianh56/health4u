// lib/features/auth/views/login_screen.dart
//
// Mô tả: Màn hình đăng nhập bằng Gmail + Mật khẩu.
//
// Vai trò trong MVVM:
//   → VIEW: Chỉ lo xây dựng UI, lắng nghe state từ AuthViewModel.
//   → Gọi viewModel.login() khi user bấm nút — KHÔNG tự gọi Firebase.
//   → Lắng nghe AuthState để hiện loading / lỗi / điều hướng.
//
// Widgets dùng (từ thư mục widgets/):
//   - AuthTextField       (auth_text_field.dart)
//   - AuthPrimaryButton   (auth_primary_button.dart)
//   - AuthErrorBanner     (auth_error_banner.dart)

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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  // State cục bộ của View: chỉ quản lý show/hide password
  // (Không phải state nghiệp vụ → không cần đưa vào ViewModel)
  bool _obscurePassword = true;

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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  // ── Gọi ViewModel để đăng nhập ──────────────────────────────────────────
  void _handleLogin() {
    // Validate form trước (email đúng định dạng, password không rỗng)
    if (!_formKey.currentState!.validate()) return;

    // Gọi ViewModel — View không biết gì về Firebase
    ref.read(authViewModelProvider.notifier).login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  // ── Lắng nghe state thay đổi để điều hướng ──────────────────────────────
  // Dùng ref.listen thay vì kiểm tra trong build() để tránh rebuild vô ích
  void _listenToAuthState(AuthState? prev, AuthState next) {
    if (next.status == AuthStatus.success) {
      // Router tự redirect khi AuthRepo state = authenticated
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe state → điều hướng khi success
    ref.listen(authViewModelProvider, _listenToAuthState);

    // Lấy state hiện tại để hiện loading / lỗi
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),

                          // Logo + tiêu đề
                          _buildHeader(),
                          const SizedBox(height: 44),

                          // Gmail field
                          AuthTextField(
                            controller: _emailController,
                            label: 'Gmail',
                            hint: 'example@gmail.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),

                          // Mật khẩu field + icon con mắt
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            hint: 'Nhập mật khẩu',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: _buildEyeIcon(),
                            validator: _validatePassword,
                          ),

                          // Quên mật khẩu
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordSheet,
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          // Banner lỗi từ Firebase (chỉ hiện khi có lỗi)
                          if (authState.errorMessage != null) ...[
                            AuthErrorBanner(message: authState.errorMessage!),
                            const SizedBox(height: 16),
                          ],

                          const SizedBox(height: 8),

                          // Nút Đăng nhập
                          AuthPrimaryButton(
                            label: 'Đăng nhập',
                            isLoading: isLoading,
                            onPressed: _handleLogin,
                          ),

                          const Spacer(),
                          _buildRegisterLink(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Quên mật khẩu (BottomSheet) ─────────────────────────────────────────
  void _showForgotPasswordSheet() {
    _forgotEmailController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(authViewModelProvider);
            final isLoading = state.status == AuthStatus.loading;
            final isSuccess = state.status == AuthStatus.success;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: isSuccess
                    ? _buildForgotSuccess()
                    : _buildForgotForm(ref, isLoading, state.errorMessage),
              ),
            );
          },
        );
      },
    ).whenComplete(() => ref.read(authViewModelProvider.notifier).resetState());
  }

  Widget _buildForgotSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Text('📬', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text(
          'Kiểm tra hộp thư nhé!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Link đặt lại mật khẩu đã được gửi đến email của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.5),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotForm(WidgetRef ref, bool isLoading, String? errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Quên mật khẩu?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nhập email và chúng tôi sẽ gửi link đặt lại mật khẩu.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.5),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: _forgotEmailController,
          label: 'Email',
          hint: 'example@gmail.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          AuthErrorBanner(message: errorMessage),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
              final email = _forgotEmailController.text.trim();
              if (email.isEmpty) return;
              ref
                  .read(authViewModelProvider.notifier)
                  .forgotPassword(email: email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : const Text(
              'Gửi link đặt lại',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Validators (logic validate thuộc về View) ────────────────────────────

  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(val)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (val.length < 6) return 'Mật khẩu phải ít nhất 6 ký tự';
    return null;
  }

  // ── UI builders nhỏ ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo app
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(child: Text('💪', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 28),
        const Text(
          'Chào mừng\ntrở lại!',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Đăng nhập để tiếp tục hành trình sức khỏe của bạn.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black.withOpacity(0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Icon con mắt toggle ẩn/hiện mật khẩu
  Widget _buildEyeIcon() {
    return IconButton(
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: AppColors.primary.withOpacity(0.7),
        size: 22,
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 14),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.register),
          child: const Text(
            'Đăng ký ngay',
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