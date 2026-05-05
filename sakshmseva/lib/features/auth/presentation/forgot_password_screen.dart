import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.sendPasswordReset(_emailController.text);
    if (mounted) setState(() => _emailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryGreen),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _emailSent ? _SuccessMessage() : _EmailForm(
          formKey: _formKey,
          emailController: _emailController,
          isLoading: authState.isLoading,
          onSend: _onSend,
        ),
      ),
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset, color: AppColors.primaryGreen, size: 48),
          const SizedBox(height: 16),
          Text('Reset Password', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email. We\'ll send you a link to reset your password.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: emailController,
            label: 'Email Address',
            hint: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send Reset Link',
            onPressed: onSend,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreenSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryGreen, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Check Your Email', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent a password reset link to your email address.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}
