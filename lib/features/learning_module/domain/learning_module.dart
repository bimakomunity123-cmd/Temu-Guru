import 'package:cloud_firestore/cloud_firestore.dart';

class LearningModule {
  final String moduleId;
  final String title;
  final String description;
  final String category; // 'Grammar' | 'Vocabulary' | 'Speaking' | 'Exam Preparation'
  final String version;
  final String pdfUrl;
  final int fileSizeBytes;
  final int totalPages;
  final DateTime updatedAt;
  final bool isPublished;
  final bool isFlagship;

  const LearningModule({
    required this.moduleId,
    required this.title,
    required this.description,
    required this.category,
    required this.version,
    required this.pdfUrl,
    required this.fileSizeBytes,
    required this.totalPages,
    required this.updatedAt,
    this.isPublished = true,
    this.isFlagship = false,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'moduleId': moduleId,
      'title': title,
      'description': description,
      'category': category,
      'version': version,
      'pdfUrl': pdfUrl,
      'fileSizeBytes': fileSizeBytes,
      'totalPages': totalPages,
      'updatedAt': updatedAt.toIso8601String(),
      'isPublished': isPublished,
      'isFlagship': isFlagship,
    };
  }

  factory LearningModule.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return LearningModule(
      moduleId: map['moduleId'] as String? ?? id ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Umum',
      version: map['version'] as String? ?? 'v1.0',
      pdfUrl: map['pdfUrl'] as String? ?? '',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 1,
      updatedAt: parseDate(map['updatedAt']),
      isPublished: map['isPublished'] as bool? ?? true,
      isFlagship: map['isFlagship'] as bool? ?? false,
    );
  }

  LearningModule copyWith({
    String? moduleId,
    String? title,
    String? description,
    String? category,
    String? version,
    String? pdfUrl,
    int? fileSizeBytes,
    int? totalPages,
    DateTime? updatedAt,
    bool? isPublished,
    bool? isFlagship,
  }) {
    return LearningModule(
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      version: version ?? this.version,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      totalPages: totalPages ?? this.totalPages,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      isFlagship: isFlagship ?? this.isFlagship,
    );
  }
}
