import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/schemes_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/scheme_model.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchemeDetailScreen extends ConsumerWidget {
  const SchemeDetailScreen({super.key, required this.schemeId});

  final String schemeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get scheme from the all-schemes provider (null = all categories)
    final schemesAsync = ref.watch(schemesProvider(null));
    final scheme = schemesAsync.valueOrNull?.firstWhere(
      (s) => s.id == schemeId,
      orElse: () => throw Exception('Not found'),
    );

    if (scheme == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Save to history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .doc(scheme.id)
            .set({
          'schemeId': scheme.id,
          'visitedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    final savedIdsAsync = ref.watch(savedSchemeIdsProvider);
    final isSaved = savedIdsAsync.when(
      data: (ids) => ids.contains(scheme.id),
      loading: () => false,
      error: (_, __) => false,
    );

    // Category → icon mapping
    const categoryIcon = <String, IconData>{
      'agriculture': Icons.grass,
      'education': Icons.school_outlined,
      'healthcare': Icons.local_hospital_outlined,
      'women': Icons.woman_outlined,
      'environment': Icons.eco_outlined,
      'industry': Icons.factory_outlined,
      'skill': Icons.work_outline,
      'social': Icons.people_outlined,
      'tourism': Icons.tour_outlined,
      'transport': Icons.directions_bus_outlined,
      'digital': Icons.computer_outlined,
    };
    final icon = categoryIcon[scheme.category] ?? Icons.article_outlined;

    String? getSectorImage(String category) {
      switch (category.toLowerCase()) {
        case 'agriculture':
          return 'assets/images/sectors/img1_farmer_sector.jpg';
        case 'education':
          return 'assets/images/sectors/img2_education_sector.webp';
        case 'digital':
          return 'assets/images/sectors/img3_digitalGujrat_sector.png';
        case 'healthcare':
        case 'health':
          return 'assets/images/sectors/img4_health_sector.jpg';
        default:
          return null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: () {
                if (scheme.imageUrl.isNotEmpty) {
                  return CachedNetworkImage(imageUrl: scheme.imageUrl, fit: BoxFit.cover);
                }
                final sectorImage = getSectorImage(scheme.category);
                if (sectorImage != null) {
                  return Image.asset(sectorImage, fit: BoxFit.cover);
                }
                return Container(
                  color: AppColors.primaryGreenSurface,
                  child: Center(
                    child: Icon(icon, size: 64, color: AppColors.primaryGreen),
                  ),
                );
              }(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreenSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scheme.category.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(scheme.title, style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 8),
                  Text(scheme.description, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 20),

                  // Benefit / Services
                  if (scheme.services.isNotEmpty) ...[
                    _InfoCard(
                      icon: Icons.star_outline,
                      title: 'Services & Benefits',
                      value: scheme.services,
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    _InfoCard(
                      icon: Icons.star_outline,
                      title: 'Benefit Highlight',
                      value: scheme.benefitHighlight,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Documents needed
                  if (scheme.documentsNeeded.isNotEmpty) ...[
                    _InfoCard(
                      icon: Icons.description_outlined,
                      title: 'Documents Needed',
                      value: scheme.documentsNeeded,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Status badge
                  _InfoCard(
                    icon: Icons.info_outline,
                    title: 'Status',
                    value: scheme.status.name.toUpperCase(),
                  ),

                  const SizedBox(height: 28),

                  OutlineButton(
                    label: isSaved ? 'Saved Scheme' : 'Save Scheme',
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? AppColors.error : AppColors.primaryGreen,
                    ),
                    onPressed: () {
                      ref
                          .read(schemeActionsProvider.notifier)
                          .toggleSave(scheme.id, !isSaved);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.schemeBenefit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
