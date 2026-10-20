import 'package:cloud_firestore/cloud_firestore.dart';

class LessonReview {
  final String reviewId;
  final String lessonSessionId;
  final String studentUid;
  final String studentName;
  final String teacherUid;
  final String teacherName;
  final int rating; // 1 to 5
  final String impression; // Mandatory
  final String? messageAndExpectation; // Optional
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String moderationStatus; // 'published' | 'pending' | 'flagged'

  const LessonReview({
    required this.reviewId,
    required this.lessonSessionId,
    required this.studentUid,
    required this.studentName,
    required this.teacherUid,
    required this.teacherName,
    required this.rating,
    required this.impression,
    this.messageAndExpectation,
    required this.createdAt,
    this.updatedAt,
    this.moderationStatus = 'published',
  });

  /// Anonymized student display name for public review lists
  /// E.g. "Ahmad Faiz Pratama" -> "Ahmad F."
  String get publicStudentName {
    final trimmed = studentName.trim();
    if (trimmed.isEmpty) return 'Siswa Temu Guru';
    final parts = trimmed.split(' ');
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts[1][0]}.';
  }

  bool get isEdited => updatedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'lessonSessionId': lessonSessionId,
      'studentUid': studentUid,
      'studentName': studentName,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'rating': rating,
      'impression': impression,
      'messageAndExpectation': messageAndExpectation,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'moderationStatus': moderationStatus,
    };
  }

  factory LessonReview.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return LessonReview(
      reviewId: map['reviewId'] as String? ?? id ?? '',
      lessonSessionId: map['lessonSessionId'] as String? ?? '',
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Siswa',
      teacherUid: map['teacherUid'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? 'Guru Pengajar',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      impression: map['impression'] as String? ?? '',
      messageAndExpectation: map['messageAndExpectation'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseNullableDate(map['updatedAt']),
      moderationStatus: map['moderationStatus'] as String? ?? 'published',
    );
  }

  LessonReview copyWith({
    String? reviewId,
    String? lessonSessionId,
    String? studentUid,
    String? studentName,
    String? teacherUid,
    String? teacherName,
    int? rating,
    String? impression,
    String? messageAndExpectation,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? moderationStatus,
  }) {
    return LessonReview(
      reviewId: reviewId ?? this.reviewId,
      lessonSessionId: lessonSessionId ?? this.lessonSessionId,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      rating: rating ?? this.rating,
      impression: impression ?? this.impression,
      messageAndExpectation: messageAndExpectation ?? this.messageAndExpectation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderationStatus: moderationStatus ?? this.moderationStatus,
    );
  }
}
