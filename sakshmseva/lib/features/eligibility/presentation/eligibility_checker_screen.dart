import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/scheme_model.dart';
import '../../../core/providers/schemes_provider.dart';
import '../../../shared/widgets/scheme_card.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Eligibility form state
class EligibilityForm {
  final String? age;
  final String? gender;
  final String? occupation;
  final String? income;
  final String? selectedSchemeId;

  const EligibilityForm({this.age, this.gender, this.occupation, this.income, this.selectedSchemeId});

  EligibilityForm copyWith({String? age, String? gender, String? occupation, String? income, String? selectedSchemeId}) {
    return EligibilityForm(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      income: income ?? this.income,
      selectedSchemeId: selectedSchemeId ?? this.selectedSchemeId,
    );
  }
}

final eligibilityFormProvider = StateProvider<EligibilityForm>((ref) => const EligibilityForm());
final eligibilityResultsProvider = StateProvider<List<SchemeModel>?>((ref) => null);

class EligibilityCheckerScreen extends ConsumerStatefulWidget {
  const EligibilityCheckerScreen({super.key});

  @override
  ConsumerState<EligibilityCheckerScreen> createState() => _EligibilityCheckerScreenState();
}

class _EligibilityCheckerScreenState extends ConsumerState<EligibilityCheckerScreen> {
  final _ageController = TextEditingController();
  final _incomeController = TextEditingController();

  static const _occupations = [
    'Farmer', 'Student', 'Government Employee', 'Private Employee',
    'Self-Employed', 'Daily Wage Worker', 'Homemaker', 'Retired', 'Other',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _checkEligibility() {
    final form = ref.read(eligibilityFormProvider);
    final allSchemes = ref.read(schemesProvider(null)).valueOrNull ?? [];

    final age = int.tryParse(form.age ?? '0') ?? 0;
    final income = double.tryParse(form.income ?? '0') ?? 0;

    final results = allSchemes.where((s) {
      bool matches = true;
      if (s.minAge != null && age < s.minAge!) matches = false;
      if (s.maxAge != null && age > s.maxAge!) matches = false;
      if (s.maxIncome != null && income > s.maxIncome!) matches = false;
      if (s.targetOccupations.isNotEmpty &&
          form.occupation != null &&
          !s.targetOccupations.contains(form.occupation!.toLowerCase())) {
        // Don't strictly exclude — just deprioritize
      }
      return matches;
    }).toList();

    ref.read(eligibilityResultsProvider.notifier).state = results;

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    final userModel = ref.read(currentUserProvider).value;
    if (user != null && userModel != null) {
      final batch = FirebaseFirestore.instance.batch();
      
      if (form.selectedSchemeId != null) {
        final selectedScheme = allSchemes.firstWhere((s) => s.id == form.selectedSchemeId);
        final isEligible = results.contains(selectedScheme);
        final score = isEligible ? 100 : 0;
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('eligibilityResults')
            .doc(selectedScheme.id);
        
        batch.set(docRef, {
          'aadhaar': userModel.aadhaarNumber,
          'email': userModel.email,
          'score': score,
          'isEligible': isEligible,
          'answers': {
            'age': age,
            'gender': form.gender,
            'occupation': form.occupation,
            'income': income,
          },
          'checkedAt': FieldValue.serverTimestamp(),
        });
      } else {
        for (final s in allSchemes) {
          final isEligible = results.contains(s);
          final score = isEligible ? 100 : 0;
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('eligibilityResults')
              .doc(s.id);
          
          batch.set(docRef, {
            'aadhaar': userModel.aadhaarNumber,
            'email': userModel.email,
            'score': score,
            'isEligible': isEligible,
            'answers': {
              'age': age,
              'gender': form.gender,
              'occupation': form.occupation,
              'income': income,
            },
            'checkedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      batch.commit().catchError((e) => debugPrint('Error saving eligibility: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(eligibilityFormProvider);
    final results = ref.watch(eligibilityResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('Eligibility Checker'),
        leading: BackButton(color: AppColors.primaryGreen),
      ),
      body: results != null && results.isNotEmpty
          ? _ResultsView(schemes: results, onReset: () {
              ref.read(eligibilityResultsProvider.notifier).state = null;
            })
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar
                  Row(
                    children: [
                      Text('STEP 1 OF 4', style: AppTextStyles.labelSmall),
                      const Spacer(),
                      Text('Personal Details', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
                      minHeight: 4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('Find Your Schemes', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your details accurately. Your data is used only for matching purposes and remains private.',
                    style: AppTextStyles.bodySmall,
                  ),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Scheme Selection
                          Text('Select Scheme (Optional)', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: form.selectedSchemeId,
                            hint: const Text('All Schemes'),
                            isExpanded: true,
                            decoration: const InputDecoration(),
                            items: (ref.watch(schemesProvider(null)).valueOrNull ?? []).map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) => ref
                                .read(eligibilityFormProvider.notifier)
                                .state = form.copyWith(selectedSchemeId: v),
                          ),
                          const SizedBox(height: 20),

                          // Age
                          Text('Age', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(hintText: 'Enter your age'),
                            onChanged: (v) => ref
                                .read(eligibilityFormProvider.notifier)
                                .state = form.copyWith(age: v),
                          ),

                          const SizedBox(height: 20),

                          // Gender
                          Text('Gender', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Male', 'Female', 'Other'].map((g) {
                              final isSelected = form.gender == g;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(eligibilityFormProvider.notifier)
                                      .state = form.copyWith(gender: g),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryGreen : AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryGreen : AppColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      g,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // Occupation
                          Text('Occupation', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: form.occupation,
                            hint: const Text('Select Occupation'),
                            decoration: const InputDecoration(),
                            items: _occupations.map((o) {
                              return DropdownMenuItem(value: o, child: Text(o));
                            }).toList(),
                            onChanged: (v) => ref
                                .read(eligibilityFormProvider.notifier)
                                .state = form.copyWith(occupation: v),
                          ),

                          const SizedBox(height: 20),

                          // Income
                          Text('Annual Family Income (₹)', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _incomeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 1,50,000',
                              helperText: 'Include incomes from all sources',
                              prefixText: '₹ ',
                            ),
                            onChanged: (v) {
                              final cleaned = v.replaceAll(',', '');
                              ref.read(eligibilityFormProvider.notifier).state =
                                  form.copyWith(income: cleaned);
                            },
                          ),

                          const SizedBox(height: 24),

                          PrimaryButton(
                            label: '🔍  Check Eligibility',
                            onPressed: _checkEligibility,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.schemes, required this.onReset});

  final List<SchemeModel> schemes;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primaryGreenSurface,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryGreen),
              const SizedBox(width: 10),
              Text(
                '${schemes.length} scheme(s) found for you!',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryGreen),
              ),
              const Spacer(),
              TextButton(onPressed: onReset, child: const Text('Reset')),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schemes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final scheme = schemes[i];
              return SchemeCard(
                scheme: scheme,
                showStatus: true,
                onApply: () => context.push('/schemes/${scheme.id}'),
                onSave: () {}, // Handled similarly if needed
              );
            },
          ),
        ),
      ],
    );
  }
}
