import 'package:cloud_firestore/cloud_firestore.dart';

class LessonReport {
  final String reportId;
  final String teacherUid;
  final String teacherName;
  final String studentUid;
  final String studentName;
  final DateTime lessonDate;
  final String meetingLocation;
  final String startTime;
  final String endTime;
  final int meetingNumber;
  final String materialsCovered;
  final String sessionComments;
  final String? additionalNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LessonReport({
    required this.reportId,
    required this.teacherUid,
    required this.teacherName,
    required this.studentUid,
    required this.studentName,
    required this.lessonDate,
    required this.meetingLocation,
    required this.startTime,
    required this.endTime,
    required this.meetingNumber,
    required this.materialsCovered,
    required this.sessionComments,
    this.additionalNotes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'studentUid': studentUid,
      'studentName': studentName,
      'lessonDate': lessonDate.toIso8601String(),
      'meetingLocation': meetingLocation,
      'startTime': startTime,
      'endTime': endTime,
      'meetingNumber': meetingNumber,
      'materialsCovered': materialsCovered,
      'sessionComments': sessionComments,
      'additionalNotes': additionalNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LessonReport.fromMap(Map<String, dynamic> map, [String? id]) {
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

    return LessonReport(
      reportId: map['reportId'] as String? ?? id ?? '',
      teacherUid: map['teacherUid'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? 'Guru Pengajar',
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Siswa',
      lessonDate: parseDate(map['lessonDate']),
      meetingLocation: map['meetingLocation'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      meetingNumber: map['meetingNumber'] as int? ?? 1,
      materialsCovered: map['materialsCovered'] as String? ?? '',
      sessionComments: map['sessionComments'] as String? ?? '',
      additionalNotes: map['additionalNotes'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseNullableDate(map['updatedAt']),
    );
  }

  LessonReport copyWith({
    String? reportId,
    String? teacherUid,
    String? teacherName,
    String? studentUid,
    String? studentName,
    DateTime? lessonDate,
    String? meetingLocation,
    String? startTime,
    String? endTime,
    int? meetingNumber,
    String? materialsCovered,
    String? sessionComments,
    String? additionalNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonReport(
      reportId: reportId ?? this.reportId,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      lessonDate: lessonDate ?? this.lessonDate,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      meetingNumber: meetingNumber ?? this.meetingNumber,
      materialsCovered: materialsCovered ?? this.materialsCovered,
      sessionComments: sessionComments ?? this.sessionComments,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
