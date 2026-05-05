/// Represents a Gujarat citizen user.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? aadhaarNumber; // masked for display
  final int? age;
  final String? photoUrl;
  final bool aadhaarVerified;
  final int appliedSchemes;
  final int savedSchemes;
  final int eligibilityScore;
  final String preferredLanguage;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.aadhaarNumber,
    this.age,
    this.photoUrl,
    this.aadhaarVerified = false,
    this.appliedSchemes = 0,
    this.savedSchemes = 0,
    this.eligibilityScore = 0,
    this.preferredLanguage = 'en',
    this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? aadhaarNumber,
    int? age,
    String? photoUrl,
    bool? aadhaarVerified,
    int? appliedSchemes,
    int? savedSchemes,
    int? eligibilityScore,
    String? preferredLanguage,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      aadhaarVerified: aadhaarVerified ?? this.aadhaarVerified,
      appliedSchemes: appliedSchemes ?? this.appliedSchemes,
      savedSchemes: savedSchemes ?? this.savedSchemes,
      eligibilityScore: eligibilityScore ?? this.eligibilityScore,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt,
    );
  }

  /// Returns masked Aadhaar: XXXX-XXXX-5678
  String get maskedAadhaar {
    if (aadhaarNumber == null || aadhaarNumber!.length < 4) return 'XXXX-XXXX-XXXX';
    final last4 = aadhaarNumber!.substring(aadhaarNumber!.length - 4);
    return 'XXXX-XXXX-$last4';
  }

  /// Returns first name for greeting
  String get firstName => name.split(' ').first;

  factory UserModel.fromFirestore(Map<String, dynamic> json, String id) {
    return UserModel(
      uid: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      aadhaarNumber: json['aadhaar'] as String? ?? json['aadhaarNumber'] as String?,
      age: json['age'] as int?,
      photoUrl: json['photoUrl'] as String?,
      aadhaarVerified: json['aadhaarVerified'] as bool? ?? false,
      appliedSchemes: json['appliedSchemes'] as int? ?? 0,
      savedSchemes: json['savedSchemes'] as int? ?? 0,
      eligibilityScore: json['eligibilityScore'] as int? ?? 0,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'aadhaar': aadhaarNumber,
      'aadhaarNumber': aadhaarNumber,
      'age': age,
      'photoUrl': photoUrl,
      'aadhaarVerified': aadhaarVerified,
      'appliedSchemes': appliedSchemes,
      'savedSchemes': savedSchemes,
      'eligibilityScore': eligibilityScore,
      'preferredLanguage': preferredLanguage,
    };
  }
}
