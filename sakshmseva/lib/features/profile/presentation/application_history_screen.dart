import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/schemes_provider.dart';
import '../../../shared/widgets/scheme_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/models/scheme_model.dart';

class ApplicationHistoryScreen extends ConsumerWidget {
  const ApplicationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application History')),
        body: const Center(child: Text('Please login to see history')),
      );
    }

    final schemesAsync = ref.watch(schemesProvider(null));

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('Application History'),
      ),
      body: schemesAsync.when(
        data: (allSchemes) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('history')
                .orderBy('visitedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('No history found', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Browse schemes to see them here.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              final savedIds = ref.watch(savedSchemeIdsProvider).value ?? {};

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final historyDoc = docs[index];
                  final schemeId = historyDoc['schemeId'] as String;
                  
                  final SchemeModel foundScheme;
                  try {
                    foundScheme = allSchemes.firstWhere((s) => s.id == schemeId);
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                  
                  final isSaved = savedIds.contains(foundScheme.id);

                  return SchemeCard(
                    scheme: foundScheme,
                    isSaved: isSaved,
                    onApply: () => context.push('/schemes/${foundScheme.id}'),
                    onSave: () => ref.read(schemeActionsProvider.notifier).toggleSave(foundScheme.id, !isSaved),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
