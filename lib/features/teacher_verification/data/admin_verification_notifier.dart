import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../teacher/data/teacher_repository.dart';
import '../../teacher/domain/teacher_profile.dart';

class AdminVerificationState {
  final bool isLoading;
  final String statusFilter; // 'all', 'pending', 'approved', 'rejected'
  final String searchQuery;
  final List<TeacherProfile> teachers;
  final String? errorMessage;
  final String? successMessage;

  const AdminVerificationState({
    this.isLoading = false,
    this.statusFilter = 'all',
    this.searchQuery = '',
    this.teachers = const [],
    this.errorMessage,
    this.successMessage,
  });

  List<TeacherProfile> get filteredTeachers {
    return teachers.where((teacher) {
      final matchesFilter = statusFilter == 'all' || teacher.applicationStatus == statusFilter;
      final query = searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          teacher.fullName.toLowerCase().contains(query) ||
          teacher.nik.contains(query) ||
          teacher.email.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  int get countTotal => teachers.length;
  int get countPending => teachers.where((t) => t.applicationStatus == 'pending').length;
  int get countApproved => teachers.where((t) => t.applicationStatus == 'approved').length;
  int get countRejected => teachers.where((t) => t.applicationStatus == 'rejected').length;

  AdminVerificationState copyWith({
    bool? isLoading,
    String? statusFilter,
    String? searchQuery,
    List<TeacherProfile>? teachers,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminVerificationState(
      isLoading: isLoading ?? this.isLoading,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      teachers: teachers ?? this.teachers,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AdminVerificationNotifier extends Notifier<AdminVerificationState> {
  @override
  AdminVerificationState build() {
    // Automatically load teachers when provider initialized
    Future.microtask(() => loadTeachers());
    return const AdminVerificationState(isLoading: true);
  }

  Future<void> loadTeachers() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(teacherRepositoryProvider);
      final list = await repo.getAllTeacherProfiles();
      state = state.copyWith(isLoading: false, teachers: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data pendaftaran guru: $e',
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> approveTeacher(String uid, String teacherName) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(teacherRepositoryProvider);
      await repo.updateApplicationStatus(
        uid: uid,
        status: 'approved',
      );
      await loadTeachers();
      state = state.copyWith(
        successMessage: 'Pendaftaran $teacherName berhasil disetujui (Approved).',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyetujui pendaftaran: $e',
      );
      return false;
    }
  }

  Future<bool> rejectTeacher(String uid, String teacherName, String reason) async {
    if (reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Alasan penolakan wajib diisi.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final repo = ref.read(teacherRepositoryProvider);
      await repo.updateApplicationStatus(
        uid: uid,
        status: 'rejected',
        rejectionReason: reason.trim(),
      );
      await loadTeachers();
      state = state.copyWith(
        successMessage: 'Pendaftaran $teacherName telah ditolak dengan catatan alasan.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menolak pendaftaran: $e',
      );
      return false;
    }
  }
}

final adminVerificationNotifierProvider =
    NotifierProvider<AdminVerificationNotifier, AdminVerificationState>(
  AdminVerificationNotifier.new,
);
