import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:blightscan/core/constants/app_colors.dart';
import 'package:blightscan/core/constants/app_text_styles.dart';
import 'package:blightscan/core/widgets/gs_button.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/utils/app_routes.dart';

// Data model
class _OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Welcome to BlightScan',
      description:
          'Focused AI support for detecting Tomato Late Blight from tomato leaf images.',
      imagePath: 'assets/images/onboarding/home.jpeg',
      icon: Icons.eco_rounded,
    ),
    _OnboardingData(
      title: 'Diagnose Plant Issues\nIn Seconds',
      description:
          'Capture or upload a clear tomato leaf image and get a Healthy or Late Blight result with confidence.',
      imagePath: 'assets/images/onboarding/diagnose.jpeg',
      icon: Icons.camera_alt_rounded,
    ),
    _OnboardingData(
      title: 'Treatment & Prevention',
      description:
          'View symptoms, treatment guidance, prevention tips, and saved scan history after each diagnosis.',
      imagePath: 'assets/images/onboarding/diagnose.jpeg',
      icon: Icons.medical_services_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.getStarted);
    }
  }

  void _skip() {
    context.go(AppRoutes.getStarted);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroHeight = size.height * 0.80;
    final sheetHeight = math.max(size.height * 0.40, 360.0);
    final phoneHeight = (size.height * 0.90).clamp(320.0, 580.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1FA971),
                    const Color(0xFF168555),
                    const Color(0xFF0F6B45).withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SizedBox(
            height: heroHeight,
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 28,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) {
                      setState(() => _currentPage = i);
                      _fadeController.forward(from: 0.0);
                      _scaleController.forward(from: 0.0);
                    },
                    itemBuilder: (_, i) => ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _PhoneMockup(
                            imagePath: _pages[i].imagePath,
                            maxHeight: phoneHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _CurvedBottomSheet(
              height: sheetHeight,
              controller: _pageController,
              currentPage: _currentPage,
              totalPages: _pages.length,
              data: _pages[_currentPage],
              onNext: _nextPage,
              onSkip: _skip,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  static const _mockupPath = 'assets/images/smartphone_frame_mockup.png';
  static const _canvasWidth = 1505.0;
  static const _canvasHeight = 1060.0;
  static const _visibleLeft = 494.0;
  static const _visibleTop = 22.0;
  static const _visibleWidth = 516.0;
  static const _visibleHeight = 1002.0;
  static const _screenLeft = 519.0;
  static const _screenTop = 50.0;
  static const _screenWidth = 466.0;
  static const _screenHeight = 1020.0;

  final String imagePath;
  final double maxHeight;

  const _PhoneMockup({required this.imagePath, required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final assetScale = math.min(
          maxHeight / _visibleHeight,
          constraints.maxHeight / _visibleHeight,
        );
        final phoneWidth = _visibleWidth * assetScale;
        final phoneHeight = _visibleHeight * assetScale;
        final canvasWidth = _canvasWidth * assetScale;
        final canvasHeight = _canvasHeight * assetScale;

        return SizedBox(
          width: phoneWidth,
          height: phoneHeight,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: (_screenLeft - _visibleLeft) * assetScale,
                  top: (_screenTop - _visibleTop) * assetScale,
                  width: _screenWidth * assetScale,
                  height: _screenHeight * assetScale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(42 * assetScale),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  left: -_visibleLeft * assetScale,
                  top: -_visibleTop * assetScale,
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Image.asset(
                    _mockupPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurvedBottomSheet extends StatelessWidget {
  final double height;
  final PageController controller;
  final int currentPage;
  final int totalPages;
  final _OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _CurvedBottomSheet({
    required this.height,
    required this.controller,
    required this.currentPage,
    required this.totalPages,
    required this.data,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == totalPages - 1;
    final curveDepth = math.min(28.0, height * 0.1);

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CurvedSheetPainter(
          curveDepth: curveDepth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            curveDepth * 2 + 12,
            24,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SmoothPageIndicator(
                        controller: controller,
                        count: totalPages,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: AppColors.primary,
                          dotHeight: 8,
                          dotWidth: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!isLast)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSkip,
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GSButton(
                        label: 'Continue',
                        onPressed: onNext,
                      ),
                    ),
                  ],
                )
              else
                GSButton(
                  label: 'Get Started',
                  onPressed: onNext,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurvedSheetPainter extends CustomPainter {
  final double curveDepth;

  const _CurvedSheetPainter({required this.curveDepth});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, curveDepth * 2, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CurvedSheetPainter oldDelegate) =>
      oldDelegate.curveDepth != curveDepth;
}
