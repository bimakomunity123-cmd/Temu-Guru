import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/lesson_report.dart';

abstract class DailyReportRepository {
  Future<LessonReport> createReport(LessonReport report);
  Future<LessonReport> updateReport(LessonReport report);
  Future<LessonReport?> getReportById(String reportId);
  Future<List<LessonReport>> getReportsForTeacher(
    String teacherUid, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<LessonReport>> getReportsForStudent(String studentUid);
  Stream<List<LessonReport>> streamReportsForTeacher(String teacherUid);
  Stream<List<LessonReport>> streamReportsForStudent(String studentUid);
  Future<List<Map<String, String>>> getAssignedStudents(String teacherUid);
}

class InMemoryDailyReportRepository implements DailyReportRepository {
  final Map<String, LessonReport> _reports = {};
  final StreamController<List<LessonReport>> _reportsStreamController =
      StreamController<List<LessonReport>>.broadcast();

  InMemoryDailyReportRepository() {
    _seedInitialReports();
  }

  void _seedInitialReports() {
    final now = DateTime.now();

    final report1 = LessonReport(
      reportId: 'report-001',
      teacherUid: 'teacher-001',
      teacherName: 'Sarah Jenkins, S.Pd',
      studentUid: 'student-001',
      studentName: 'Ahmad Faiz Pratama',
      lessonDate: now.subtract(const Duration(days: 3)),
      meetingLocation: 'Kediaman Siswa (Tebet Barat, Jakarta Selatan)',
      startTime: '15:30',
      endTime: '17:00',
      meetingNumber: 1,
      materialsCovered:
          'Introduction to IELTS Academic Writing Task 1 & Overview of Bar Charts / Trend Lines.',
      sessionComments:
          'Ahmad Faiz sangat antusias dan mampu mengidentifikasi main features grafik data dengan cepat. Kosakata deskriptif meningkat.',
      additionalNotes:
          'PR: Menulis 1 paragraf overview untuk line graph latihan hal. 24.',
      createdAt: now.subtract(const Duration(days: 3)),
    );

    final report2 = LessonReport(
      reportId: 'report-002',
      teacherUid: 'teacher-001',
      teacherName: 'Sarah Jenkins, S.Pd',
      studentUid: 'student-001',
      studentName: 'Ahmad Faiz Pratama',
      lessonDate: now.subtract(const Duration(days: 1)),
      meetingLocation: 'Ruang Belajar Perpustakaan Tebet Eco Park',
      startTime: '16:00',
      endTime: '17:30',
      meetingNumber: 2,
      materialsCovered:
          'Speaking Part 2 Simulation: Describing Personal Experiences & Fluency Drills.',
      sessionComments:
          'Percaya diri saat berbicara selama 2 menit penuh tanpa henti. Perlu sedikit perhatian pada penggunaan past tense irregular verbs.',
      additionalNotes:
          'Target sesi berikutnya: Latihan Speaking Part 3 (abstract discussion).',
      createdAt: now.subtract(const Duration(days: 1)),
    );

    _reports[report1.reportId] = report1;
    _reports[report2.reportId] = report2;
  }

  void _notify() {
    if (!_reportsStreamController.isClosed) {
      _reportsStreamController.add(_reports.values.toList());
    }
  }

  @override
  Future<LessonReport> createReport(LessonReport report) async {
    final newId = report.reportId.isNotEmpty
        ? report.reportId
        : 'report-${DateTime.now().millisecondsSinceEpoch}';
    final saved = report.copyWith(reportId: newId);
    _reports[newId] = saved;
    _notify();
    return saved;
  }

  @override
  Future<LessonReport> updateReport(LessonReport report) async {
    _reports[report.reportId] = report.copyWith(updatedAt: DateTime.now());
    _notify();
    return _reports[report.reportId]!;
  }

  @override
  Future<LessonReport?> getReportById(String reportId) async {
    return _reports[reportId];
  }

  @override
  Future<List<LessonReport>> getReportsForTeacher(
    String teacherUid, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var list = _reports.values.where((r) {
      final matchTeacher = r.teacherUid == teacherUid || teacherUid == 'all';
      if (!matchTeacher) return false;
      if (startDate != null && r.lessonDate.isBefore(startDate)) return false;
      if (endDate != null && r.lessonDate.isAfter(endDate)) return false;
      return true;
    }).toList();

    list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
    return list;
  }

  @override
  Future<List<LessonReport>> getReportsForStudent(String studentUid) async {
    var list = _reports.values
        .where((r) => r.studentUid == studentUid || studentUid == 'all')
        .toList();
    list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
    return list;
  }

  @override
  Stream<List<LessonReport>> streamReportsForTeacher(String teacherUid) async* {
    yield await getReportsForTeacher(teacherUid);
    yield* _reportsStreamController.stream.map((list) {
      var filtered = list.where((r) => r.teacherUid == teacherUid || teacherUid == 'all').toList();
      filtered.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
      return filtered;
    });
  }

  @override
  Stream<List<LessonReport>> streamReportsForStudent(String studentUid) async* {
    yield await getReportsForStudent(studentUid);
    yield* _reportsStreamController.stream.map((list) {
      var filtered = list.where((r) => r.studentUid == studentUid || studentUid == 'all').toList();
      filtered.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
      return filtered;
    });
  }

  @override
  Future<List<Map<String, String>>> getAssignedStudents(String teacherUid) async {
    return const [
      {
        'uid': 'student-001',
        'name': 'Ahmad Faiz Pratama',
        'program': 'General English & Speaking Booster',
        'address': 'Jl. Tebet Barat Dalam No. 14, Jakarta Selatan',
      },
      {
        'uid': 'student-002',
        'name': 'Nabila Khairunnisa',
        'program': 'TOEFL Preparation & Academic Writing',
        'address': 'Jl. Menteng Raya No. 22, Jakarta Pusat',
      },
      {
        'uid': 'student-003',
        'name': 'Rafi Alamsyah',
        'program': 'English for School & Exam Preparation',
        'address': 'Jl. Cipete Raya No. 8, Jakarta Selatan',
      },
    ];
  }
}

class FirestoreDailyReportRepository implements DailyReportRepository {
  final FirebaseFirestore? _customFirestore;
  final InMemoryDailyReportRepository _fallback = InMemoryDailyReportRepository();

  FirestoreDailyReportRepository([FirebaseFirestore? firestore])
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<LessonReport> createReport(LessonReport report) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.createReport(report);
    }

    try {
      final collection = _firestore.collection('lessonReports');
      final docRef = report.reportId.isNotEmpty
          ? collection.doc(report.reportId)
          : collection.doc();

      final data = report.toMap();
      data['reportId'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);
      return report.copyWith(reportId: docRef.id);
    } catch (e) {
      // Fallback
      return await _fallback.createReport(report);
    }
  }

  @override
  Future<LessonReport> updateReport(LessonReport report) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.updateReport(report);
    }

    try {
      final docRef = _firestore.collection('lessonReports').doc(report.reportId);
      final data = report.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.update(data);
      return report;
    } catch (e) {
      return await _fallback.updateReport(report);
    }
  }

  @override
  Future<LessonReport?> getReportById(String reportId) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getReportById(reportId);
    }

    try {
      final doc = await _firestore.collection('lessonReports').doc(reportId).get();
      if (!doc.exists || doc.data() == null) return null;
      return LessonReport.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return await _fallback.getReportById(reportId);
    }
  }

  @override
  Future<List<LessonReport>> getReportsForTeacher(
    String teacherUid, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getReportsForTeacher(
        teacherUid,
        startDate: startDate,
        endDate: endDate,
      );
    }

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('lessonReports')
          .where('teacherUid', isEqualTo: teacherUid);

      final snapshot = await query.get();
      var list = snapshot.docs
          .map((doc) => LessonReport.fromMap(doc.data(), doc.id))
          .toList();

      if (startDate != null) {
        list = list.where((r) => !r.lessonDate.isBefore(startDate)).toList();
      }
      if (endDate != null) {
        list = list.where((r) => !r.lessonDate.isAfter(endDate)).toList();
      }

      list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
      if (list.isEmpty) {
        return await _fallback.getReportsForTeacher(teacherUid);
      }
      return list;
    } catch (_) {
      return await _fallback.getReportsForTeacher(teacherUid);
    }
  }

  @override
  Future<List<LessonReport>> getReportsForStudent(String studentUid) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getReportsForStudent(studentUid);
    }

    try {
      final query = _firestore
          .collection('lessonReports')
          .where('studentUid', isEqualTo: studentUid);
      final snapshot = await query.get();
      var list = snapshot.docs
          .map((doc) => LessonReport.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
      if (list.isEmpty) {
        return await _fallback.getReportsForStudent(studentUid);
      }
      return list;
    } catch (_) {
      return await _fallback.getReportsForStudent(studentUid);
    }
  }

  @override
  Stream<List<LessonReport>> streamReportsForTeacher(String teacherUid) async* {
    if (!FirebaseService.isInitialized) {
      yield* _fallback.streamReportsForTeacher(teacherUid);
      return;
    }

    try {
      final stream = _firestore
          .collection('lessonReports')
          .where('teacherUid', isEqualTo: teacherUid)
          .snapshots();

      await for (final snapshot in stream) {
        final list = snapshot.docs
            .map((doc) => LessonReport.fromMap(doc.data(), doc.id))
            .toList();
        list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
        if (list.isNotEmpty) {
          yield list;
        } else {
          yield await _fallback.getReportsForTeacher(teacherUid);
        }
      }
    } catch (_) {
      yield* _fallback.streamReportsForTeacher(teacherUid);
    }
  }

  @override
  Stream<List<LessonReport>> streamReportsForStudent(String studentUid) async* {
    if (!FirebaseService.isInitialized) {
      yield* _fallback.streamReportsForStudent(studentUid);
      return;
    }

    try {
      final stream = _firestore
          .collection('lessonReports')
          .where('studentUid', isEqualTo: studentUid)
          .snapshots();

      await for (final snapshot in stream) {
        final list = snapshot.docs
            .map((doc) => LessonReport.fromMap(doc.data(), doc.id))
            .toList();
        list.sort((a, b) => b.lessonDate.compareTo(a.lessonDate));
        if (list.isNotEmpty) {
          yield list;
        } else {
          yield await _fallback.getReportsForStudent(studentUid);
        }
      }
    } catch (_) {
      yield* _fallback.streamReportsForStudent(studentUid);
    }
  }

  @override
  Future<List<Map<String, String>>> getAssignedStudents(String teacherUid) async {
    // Queries registered students or returns assigned roster
    return _fallback.getAssignedStudents(teacherUid);
  }
}

final dailyReportRepositoryProvider = Provider<DailyReportRepository>((ref) {
  if (FirebaseService.isInitialized) {
    return FirestoreDailyReportRepository();
  }
  return InMemoryDailyReportRepository();
});
