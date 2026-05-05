import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AadhaarScreen extends ConsumerStatefulWidget {
  const AadhaarScreen({super.key});

  @override
  ConsumerState<AadhaarScreen> createState() => _AadhaarScreenState();
}

class _AadhaarScreenState extends ConsumerState<AadhaarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _aadhaarController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'Gujarat Citizen',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'aadhaar': _aadhaarController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'aadhaarVerified': false,
          'preferredLanguage': 'en',
        }, SetOptions(merge: true));
      }
      
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving details: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Complete Your Profile',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We need a few more details to set up your SakshmSeva account.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                        
                        const SizedBox(height: 32),
                        
                        PrimaryButton(
                          label: 'Save & Continue →',
                          onPressed: _submit,
                          isLoading: _isLoading,
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
    );
  }
}
