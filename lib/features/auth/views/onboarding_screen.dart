// lib/features/auth/views/onboarding_screen.dart
//
// Mô tả: Màn hình Onboarding gồm 3 trang giới thiệu app.
// Hiển thị khi user chưa đăng nhập lần nào.
//
// Vai trò trong MVVM:
//   → VIEW: Chỉ lo hiển thị UI và animation.
//   → Không gọi Firebase, không có logic nghiệp vụ.
//   → Khi user bấm nút, điều hướng sang LoginScreen hoặc RegisterScreen.
//
// Điều hướng:
//   "Bỏ qua" / "Đăng nhập" → /login
//   "Bắt đầu ngay"          → /login  (hoặc /register tùy luồng)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../../core/constants/app_colors.dart';

// ─── Data model cho mỗi trang Onboarding ────────────────────────────────────
// Đây là data tĩnh, không liên quan Firestore nên để thẳng trong View
class _OnboardingPageData {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;

  const _OnboardingPageData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
  });
}

// ─── Danh sách 3 trang ──────────────────────────────────────────────────────
const _pages = [
  _OnboardingPageData(
    emoji: '🥗',
    title: 'Thực đơn\nthông minh',
    subtitle:
    'Hệ thống tự động lên kế hoạch 4 bữa mỗi ngày, 28 bữa mỗi tuần — phù hợp với mục tiêu sức khỏe của bạn.',
    gradientColors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    accentColor: Color(0xFFF59E0B),
  ),
  _OnboardingPageData(
    emoji: '🏋️',
    title: 'Luyện tập\nhằng ngày',
    subtitle:
    'Lộ trình tập luyện cá nhân hóa: Cardio, Yoga, Strength — theo dõi calo tiêu thụ theo thời gian thực.',
    gradientColors: [Color(0xFF0369A1), Color(0xFF0284C7)],
    accentColor: Color(0xFFFBBF24),
  ),
  _OnboardingPageData(
    emoji: '🔥',
    title: 'Chuỗi ngày\nkỷ luật',
    subtitle:
    'Tích lũy Streaks mỗi ngày, đổi điểm thưởng lấy các bộ giao diện độc đáo trong Theme Store.',
    gradientColors: [Color(0xFF075985), Color(0xFF0284C7)],
    accentColor: Color(0xFFF59E0B),
  ),
];

// ─── Screen ─────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controller cho fade + slide khi chuyển trang
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  // Khi PageView chuyển trang → restart animation
  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animController.reset();
    _animController.forward();
  }

  // Bấm nút "Tiếp theo" hoặc "Bắt đầu ngay"
  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      // Còn trang tiếp theo → chuyển trang
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Trang cuối → vào app
      _goToLogin();
    }
  }

  void _goToLogin() {
    // Đánh dấu đã xem onboarding → lần sau mở app vào thẳng Login
    ref.read(authRepoProvider.notifier).completeOnboarding();
    // Router tự redirect khi state thay đổi — không cần context.go()
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        // Gradient thay đổi theo trang
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: page.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Hình tròn trang trí nền
              _buildBackgroundDecorations(),

              Column(
                children: [
                  // Nút bỏ qua
                  _buildSkipButton(),

                  // Nội dung 3 trang (swipe được)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (_, index) => _OnboardingPageContent(
                        data: _pages[index],
                        fadeAnim: _fadeAnim,
                        slideAnim: _slideAnim,
                      ),
                    ),
                  ),

                  // Dot indicator + nút bấm + link đăng nhập
                  _buildBottomSection(page),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI builders ─────────────────────────────────────────────────────────

  Widget _buildBackgroundDecorations() {
    return Stack(children: [
      Positioned(
        top: -60, right: -60,
        child: _Circle(size: 220, opacity: 0.07),
      ),
      Positioned(
        bottom: 120, left: -80,
        child: _Circle(size: 280, opacity: 0.05),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.35, right: -40,
        child: _Circle(size: 160, opacity: 0.06),
      ),
    ]);
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 20, top: 12),
        child: TextButton(
          onPressed: _goToLogin,
          child: const Text(
            'Bỏ qua',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(_OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      child: Column(
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? page.accentColor
                      : Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Nút Tiếp theo / Bắt đầu ngay
          GestureDetector(
            onTap: _onNextPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: page.accentColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: page.accentColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentPage == _pages.length - 1
                      ? 'Bắt đầu ngay 🚀'
                      : 'Tiếp theo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Link đăng nhập
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đã có tài khoản? ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: _goToLogin,
                child: Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: page.accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Widget con: nội dung 1 trang onboarding ────────────────────────────────
// Tách thành widget riêng để PageView builder gọn hơn
class _OnboardingPageContent extends StatelessWidget {
  final _OnboardingPageData data;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _OnboardingPageContent({
    required this.data,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji trong card kính mờ
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(data.emoji, style: const TextStyle(fontSize: 64)),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Tiêu đề lớn
              Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Thanh accent màu vàng
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Mô tả
              Text(
                data.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 16,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget trang trí hình tròn nền ─────────────────────────────────────────
class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}