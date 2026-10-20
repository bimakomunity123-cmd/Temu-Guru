import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/lesson_report.dart';
import 'daily_report_repository.dart';

class DailyReportState {
  final bool isLoading;
  final bool isSubmitting;
  final List<LessonReport> reports;
  final String dateFilter; // 'all', 'today', '7days', '30days'
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const DailyReportState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.reports = const [],
    this.dateFilter = 'all',
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  List<LessonReport> get filteredReports {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return reports.where((report) {
      // Date filter
      final reportDay = DateTime(
        report.lessonDate.year,
        report.lessonDate.month,
        report.lessonDate.day,
      );

      bool matchesDate = true;
      if (dateFilter == 'today') {
        matchesDate = reportDay.isAtSameMomentAs(today);
      } else if (dateFilter == '7days') {
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        matchesDate = !reportDay.isBefore(sevenDaysAgo);
      } else if (dateFilter == '30days') {
        final thirtyDaysAgo = today.subtract(const Duration(days: 30));
        matchesDate = !reportDay.isBefore(thirtyDaysAgo);
      }

      // Search query
      final query = searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          report.studentName.toLowerCase().contains(query) ||
          report.materialsCovered.toLowerCase().contains(query) ||
          report.meetingLocation.toLowerCase().contains(query) ||
          'pertemuan ${report.meetingNumber}'.contains(query);

      return matchesDate && matchesQuery;
    }).toList();
  }

  int get countTotal => reports.length;
  int get countThisMonth {
    final now = DateTime.now();
    return reports
        .where((r) =>
            r.lessonDate.year == now.year && r.lessonDate.month == now.month)
        .length;
  }

  Set<String> get uniqueStudentUids => reports.map((r) => r.studentUid).toSet();

  DailyReportState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<LessonReport>? reports,
    String? dateFilter,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
  }) {
    return DailyReportState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      reports: reports ?? this.reports,
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class DailyReportNotifier extends Notifier<DailyReportState> {
  @override
  DailyReportState build() {
    return const DailyReportState();
  }

  Future<void> loadReportsForTeacher(String teacherUid) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(dailyReportRepositoryProvider);
      final list = await repo.getReportsForTeacher(teacherUid);
      state = state.copyWith(isLoading: false, reports: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat riwayat laporan: $e',
      );
    }
  }

  Future<void> loadReportsForStudent(String studentUid) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(dailyReportRepositoryProvider);
      final list = await repo.getReportsForStudent(studentUid);
      state = state.copyWith(isLoading: false, reports: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat laporan belajar siswa: $e',
      );
    }
  }

  void setDateFilter(String filter) {
    state = state.copyWith(dateFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> submitReport(LessonReport report) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(dailyReportRepositoryProvider);
      await repo.createReport(report);
      await loadReportsForTeacher(report.teacherUid);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Laporan pertemuan ke-${report.meetingNumber} berhasil disimpan!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gagal menyimpan laporan sesi: $e',
      );
      return false;
    }
  }

  Future<bool> updateReport(LessonReport report) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(dailyReportRepositoryProvider);
      await repo.updateReport(report);
      await loadReportsForTeacher(report.teacherUid);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Laporan pertemuan berhasil diperbarui.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gagal memperbarui laporan: $e',
      );
      return false;
    }
  }
}

final dailyReportNotifierProvider =
    NotifierProvider<DailyReportNotifier, DailyReportState>(
  DailyReportNotifier.new,
);
