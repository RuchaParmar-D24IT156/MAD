import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/scheme_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/schemes_provider.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/scheme_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _carouselController = PageController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isEnglish = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  static const _categories = [
    _Category('All', Icons.grid_view_rounded, null),
    _Category('Agriculture', Icons.grass, 'agriculture'),
    _Category('Education', Icons.school_outlined, 'education'),
    _Category('Healthcare', Icons.local_hospital_outlined, 'healthcare'),
    _Category('Women', Icons.woman_outlined, 'women'),
    _Category('Environment', Icons.eco_outlined, 'environment'),
    _Category('Industry', Icons.factory_outlined, 'industry'),
    _Category('Skill Dev', Icons.work_outline, 'skill'),
    _Category('Social', Icons.people_outlined, 'social'),
    _Category('Tourism', Icons.tour_outlined, 'tourism'),
    _Category('Transport', Icons.directions_bus_outlined, 'transport'),
    _Category('Digital', Icons.computer_outlined, 'digital'),
  ];

  @override
  void dispose() {
    _carouselController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final featuredAsync = ref.watch(featuredSchemesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final schemesAsync = ref.watch(schemesProvider(selectedCat));

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.backgroundWhite,
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 70,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Schemes',
                  style: AppTextStyles.headlineMedium,
                ),
                Text(
                  'Find benefits for you',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            actions: [
              // Language toggle
              GestureDetector(
                onTap: () => setState(() => _isEnglish = !_isEnglish),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        _isEnglish ? 'English' : 'ગુજરાતી',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ),
              // Notifications
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                color: AppColors.textPrimary,
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──────────────────────────────────────────
                Container(
                  color: AppColors.backgroundWhite,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null)
                        Text(
                          'Welcome back, ${user.firstName} 👋',
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                        ),

                      const SizedBox(height: 12),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundBeige,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search for benefits, schemes...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.tune_rounded, color: AppColors.primaryGreen, size: 20),
                              onPressed: () {},
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── Category Chips ─────────────────────────────────────
                Container(
                  color: AppColors.backgroundWhite,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = selectedCat == cat.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              cat.icon,
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.primaryGreen,
                            ),
                            label: Text(
                              cat.label,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              ref.read(selectedCategoryProvider.notifier).state = cat.value;
                            },
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: AppColors.surfaceCard,
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryGreen : AppColors.border,
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 20),

                // ── Featured Carousel ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trending Now', style: AppTextStyles.headlineSmall),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.schemes),
                        child: const Text('View all →'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                featuredAsync.when(
                  data: (schemes) => schemes.isEmpty
                      ? _EmptyCarousel()
                      : _FeaturedCarousel(
                          schemes: schemes,
                          controller: _carouselController,
                        ),
                  loading: () => _CarouselShimmer(),
                  error: (_, __) => _EmptyCarousel(),
                ),

                const SizedBox(height: 24),

                // ── Recommended Section ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Recommended for You', style: AppTextStyles.headlineSmall),
                ),
                const SizedBox(height: 12),

                schemesAsync.when(
                  data: (schemes) {
                    var filteredSchemes = schemes;
                    if (_searchQuery.isNotEmpty) {
                      filteredSchemes = schemes.where((s) => 
                        s.title.toLowerCase().contains(_searchQuery) || 
                        s.description.toLowerCase().contains(_searchQuery)
                      ).toList();
                    }
                    if (filteredSchemes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('No schemes found matching your search.'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredSchemes.take(5).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final scheme = filteredSchemes[i];
                        final savedIds = ref.watch(savedSchemeIdsProvider).value ?? {};
                        final isSaved = savedIds.contains(scheme.id);
                        return SchemeCard(
                          scheme: scheme,
                          isSaved: isSaved,
                          onApply: () => context.push('/schemes/${scheme.id}'),
                          onSave: () => ref.read(schemeActionsProvider.notifier).toggleSave(scheme.id, !isSaved),
                        );
                      },
                    );
                  },
                  loading: () => _ListShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Carousel ──────────────────────────────────────────────────────

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.schemes, required this.controller});

  final List<SchemeModel> schemes;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: controller,
            itemCount: schemes.length,
            itemBuilder: (_, i) => _CarouselCard(scheme: schemes[i]),
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: controller,
          count: schemes.length,
          effect: const WormEffect(
            dotWidth: 6,
            dotHeight: 6,
            activeDotColor: AppColors.primaryGreen,
            dotColor: AppColors.divider,
          ),
        ),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.scheme});

  final SchemeModel scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Image
            SizedBox.expand(
              child: Builder(
                builder: (context) {
                  String? sectorImage;
                  switch (scheme.category.toLowerCase()) {
                    case 'agriculture': sectorImage = 'assets/images/sectors/img1_farmer_sector.jpg'; break;
                    case 'education': sectorImage = 'assets/images/sectors/img2_education_sector.webp'; break;
                    case 'digital': sectorImage = 'assets/images/sectors/img3_digitalGujrat_sector.png'; break;
                    case 'healthcare':
                    case 'health': sectorImage = 'assets/images/sectors/img4_health_sector.jpg'; break;
                  }
                  
                  if (scheme.imageUrl.isNotEmpty && scheme.imageUrl.startsWith('http')) {
                    return CachedNetworkImage(
                      imageUrl: scheme.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.primaryGreenSurface),
                      errorWidget: (_, __, ___) => Container(color: AppColors.primaryGreenSurface),
                    );
                  } else if (sectorImage != null) {
                    return Image.asset(sectorImage, fit: BoxFit.cover);
                  }
                  return Container(color: AppColors.primaryGreenSurface);
                },
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scheme.category.toUpperCase(),
                      style: AppTextStyles.categoryTag.copyWith(fontSize: 8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scheme.title,
                    style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheme.benefitHighlight,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Placeholders ───────────────────────────────────────────────────

class _CarouselShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.backgroundWhite,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _EmptyCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, color: AppColors.primaryGreen, size: 36),
            SizedBox(height: 8),
            Text('No featured schemes yet'),
          ],
        ),
      ),
    );
  }
}

class _ListShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.backgroundWhite,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── Category data ──────────────────────────────────────────────────────────

class _Category {
  const _Category(this.label, this.icon, this.value);
  final String label;
  final IconData icon;
  final String? value;
}
