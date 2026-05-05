import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/scheme_model.dart';

/// Firestore service abstraction layer.
///
/// All database reads/writes go through this class to keep
/// Firestore SDK logic out of UI layers.
class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── User Collection ──────────────────────────────────────────────────

  /// Stream of the authenticated user's document.
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  /// Fetch user document once.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update user profile fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ── Schemes Collection ───────────────────────────────────────────────

  /// Stream of all schemes (for schemes list screen).
  Stream<List<SchemeModel>> streamSchemes({String? category}) {
    Query<Map<String, dynamic>> query = _db.collection('schemes');
    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(SchemeModel.fromFirestore).toList(),
        );
  }

  /// Stream of featured schemes for the home carousel.
  Stream<List<SchemeModel>> streamFeaturedSchemes() {
    return _db
        .collection('schemes')
        .where('featured', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map(SchemeModel.fromFirestore).toList());
  }

  /// Fetch a single scheme by ID.
  Future<SchemeModel?> getScheme(String id) async {
    final doc = await _db.collection('schemes').doc(id).get();
    if (!doc.exists) return null;
    return SchemeModel.fromFirestore(doc);
  }

  // ── Saved Schemes ────────────────────────────────────────────────────

  /// Stream of saved schemes for a user.
  Stream<List<SchemeModel>> streamSavedSchemes(String uid) {
    return _db
        .collection('saved_schemes')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      final futures = snap.docs.map((d) async {
        final schemeId = d['schemeId'] as String;
        return getScheme(schemeId);
      });
      final results = await Future.wait(futures);
      return results.whereType<SchemeModel>().toList();
    });
  }

  /// Save or unsave a scheme for a user.
  Future<void> toggleSaveScheme({
    required String uid,
    required String schemeId,
    required bool save,
  }) async {
    final ref = _db
        .collection('saved_schemes')
        .doc('${uid}_$schemeId');
    if (save) {
      await ref.set({
        'userId': uid,
        'schemeId': schemeId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('users').doc(uid).update({
        'savedSchemes': FieldValue.increment(1),
      });
    } else {
      await ref.delete();
      await _db.collection('users').doc(uid).update({
        'savedSchemes': FieldValue.increment(-1),
      });
    }
  }

  /// Check if a scheme is saved by user.
  Future<bool> isSchemesSaved(String uid, String schemeId) async {
    final doc = await _db
        .collection('saved_schemes')
        .doc('${uid}_$schemeId')
        .get();
    return doc.exists;
  }

  // ── Applications Collection ──────────────────────────────────────────

  /// Submit an application for a scheme.
  Future<void> applyToScheme({
    required String uid,
    required String schemeId,
    required String schemeTitle,
  }) async {
    await _db.collection('applications').add({
      'userId': uid,
      'schemeId': schemeId,
      'schemeTitle': schemeTitle,
      'status': 'submitted',
      'appliedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('users').doc(uid).update({
      'appliedSchemes': FieldValue.increment(1),
    });
  }

  /// Stream all applications for user (for profile history).
  Stream<List<Map<String, dynamic>>> streamApplications(String uid) {
    return _db
        .collection('applications')
        .where('userId', isEqualTo: uid)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Seed Data ────────────────────────────────────────────────────────

  /// Seeds sample Gujarat schemes into Firestore (call once during dev setup).
  Future<void> seedSampleSchemes() async {
    final schemes = [
      {
        'title': 'PM-Kisan Samman Nidhi',
        'description':
            'Direct income support of ₹6,000 per year to farmer families in three equal installments.',
        'benefitHighlight': '₹6,000/year',
        'category': 'agriculture',
        'imageUrl': 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=800',
        'featured': true,
        'status': 'open',
        'eligibilityNote': 'Landholding farmers',
        'maxIncome': 200000.0,
        'targetOccupations': ['farmer'],
      },
      {
        'title': 'Gujarat Digital Scholarship',
        'description':
            'Scholarship for students belonging to minority communities for pursuing higher education.',
        'benefitHighlight': 'Full Tuition Waiver',
        'category': 'education',
        'imageUrl': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800',
        'featured': true,
        'status': 'open',
        'eligibilityNote': 'Students in higher education',
        'maxIncome': 250000.0,
        'targetOccupations': ['student'],
      },
      {
        'title': 'Mukhyamantri Amrutam Yojana',
        'description':
            'Health insurance coverage of up to ₹5 Lakhs per family per year for secondary and tertiary care.',
        'benefitHighlight': '₹5 Lakh/Family',
        'category': 'healthcare',
        'imageUrl': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=800',
        'featured': true,
        'status': 'ongoing',
        'eligibilityNote': 'BPL families',
        'maxIncome': 150000.0,
        'targetOccupations': [],
      },
      {
        'title': 'PM Awas Yojana',
        'description':
            'Financial assistance for housing for urban poor and eligible families. Get subsidies on home loans.',
        'benefitHighlight': 'Subsidy on Home Loans',
        'category': 'housing',
        'imageUrl': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        'featured': false,
        'status': 'open',
        'eligibilityNote': 'Income + ₹6L/yr',
        'maxIncome': 600000.0,
        'targetOccupations': [],
      },
      {
        'title': 'Solar Rooftop Yojana',
        'description':
            'Financial assistance for installation of solar panels on residential rooftops to reduce electricity bills.',
        'benefitHighlight': '40% Subsidy',
        'category': 'environment',
        'imageUrl': 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=800',
        'featured': false,
        'status': 'open',
        'eligibilityNote': 'Residential property owners',
        'targetOccupations': [],
      },
    ];

    final batch = _db.batch();
    for (final scheme in schemes) {
      final ref = _db.collection('schemes').doc();
      batch.set(ref, scheme);
    }
    await batch.commit();
  }
}
