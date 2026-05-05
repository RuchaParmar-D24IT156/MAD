import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/schemes_provider.dart';
import '../../../core/models/scheme_model.dart';
import '../../../shared/widgets/scheme_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SavedSchemesScreen extends ConsumerStatefulWidget {
  const SavedSchemesScreen({super.key});

  @override
  ConsumerState<SavedSchemesScreen> createState() => _SavedSchemesScreenState();
}

class _SavedSchemesScreenState extends ConsumerState<SavedSchemesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['All Saved', 'Health', 'Agriculture', 'Education', 'Women'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<SchemeModel> _filterSchemes(List<SchemeModel> all, int tabIndex) {
    if (tabIndex == 0) return all;
    final cat = const {
      'Health': 'healthcare',
      'Agriculture': 'agriculture',
      'Education': 'education',
      'Women': 'women',
    }[_tabs[tabIndex]];
    if (cat == null) return all;
    return all.where((s) => s.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    // savedSchemesProvider is now a Provider<AsyncValue<List<SchemeModel>>>
    final savedAsync = ref.watch(savedSchemesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('My Saved Schemes'),
        leading: const BackButton(color: AppColors.primaryGreen),
        actions: [
          IconButton(icon: const Icon(Icons.search_outlined), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelMedium,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: savedAsync.when(
        data: (allSaved) => allSaved.isEmpty
            ? _EmptyState()
            : TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (i) {
                  final filtered = _filterSchemes(allSaved, i);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_border, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No saved schemes in this category', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, index) {
                      final scheme = filtered[index];
                      return SchemeCardWithImage(
                        scheme: scheme,
                        onApply: () => context.push('/schemes/${scheme.id}'),
                        onSave: () {
                          ref.read(schemeActionsProvider.notifier).toggleSave(scheme.id, false);
                        },
                      );
                    },
                  );
                }),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No saved schemes yet', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Browse schemes and tap "Save" to bookmark them here.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
