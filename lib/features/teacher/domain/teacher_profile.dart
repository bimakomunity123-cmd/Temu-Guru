class TeacherProfile {
  final String uid;
  final String fullName;
  final String nik;
  final DateTime birthDate;
  final int age;
  final String whatsapp;
  final String email;
  final String education; // D3, S1, S2, S3
  final String educationBackground; // Major / Jurusan
  final String englishLevel; // B2, C1, C2
  final String englishTestDocumentPath;
  final String englishTestDocumentName;
  final int englishTestDocumentSizeBytes;
  final String address;
  final List<String> availableTeachingAreas;
  final String applicationStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TeacherProfile({
    required this.uid,
    required this.fullName,
    required this.nik,
    required this.birthDate,
    required this.age,
    required this.whatsapp,
    required this.email,
    required this.education,
    required this.educationBackground,
    required this.englishLevel,
    required this.englishTestDocumentPath,
    required this.englishTestDocumentName,
    required this.englishTestDocumentSizeBytes,
    required this.address,
    required this.availableTeachingAreas,
    this.applicationStatus = 'pending',
    this.rejectionReason,
    this.reviewedAt,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => applicationStatus == 'pending';
  bool get isApproved => applicationStatus == 'approved';
  bool get isRejected => applicationStatus == 'rejected';

  String get formattedDocumentSize {
    if (englishTestDocumentSizeBytes <= 0) return '0 KB';
    final kb = englishTestDocumentSizeBytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'nik': nik,
      'birthDate': birthDate.toIso8601String(),
      'age': age,
      'whatsapp': whatsapp,
      'email': email,
      'education': education,
      'educationBackground': educationBackground,
      'englishLevel': englishLevel,
      'englishTestDocumentPath': englishTestDocumentPath,
      'englishTestDocumentName': englishTestDocumentName,
      'englishTestDocumentSizeBytes': englishTestDocumentSizeBytes,
      'address': address,
      'availableTeachingAreas': availableTeachingAreas,
      'applicationStatus': applicationStatus,
      'rejectionReason': rejectionReason,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TeacherProfile.fromMap(Map<String, dynamic> map) {
    return TeacherProfile(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      nik: map['nik'] as String? ?? '',
      birthDate: DateTime.tryParse(map['birthDate'] as String? ?? '') ?? DateTime.now(),
      age: map['age'] as int? ?? 0,
      whatsapp: map['whatsapp'] as String? ?? '',
      email: map['email'] as String? ?? '',
      education: map['education'] as String? ?? '',
      educationBackground: map['educationBackground'] as String? ?? '',
      englishLevel: map['englishLevel'] as String? ?? '',
      englishTestDocumentPath: map['englishTestDocumentPath'] as String? ?? '',
      englishTestDocumentName: map['englishTestDocumentName'] as String? ?? '',
      englishTestDocumentSizeBytes: map['englishTestDocumentSizeBytes'] as int? ?? 0,
      address: map['address'] as String? ?? '',
      availableTeachingAreas: List<String>.from(map['availableTeachingAreas'] as List? ?? []),
      applicationStatus: map['applicationStatus'] as String? ?? 'pending',
      rejectionReason: map['rejectionReason'] as String?,
      reviewedAt: map['reviewedAt'] != null ? DateTime.tryParse(map['reviewedAt'] as String) : null,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'] as String) : null,
    );
  }

  TeacherProfile copyWith({
    String? uid,
    String? fullName,
    String? nik,
    DateTime? birthDate,
    int? age,
    String? whatsapp,
    String? email,
    String? education,
    String? educationBackground,
    String? englishLevel,
    String? englishTestDocumentPath,
    String? englishTestDocumentName,
    int? englishTestDocumentSizeBytes,
    String? address,
    List<String>? availableTeachingAreas,
    String? applicationStatus,
    String? rejectionReason,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      nik: nik ?? this.nik,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      education: education ?? this.education,
      educationBackground: educationBackground ?? this.educationBackground,
      englishLevel: englishLevel ?? this.englishLevel,
      englishTestDocumentPath: englishTestDocumentPath ?? this.englishTestDocumentPath,
      englishTestDocumentName: englishTestDocumentName ?? this.englishTestDocumentName,
      englishTestDocumentSizeBytes: englishTestDocumentSizeBytes ?? this.englishTestDocumentSizeBytes,
      address: address ?? this.address,
      availableTeachingAreas: availableTeachingAreas ?? this.availableTeachingAreas,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
