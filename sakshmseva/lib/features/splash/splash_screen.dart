import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Splash screen with animated progress bar and Gujarat government branding.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _percentage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _controller.addListener(() {
      setState(() {
        _percentage = (_progressAnimation.value * 100).toInt();
      });
    });

    _controller.forward().then((_) => _navigateToNext());
  }

  void _navigateToNext() {
    // Navigate to home. The GoRouter redirect will intercept this and route to login if unauthenticated.
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
              Color(0xFF1B5E20),
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Government emblem placeholder
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _GovernmentEmblem(),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'SakshmSeva',
                          style: AppTextStyles.splashTitle,
                        ),
                        Text(
                          'Gujarat',
                          style: AppTextStyles.splashTitle.copyWith(
                            color: AppColors.accentGoldLight,
                            fontSize: 28,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 60,
                          height: 2,
                          color: AppColors.accentGold,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'EMPOWERING CITIZENS OF GUJARAT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textOnPrimary.withOpacity(0.75),
                            letterSpacing: 2.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Progress bar section
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INITIALISING',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textOnPrimary.withOpacity(0.6),
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '$_percentage%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textOnPrimary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (_, __) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.accentGold,
                            ),
                            minHeight: 3,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Government footer
                _GovernmentFooter(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GovernmentEmblem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _GovernmentFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOVERNMENT OF GUJARAT',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Official Citizen Services Platform',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 9,
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
