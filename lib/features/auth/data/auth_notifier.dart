import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../teacher/data/teacher_repository.dart';
import '../domain/user_role.dart';
import 'firebase_auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AppUser? user;
  final String? errorMessage;
  final bool rememberMe;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.rememberMe = true,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AppUser? user,
    String? errorMessage,
    bool? rememberMe,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // If live Firebase is configured and initialized, authenticate with Firebase Auth
    if (FirebaseService.isInitialized) {
      try {
        final authService = ref.read(firebaseAuthServiceProvider);
        final user = await authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
        return true;
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
        return false;
      }
    }

    // Simulate network delay for realistic UI response
    await Future.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim().toLowerCase();

    // Check credentials or provide dummy mapping for testing in Tahap 1
    if (normalizedEmail.contains('admin')) {
      final user = AppUser(
        uid: 'admin-001',
        email: email,
        name: 'Administrator Temu Guru',
        role: UserRole.admin,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } else if (normalizedEmail.contains('guru.approved') ||
        normalizedEmail.contains('teacher.approved')) {
      final user = AppUser(
        uid: 'teacher-001',
        email: email,
        name: 'Sarah Jenkins, S.Pd',
        role: UserRole.teacher,
        teacherStatus: TeacherApplicationStatus.approved,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } else if (normalizedEmail.contains('guru.pending') ||
        normalizedEmail.contains('teacher.pending')) {
      final user = AppUser(
        uid: 'teacher-002',
        email: email,
        name: 'Budi Pratama, S.Hum',
        role: UserRole.teacher,
        teacherStatus: TeacherApplicationStatus.pending,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } else if (normalizedEmail.contains('guru.rejected') ||
        normalizedEmail.contains('teacher.rejected')) {
      final user = AppUser(
        uid: 'teacher-003',
        email: email,
        name: 'Doni Saputra, S.S.',
        role: UserRole.teacher,
        teacherStatus: TeacherApplicationStatus.rejected,
        rejectionReason:
            'Masa berlaku sertifikat bahasa Inggris telah kedaluwarsa lebih dari 2 tahun. Silakan unggah sertifikat resmi terbaru.',
        reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } else if (normalizedEmail.contains('guru') ||
        normalizedEmail.contains('teacher')) {
      // Default teacher is pending if not specified
      final user = AppUser(
        uid: 'teacher-default',
        email: email,
        name: 'Guru Pengajar',
        role: UserRole.teacher,
        teacherStatus: TeacherApplicationStatus.pending,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } else {
      // Default to student
      final user = AppUser(
        uid: 'student-001',
        email: email,
        name: 'Ahmad Faiz',
        role: UserRole.student,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      return true;
    }
  }

  void loginAsQuickDemo(UserRole role, [TeacherApplicationStatus? teacherStatus]) {
    state = state.copyWith(isLoading: true, errorMessage: null);

    Future.delayed(const Duration(milliseconds: 300), () {
      AppUser user;
      switch (role) {
        case UserRole.student:
          user = const AppUser(
            uid: 'student-demo',
            email: 'siswa@temuguru.id',
            name: 'Ahmad Faiz Pratama',
            role: UserRole.student,
          );
          break;
        case UserRole.teacher:
          user = AppUser(
            uid: teacherStatus == TeacherApplicationStatus.pending
                ? 'teacher-002'
                : (teacherStatus == TeacherApplicationStatus.rejected
                    ? 'teacher-003'
                    : 'teacher-001'),
            email: 'guru@temuguru.id',
            name: teacherStatus == TeacherApplicationStatus.pending
                ? 'Budi Pratama, S.Hum'
                : (teacherStatus == TeacherApplicationStatus.rejected
                    ? 'Doni Saputra, S.S.'
                    : 'Sarah Jenkins, S.Pd'),
            role: UserRole.teacher,
            teacherStatus: teacherStatus ?? TeacherApplicationStatus.approved,
            rejectionReason: teacherStatus == TeacherApplicationStatus.rejected
                ? 'Masa berlaku sertifikat bahasa Inggris telah kedaluwarsa lebih dari 2 tahun. Silakan unggah sertifikat resmi terbaru.'
                : null,
            reviewedAt: teacherStatus == TeacherApplicationStatus.rejected
                ? DateTime.now().subtract(const Duration(days: 1))
                : null,
          );
          break;
        case UserRole.admin:
          user = const AppUser(
            uid: 'admin-demo',
            email: 'admin@temuguru.id',
            name: 'Admin Temu Guru',
            role: UserRole.admin,
          );
          break;
      }
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    });
  }

  Future<void> refreshTeacherStatus() async {
    final currentUser = state.user;
    if (currentUser == null || !currentUser.isTeacher) return;

    try {
      final repo = ref.read(teacherRepositoryProvider);
      final profile = await repo.getTeacherProfile(currentUser.uid);
      if (profile != null) {
        final status = TeacherApplicationStatus.values.firstWhere(
          (s) => s.name == profile.applicationStatus,
          orElse: () => TeacherApplicationStatus.pending,
        );
        final updatedUser = currentUser.copyWith(
          teacherStatus: status,
          rejectionReason: profile.rejectionReason,
          reviewedAt: profile.reviewedAt,
        );
        state = state.copyWith(user: updatedUser);
      }
    } catch (_) {}
  }

  void logout() {
    if (FirebaseService.isInitialized) {
      ref.read(firebaseAuthServiceProvider).signOut();
    }
    state = const AuthState();
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
