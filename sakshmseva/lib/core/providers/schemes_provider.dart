import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';
import '../models/scheme_model.dart';
import '../services/scheme_api_service.dart';

// ── API service provider ──────────────────────────────────────────────────────

final schemeApiServiceProvider = Provider<SchemeApiService>(
  (_) => SchemeApiService(),
);

// ── All schemes (fetched from sgp API) ───────────────────────────────────────

/// Fetches all schemes from the sgp Python backend.
/// The sgp server reads the 11 CSV files in sgp/files/ and returns them as JSON.
final allSchemesProvider = FutureProvider<List<SchemeModel>>((ref) async {
  final api = ref.read(schemeApiServiceProvider);
  return api.fetchSchemes();
});

// ── Filtered by category ──────────────────────────────────────────────────────

/// Schemes filtered by category. Pass null to get all schemes.
final schemesProvider =
    Provider.family<AsyncValue<List<SchemeModel>>, String?>((ref, category) {
  final allAsync = ref.watch(allSchemesProvider);
  return allAsync.whenData((all) {
    if (category == null || category.isEmpty) return all;
    return all.where((s) => s.category == category).toList();
  });
});

// ── Featured schemes (one per category, for home carousel) ───────────────────

final featuredSchemesProvider = Provider<AsyncValue<List<SchemeModel>>>((ref) {
  final allAsync = ref.watch(allSchemesProvider);
  return allAsync.whenData((all) {
    // Pick first scheme from each category to represent it in the carousel
    final seen = <String>{};
    final featured = <SchemeModel>[];
    for (final s in all) {
      if (!seen.contains(s.category)) {
        seen.add(s.category);
        featured.add(s);
      }
      if (featured.length >= 11) break; // one per category max
    }
    return featured;
  });
});

// ── Selected category ─────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ── Saved schemes (Firestore) ────────────────────────────────────

final savedSchemeIdsProvider = StreamProvider<Set<String>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value({});
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedSchemes')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
    },
    loading: () => Stream.value({}),
    error: (_, __) => Stream.value({}),
  );
});

final savedSchemesProvider = Provider<AsyncValue<List<SchemeModel>>>((ref) {
  final allAsync = ref.watch(allSchemesProvider);
  final savedIdsAsync = ref.watch(savedSchemeIdsProvider);
  
  if (allAsync.isLoading || savedIdsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (allAsync.hasError) return AsyncValue.error(allAsync.error!, allAsync.stackTrace!);
  if (savedIdsAsync.hasError) return AsyncValue.error(savedIdsAsync.error!, savedIdsAsync.stackTrace!);

  final all = allAsync.value ?? [];
  final savedIds = savedIdsAsync.value ?? {};
  
  return AsyncValue.data(all.where((s) => savedIds.contains(s.id)).toList());
});

// ── Scheme actions ────────────────────────────────────────────────────────────

class SchemeActionsNotifier extends StateNotifier<AsyncValue<void>> {
  SchemeActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> toggleSave(String schemeId, bool save) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider).value;
      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedSchemes')
            .doc(schemeId);
        
        if (save) {
          await docRef.set({'savedAt': FieldValue.serverTimestamp()});
        } else {
          await docRef.delete();
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> applyToScheme(String schemeId, String schemeTitle) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 1));
    state = const AsyncValue.data(null);
  }
}

final schemeActionsProvider =
    StateNotifierProvider<SchemeActionsNotifier, AsyncValue<void>>((ref) {
  return SchemeActionsNotifier(ref);
});
