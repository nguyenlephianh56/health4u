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
                              onPressed: () {
                                // TODO: Tạo màn hình forgot password sau
                              },
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

                          const SizedBox(height: 24),
                          _buildDivider(),
                          const SizedBox(height: 24),
                          _buildGoogleButton(),

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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.black.withOpacity(0.12), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'hoặc',
            style: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.black.withOpacity(0.12), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: () {/* TODO: Google Sign In */},
        icon: const Text('🌐', style: TextStyle(fontSize: 20)),
        label: const Text(
          'Đăng nhập với Google',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.black.withOpacity(0.15)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: AppColors.surface,
        ),
      ),
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