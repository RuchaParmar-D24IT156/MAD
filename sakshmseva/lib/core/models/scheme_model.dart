import 'package:cloud_firestore/cloud_firestore.dart';

/// Scheme status in the system
enum SchemeStatus { open, closingSoon, ongoing, closed }

/// Category for each scheme
enum SchemeCategory {
  agriculture,
  education,
  healthcare,
  housing,
  women,
  environment,
  industry,
  skill,
  social,
  tourism,
  transport,
  digital,
  general,
}

/// Represents a government scheme from the sgp CSV data (or Firestore)
class SchemeModel {
  final String id;
  final String title;
  final String description;
  final String benefitHighlight;
  final String category;
  final String imageUrl;
  final bool featured;
  final SchemeStatus status;
  final DateTime? closingDate;
  final String? eligibilityNote;
  final int? minAge;
  final int? maxAge;
  final double? maxIncome;
  final List<String> targetOccupations;

  // ── Fields from sgp CSV ───────────────────────────────────────────────────
  /// Services provided by the scheme
  final String services;

  /// Documents required to apply
  final String documentsNeeded;

  /// Apply link
  final String applyLink;

  const SchemeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.benefitHighlight,
    required this.category,
    required this.imageUrl,
    this.featured = false,
    this.status = SchemeStatus.open,
    this.closingDate,
    this.eligibilityNote,
    this.minAge,
    this.maxAge,
    this.maxIncome,
    this.targetOccupations = const [],
    this.services = '',
    this.documentsNeeded = '',
    this.applyLink = '',
  });

  // ── JSON factory (from sgp API /schemes) ─────────────────────────────────

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = (json['category'] as String? ?? '').toLowerCase();
    final schemeName = (json['scheme_name'] as String? ?? '').trim();
    final description = (json['description'] as String? ?? '').trim();
    final services = (json['services'] as String? ?? '').trim();
    final documentsNeeded = (json['documents_needed'] as String? ?? '').trim();
    final rawStatus = (json['status'] as String? ?? '').toLowerCase();

    // Derive a short display category key from the verbose CSV filename string
    final categoryKey = _mapCategory(rawCategory);

    // Use services as a benefit highlight if non-empty, else truncate description
    final benefit = services.isNotEmpty
        ? (services.length > 60 ? '${services.substring(0, 57)}…' : services)
        : (description.length > 60
            ? '${description.substring(0, 57)}…'
            : description);

    // Derive a stable id from scheme name
    final id = schemeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    return SchemeModel(
      id: id,
      title: schemeName,
      description: description,
      benefitHighlight: benefit,
      category: categoryKey,
      imageUrl: '',
      featured: false,
      status: _parseStatusStr(rawStatus),
      services: services,
      documentsNeeded: documentsNeeded,
      eligibilityNote: documentsNeeded.isNotEmpty ? documentsNeeded : 'Check details for eligibility',
      applyLink: _parseStatusStr(rawStatus) == SchemeStatus.open ? 'https://digitalgujarat.gov.in/' : '',
    );
  }

  // ── Firestore factory (existing – unchanged) ──────────────────────────────

  factory SchemeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchemeModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      benefitHighlight: data['benefitHighlight'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      imageUrl: data['imageUrl'] as String? ?? '',
      featured: data['featured'] as bool? ?? false,
      status: _parseStatus(data['status'] as String?),
      closingDate: (data['closingDate'] as Timestamp?)?.toDate(),
      eligibilityNote: data['eligibilityNote'] as String?,
      minAge: data['minAge'] as int?,
      maxAge: data['maxAge'] as int?,
      maxIncome: (data['maxIncome'] as num?)?.toDouble(),
      targetOccupations: List<String>.from(data['targetOccupations'] ?? []),
      services: data['services'] as String? ?? '',
      documentsNeeded: data['documentsNeeded'] as String? ?? '',
      applyLink: data['applyLink'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'benefitHighlight': benefitHighlight,
        'category': category,
        'imageUrl': imageUrl,
        'featured': featured,
        'status': status.name,
        'closingDate':
            closingDate != null ? Timestamp.fromDate(closingDate!) : null,
        'eligibilityNote': eligibilityNote,
        'minAge': minAge,
        'maxAge': maxAge,
        'maxIncome': maxIncome,
        'targetOccupations': targetOccupations,
        'services': services,
        'documentsNeeded': documentsNeeded,
        'applyLink': applyLink,
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _mapCategory(String raw) {
    if (raw.contains('agriculture') || raw.contains('farmer')) {
      return 'agriculture';
    } else if (raw.contains('education')) {
      return 'education';
    } else if (raw.contains('health')) {
      return 'healthcare';
    } else if (raw.contains('women') || raw.contains('child')) {
      return 'women';
    } else if (raw.contains('environment') || raw.contains('energy')) {
      return 'environment';
    } else if (raw.contains('industry') || raw.contains('msme')) {
      return 'industry';
    } else if (raw.contains('skill') || raw.contains('employment')) {
      return 'skill';
    } else if (raw.contains('social') || raw.contains('justice')) {
      return 'social';
    } else if (raw.contains('tourism') || raw.contains('culture')) {
      return 'tourism';
    } else if (raw.contains('transport') || raw.contains('infrastructure')) {
      return 'transport';
    } else if (raw.contains('digital') || raw.contains('governance')) {
      return 'digital';
    }
    return 'general';
  }

  static SchemeStatus _parseStatusStr(String s) {
    if (s.contains('offline')) return SchemeStatus.ongoing;
    if (s.contains('online')) return SchemeStatus.open;
    if (s.contains('hybrid')) return SchemeStatus.open;
    if (s.contains('closed')) return SchemeStatus.closed;
    return SchemeStatus.open;
  }

  static SchemeStatus _parseStatus(String? s) {
    switch (s) {
      case 'closingSoon':
        return SchemeStatus.closingSoon;
      case 'ongoing':
        return SchemeStatus.ongoing;
      case 'closed':
        return SchemeStatus.closed;
      default:
        return SchemeStatus.open;
    }
  }

  /// Human-readable status label
  String get statusLabel {
    switch (status) {
      case SchemeStatus.open:
        return 'OPEN';
      case SchemeStatus.closingSoon:
        return 'CLOSING SOON';
      case SchemeStatus.ongoing:
        return 'ONGOING';
      case SchemeStatus.closed:
        return 'CLOSED';
    }
  }
}
