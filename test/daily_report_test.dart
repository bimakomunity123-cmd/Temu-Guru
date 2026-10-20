import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ruangguru/features/daily_report/domain/lesson_report.dart';
import 'package:flutter_ruangguru/features/daily_report/data/daily_report_repository.dart';
import 'package:flutter_ruangguru/features/daily_report/data/daily_report_notifier.dart';

void main() {
  group('LessonReport Model Tests', () {
    test('toMap and fromMap preserves all fields accurately', () {
      final now = DateTime(2026, 10, 15, 16, 30);
      final report = LessonReport(
        reportId: 'test-rep-01',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah Jenkins, S.Pd',
        studentUid: 'student-001',
        studentName: 'Ahmad Faiz Pratama',
        lessonDate: now,
        meetingLocation: 'Kediaman Siswa',
        startTime: '15:30',
        endTime: '17:00',
        meetingNumber: 1,
        materialsCovered: 'IELTS Academic Writing Task 1',
        sessionComments: 'Siswa memahami materi grafik garis dan bar chart.',
        additionalNotes: 'Latihan soal halaman 32.',
        createdAt: now,
      );

      final map = report.toMap();
      final fromMap = LessonReport.fromMap(map);

      expect(fromMap.reportId, report.reportId);
      expect(fromMap.teacherUid, report.teacherUid);
      expect(fromMap.teacherName, report.teacherName);
      expect(fromMap.studentUid, report.studentUid);
      expect(fromMap.studentName, report.studentName);
      expect(fromMap.meetingLocation, report.meetingLocation);
      expect(fromMap.startTime, report.startTime);
      expect(fromMap.endTime, report.endTime);
      expect(fromMap.meetingNumber, 1);
      expect(fromMap.materialsCovered, report.materialsCovered);
      expect(fromMap.sessionComments, report.sessionComments);
      expect(fromMap.additionalNotes, report.additionalNotes);
    });
  });

  group('DailyReport Repository & Notifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial repository has seed reports for Sarah Jenkins', () async {
      final repo = container.read(dailyReportRepositoryProvider);
      final reports = await repo.getReportsForTeacher('teacher-001');

      expect(reports.isNotEmpty, true);
      expect(reports.length, greaterThanOrEqualTo(2));
      expect(reports.first.teacherUid, 'teacher-001');
    });

    test('Creating a report saves and updates list in notifier', () async {
      final notifier = container.read(dailyReportNotifierProvider.notifier);
      await notifier.loadReportsForTeacher('teacher-001');

      final beforeCount =
          container.read(dailyReportNotifierProvider).reports.length;

      final newReport = LessonReport(
        reportId: 'report-new-001',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah Jenkins, S.Pd',
        studentUid: 'student-001',
        studentName: 'Ahmad Faiz Pratama',
        lessonDate: DateTime.now(),
        meetingLocation: 'Tebet Eco Park Library',
        startTime: '14:00',
        endTime: '15:30',
        meetingNumber: 3,
        materialsCovered: 'IELTS Speaking Part 3 Mock Test',
        sessionComments: 'Diskusi lancar dengan variasi vocabulary tinggi.',
        createdAt: DateTime.now(),
      );

      final success = await notifier.submitReport(newReport);
      expect(success, true);

      final state = container.read(dailyReportNotifierProvider);
      expect(state.reports.length, beforeCount + 1);
      expect(state.reports.any((r) => r.reportId == 'report-new-001'), true);
    });

    test('Filter by search query matches materials or student name', () async {
      final notifier = container.read(dailyReportNotifierProvider.notifier);
      await notifier.loadReportsForTeacher('teacher-001');

      // Search by Material
      notifier.setSearchQuery('Speaking');
      var state = container.read(dailyReportNotifierProvider);
      expect(state.filteredReports.isNotEmpty, true);
      for (final r in state.filteredReports) {
        expect(
          r.materialsCovered.toLowerCase().contains('speaking') ||
              r.studentName.toLowerCase().contains('speaking'),
          true,
        );
      }

      // Clear search
      notifier.setSearchQuery('');
      state = container.read(dailyReportNotifierProvider);
      expect(state.filteredReports.length, state.reports.length);
    });

    test('Student can fetch their own assigned lesson reports', () async {
      final repo = container.read(dailyReportRepositoryProvider);
      final studentReports = await repo.getReportsForStudent('student-001');

      expect(studentReports.isNotEmpty, true);
      for (final r in studentReports) {
        expect(r.studentUid, 'student-001');
      }
    });
  });
}
