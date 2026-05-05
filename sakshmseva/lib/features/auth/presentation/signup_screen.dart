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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _termsAccepted = false;
  double _passwordStrength = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _aadhaarController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) strength += 0.25;
    return strength;
  }

  String _strengthLabel(double strength) {
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Good';
    return 'Strong';
  }

  Color _strengthColor(double strength) {
    if (strength <= 0.25) return AppColors.error;
    if (strength <= 0.5) return AppColors.warning;
    if (strength <= 0.75) return Colors.blue;
    return AppColors.success;
  }

  Future<void> _onSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service')),
      );
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.signUpWithEmail(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      aadhaarNumber: _aadhaarController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
    );
    if (success && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
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
              const SizedBox(height: 32),

              // Header
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              Text('Create Account', style: AppTextStyles.headlineMedium),
              Text(
                'Join SakshmSeva to access secure and efficient government services.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'John Doe',
                          prefixIcon: Icons.person_outline,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Full name is required';
                            if (v.length < 3) return 'Name must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'john@example.com',
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
                          controller: _ageController,
                          label: 'Age',
                          hint: '25',
                          prefixIcon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Age is required';
                            final age = int.tryParse(v);
                            if (age == null || age < 18 || age > 120) return 'Enter a valid age (18+)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _aadhaarController,
                          label: 'Aadhaar Number',
                          hint: 'XXXX XXXX XXXX',
                          prefixIcon: Icons.fingerprint,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Aadhaar number is required';
                            if (v.length != 12) return 'Aadhaar must be 12 digits';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password with strength meter
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          onChanged: (v) {
                            setState(() => _passwordStrength = _calculateStrength(v));
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 8) return 'Password must be at least 8 characters';
                            return null;
                          },
                        ),

                        // Strength meter
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _passwordStrength,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation(
                                _strengthColor(_passwordStrength),
                              ),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_strengthLabel(_passwordStrength)} password',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _strengthColor(_passwordStrength),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please confirm your password';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Terms checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                              activeColor: AppColors.primaryGreen,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'By creating an account, you agree to the ',
                                    style: AppTextStyles.bodySmall,
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primaryGreen,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' and ', style: AppTextStyles.bodySmall),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primaryGreen,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: '.', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        PrimaryButton(
                          label: 'Create Account →',
                          onPressed: _onSignup,
                          isLoading: authState.isLoading,
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: AppTextStyles.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: 'Log In',
                                    style: AppTextStyles.labelLarge
                                        .copyWith(color: AppColors.primaryGreen),
                                  ),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
