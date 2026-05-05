import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Avatar + Name ───────────────────────────────────────
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Avatar circle with initials
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen,
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name
                                      .split(' ')
                                      .map((w) => w.isNotEmpty ? w[0] : '')
                                      .take(2)
                                      .join()
                                      .toUpperCase()
                                  : '?',
                              style: AppTextStyles.headlineLarge
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        // Verified badge
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: AppTextStyles.headlineMedium),
                    Text(user.email, style: AppTextStyles.bodySmall),
                  ],
                ),

                const SizedBox(height: 24),



                const SizedBox(height: 20),

                // ── Aadhaar Card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fingerprint, color: AppColors.accentGold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AADHAAR CARD', style: AppTextStyles.labelSmall),
                            Text(
                              user.aadhaarNumber ?? '',
                              style: AppTextStyles.titleLarge.copyWith(
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Info Tiles ──────────────────────────────────────────
                Card(
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.person_outline,
                        label: 'Personal Information',
                        onTap: () => context.push('/profile/info'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.favorite_outline,
                        label: 'Saved Schemes',
                        onTap: () => context.push(AppRoutes.saved),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.history_rounded,
                        label: 'Application History',
                        onTap: () => context.push('/profile/history'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.verified_user_outlined,
                        label: 'Eligibility Check',
                        onTap: () => context.push(AppRoutes.eligibility),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.folder_copy_outlined,
                        label: 'Document Vault',
                        onTap: () => context.push(AppRoutes.documentVault),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: Icons.language_outlined,
                        label: 'Language Settings',
                        subtitle: 'Default: ${user.preferredLanguage == "en" ? "English" : "Hindi"}',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Select Language'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('English'),
                                    onTap: () {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .update({'preferredLanguage': 'en'});
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text('Hindi'),
                                    onTap: () {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .update({'preferredLanguage': 'hi'});
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Logout ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}



class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryGreenSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 18),
      ),
      title: Text(label, style: AppTextStyles.titleMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.bodySmall)
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}
