import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/schemes_provider.dart';
import '../../../shared/widgets/scheme_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SchemesListScreen extends ConsumerStatefulWidget {
  const SchemesListScreen({super.key});

  @override
  ConsumerState<SchemesListScreen> createState() => _SchemesListScreenState();
}

class _SchemesListScreenState extends ConsumerState<SchemesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const _categories = [
    'All',
    'Agriculture',
    'Education',
    'Healthcare',
    'Women',
    'Environment',
    'Industry',
    'Skill Dev',
    'Social',
    'Tourism',
    'Transport',
    'Digital',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCat = ref.watch(selectedCategoryProvider);
    final schemesAsync = ref.watch(schemesProvider(selectedCat));

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search schemes...',
                  border: InputBorder.none,
                ),
              )
            : const Text('All Schemes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter row
          Container(
            color: AppColors.backgroundWhite,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: _categories.map((cat) {
                  final value = cat == 'All'
                      ? null
                      : const {
                          'Agriculture': 'agriculture',
                          'Education': 'education',
                          'Healthcare': 'healthcare',
                          'Women': 'women',
                          'Environment': 'environment',
                          'Industry': 'industry',
                          'Skill Dev': 'skill',
                          'Social': 'social',
                          'Tourism': 'tourism',
                          'Transport': 'transport',
                          'Digital': 'digital',
                        }[cat];
                  final isSelected = selectedCat == value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(selectedCategoryProvider.notifier).state = value;
                      },
                      selectedColor: AppColors.primaryGreen,
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.border),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: schemesAsync.when(
              data: (schemes) {
                var filteredSchemes = schemes;
                if (_searchQuery.isNotEmpty) {
                  filteredSchemes = schemes.where((s) => 
                    s.title.toLowerCase().contains(_searchQuery) || 
                    s.description.toLowerCase().contains(_searchQuery)
                  ).toList();
                }
                
                if (filteredSchemes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.article_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No schemes found', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSchemes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final scheme = filteredSchemes[i];
                    final savedIds = ref.watch(savedSchemeIdsProvider).value ?? {};
                    final isSaved = savedIds.contains(scheme.id);
                    return SchemeCard(
                      scheme: scheme,
                      showStatus: true,
                      isSaved: isSaved,
                      onApply: () => context.push('/schemes/${scheme.id}'),
                      onSave: () => ref.read(schemeActionsProvider.notifier).toggleSave(scheme.id, !isSaved),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
