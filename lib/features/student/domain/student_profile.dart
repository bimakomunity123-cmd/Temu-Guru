class StudentProfile {
  final String uid;
  final String fullName;
  final DateTime birthDate;
  final int age;
  final String whatsapp;
  final String email;
  final String address;
  final String preferredTeachingArea;
  final bool hasEnglishLearningExperience;
  final String preferredProgram;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StudentProfile({
    required this.uid,
    required this.fullName,
    required this.birthDate,
    required this.age,
    required this.whatsapp,
    required this.email,
    required this.address,
    required this.preferredTeachingArea,
    required this.hasEnglishLearningExperience,
    required this.preferredProgram,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'birthDate': birthDate.toIso8601String(),
      'age': age,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'preferredTeachingArea': preferredTeachingArea,
      'hasEnglishLearningExperience': hasEnglishLearningExperience,
      'preferredProgram': preferredProgram,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      birthDate: DateTime.tryParse(map['birthDate'] as String? ?? '') ?? DateTime.now(),
      age: map['age'] as int? ?? 0,
      whatsapp: map['whatsapp'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      preferredTeachingArea: map['preferredTeachingArea'] as String? ?? '',
      hasEnglishLearningExperience: map['hasEnglishLearningExperience'] as bool? ?? false,
      preferredProgram: map['preferredProgram'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'] as String) : null,
    );
  }

  StudentProfile copyWith({
    String? uid,
    String? fullName,
    DateTime? birthDate,
    int? age,
    String? whatsapp,
    String? email,
    String? address,
    String? preferredTeachingArea,
    bool? hasEnglishLearningExperience,
    String? preferredProgram,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      preferredTeachingArea: preferredTeachingArea ?? this.preferredTeachingArea,
      hasEnglishLearningExperience: hasEnglishLearningExperience ?? this.hasEnglishLearningExperience,
      preferredProgram: preferredProgram ?? this.preferredProgram,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
