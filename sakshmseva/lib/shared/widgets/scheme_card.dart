import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/models/scheme_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Reusable scheme card used in recommended and list sections.
class SchemeCard extends StatelessWidget {
  const SchemeCard({
    super.key,
    required this.scheme,
    this.onApply,
    this.onSave,
    this.isSaved = false,
    this.showStatus = false,
  });

  final SchemeModel scheme;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final bool isSaved;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStatus) _SchemeImageWithStatus(scheme: scheme),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryTag(category: scheme.category),
                    const Spacer(),
                    if (onSave != null)
                      GestureDetector(
                        onTap: onSave,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isSaved),
                            color: isSaved ? AppColors.error : AppColors.textMuted,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(scheme.title, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(
                  scheme.description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BENEFIT AMOUNT', style: AppTextStyles.labelSmall),
                        Text(scheme.benefitHighlight, style: AppTextStyles.schemeBenefit),
                      ],
                    ),
                    const Spacer(),
                    if (onApply != null)
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onApply,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Apply Now'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scheme card with image hero and status overlay (used in Saved screen)
class SchemeCardWithImage extends StatelessWidget {
  const SchemeCardWithImage({
    super.key,
    required this.scheme,
    this.onApply,
    this.onSave,
    this.isSaved = true,
  });

  final SchemeModel scheme;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _NetworkImage(imageUrl: scheme.imageUrl, height: 160, category: scheme.category),
              Positioned(
                top: 12,
                left: 12,
                child: _StatusChip(status: scheme.status),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onSave,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? AppColors.error : AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scheme.title, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  scheme.description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Eligibility: ${scheme.eligibilityNote ?? "Open"}',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onApply,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Apply Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemeImageWithStatus extends StatelessWidget {
  const _SchemeImageWithStatus({required this.scheme});
  final SchemeModel scheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _NetworkImage(imageUrl: scheme.imageUrl, height: 140, category: scheme.category),
        Positioned(
          top: 12,
          left: 12,
          child: _StatusChip(status: scheme.status),
        ),
      ],
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.imageUrl, required this.height, this.category});
  final String imageUrl;
  final double height;
  final String? category;

  String? _getSectorImage(String? cat) {
    if (cat == null) return null;
    switch (cat.toLowerCase()) {
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
        return 'assets/images/sectors/img3_digitalGujrat_sector.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      final sectorImage = _getSectorImage(category);
      if (sectorImage != null) {
        return Image.asset(
          sectorImage,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
      return Container(
        height: height,
        width: double.infinity,
        color: AppColors.primaryGreenSurface,
        child: const Icon(Icons.image_outlined, color: AppColors.primaryGreen, size: 40),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.backgroundWhite,
        child: Container(height: height, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: AppColors.primaryGreenSurface,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.primaryGreen),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final SchemeStatus status;

  Color get _color {
    switch (status) {
      case SchemeStatus.open:
        return AppColors.statusOpen;
      case SchemeStatus.closingSoon:
        return AppColors.statusClosingSoon;
      case SchemeStatus.ongoing:
        return AppColors.statusOngoing;
      case SchemeStatus.closed:
        return AppColors.statusClosed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: AppTextStyles.categoryTag.copyWith(fontSize: 9),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.category});
  final String category;

  Color get _color {
    switch (category.toLowerCase()) {
      case 'agriculture':
        return AppColors.catAgriculture;
      case 'education':
        return AppColors.catEducation;
      case 'healthcare':
        return AppColors.catHealthcare;
      case 'housing':
        return AppColors.catHousing;
      case 'women':
        return AppColors.catWomen;
      case 'environment':
        return AppColors.catEnvironment;
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        category.toUpperCase(),
        style: AppTextStyles.categoryTag.copyWith(color: _color, fontSize: 9),
      ),
    );
  }
}
