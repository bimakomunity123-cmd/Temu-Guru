import 'package:cloud_firestore/cloud_firestore.dart';

class TeachingMaterial {
  final String materialId;
  final String title;
  final String level;
  final int meetingNumber;
  final String materialType; // 'petunjuk_ajar' | 'materi_presentasi' | 'panduan_lengkap'
  final String externalUrl;
  final DateTime updatedAt;
  final bool isPublished;
  final String? description;

  const TeachingMaterial({
    required this.materialId,
    required this.title,
    required this.level,
    required this.meetingNumber,
    required this.materialType,
    required this.externalUrl,
    required this.updatedAt,
    this.isPublished = true,
    this.description,
  });

  bool get isGoogleDriveLink {
    final lower = externalUrl.toLowerCase();
    return lower.contains('drive.google.com') ||
        lower.contains('docs.google.com');
  }

  String get typeLabel {
    switch (materialType) {
      case 'petunjuk_ajar':
        return 'Petunjuk Ajar Guru (Teaching Guide)';
      case 'materi_presentasi':
        return 'Materi Presentasi (Slides Deck)';
      case 'panduan_lengkap':
        return 'Modul & Panduan Lengkap';
      default:
        return 'Bahan Ajar';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'title': title,
      'level': level,
      'meetingNumber': meetingNumber,
      'materialType': materialType,
      'externalUrl': externalUrl,
      'updatedAt': updatedAt.toIso8601String(),
      'isPublished': isPublished,
      'description': description,
    };
  }

  factory TeachingMaterial.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TeachingMaterial(
      materialId: map['materialId'] as String? ?? id ?? '',
      title: map['title'] as String? ?? '',
      level: map['level'] as String? ?? 'General English',
      meetingNumber: (map['meetingNumber'] as num?)?.toInt() ?? 1,
      materialType: map['materialType'] as String? ?? 'petunjuk_ajar',
      externalUrl: map['externalUrl'] as String? ?? '',
      updatedAt: parseDate(map['updatedAt']),
      isPublished: map['isPublished'] as bool? ?? true,
      description: map['description'] as String?,
    );
  }

  TeachingMaterial copyWith({
    String? materialId,
    String? title,
    String? level,
    int? meetingNumber,
    String? materialType,
    String? externalUrl,
    DateTime? updatedAt,
    bool? isPublished,
    String? description,
  }) {
    return TeachingMaterial(
      materialId: materialId ?? this.materialId,
      title: title ?? this.title,
      level: level ?? this.level,
      meetingNumber: meetingNumber ?? this.meetingNumber,
      materialType: materialType ?? this.materialType,
      externalUrl: externalUrl ?? this.externalUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      description: description ?? this.description,
    );
  }
}
