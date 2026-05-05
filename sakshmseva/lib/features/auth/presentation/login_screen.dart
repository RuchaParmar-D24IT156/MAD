import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Login screen with Aadhaar number, email, password, Google Sign-In.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _aadhaarController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && mounted) context.go(AppRoutes.home);
  }

  Future<void> _onGoogleSignIn() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signInWithGoogle();
    if (success && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Show error snackbar
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo + App name
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Text('SakshmSeva', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primaryGreen)),
              Text(
                'Empowering every citizen through service',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back', style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 24),

                        CustomTextField(
                          controller: _aadhaarController,
                          label: 'Aadhaar Number',
                          hint: '12-digit Aadhaar Number',
                          prefixIcon: Icons.fingerprint,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return null; // optional at login
                            if (v.length != 12) return 'Aadhaar must be 12 digits';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'name@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(AppRoutes.forgotPassword),
                            child: const Text('Forgot password?'),
                          ),
                        ),

                        const SizedBox(height: 8),

                        PrimaryButton(
                          label: 'Login',
                          onPressed: _onLogin,
                          isLoading: authState.isLoading,
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR CONTINUE WITH', style: AppTextStyles.labelSmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        OutlineButton(
                          label: 'Sign in with Google',
                          onPressed: _onGoogleSignIn,
                          isLoading: authState.isLoading,
                          icon: _GoogleIcon(),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: AppTextStyles.bodyMedium,
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.push(AppRoutes.signup),
                                    child: Text(
                                      'Create Account',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primaryGreen,
                                      ),
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
                ),
              ),

              const SizedBox(height: 24),

              // Privacy footer
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  _FooterLink(label: 'Privacy Policy', onTap: () {}),
                  _FooterLink(label: 'Terms of Service', onTap: () {}),
                  _FooterLink(label: 'Help Center', onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: AppTextStyles.bodySmall.copyWith(decoration: TextDecoration.underline)),
    );
  }
}
