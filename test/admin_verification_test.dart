import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ruangguru/features/teacher_verification/data/admin_verification_notifier.dart';
import 'package:flutter_ruangguru/features/teacher/data/teacher_repository.dart';

void main() {
  group('Admin Teacher Verification Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state loads mock teachers and calculates counts correctly', () async {
      final notifier = container.read(adminVerificationNotifierProvider.notifier);
      await notifier.loadTeachers();

      final state = container.read(adminVerificationNotifierProvider);

      expect(state.isLoading, false);
      expect(state.teachers.isNotEmpty, true);
      expect(state.countTotal, greaterThanOrEqualTo(3));
      expect(state.countPending, greaterThanOrEqualTo(1));
      expect(state.countApproved, greaterThanOrEqualTo(1));
      expect(state.countRejected, greaterThanOrEqualTo(1));
    });

    test('Filter by status correctly filters list', () async {
      final notifier = container.read(adminVerificationNotifierProvider.notifier);
      await notifier.loadTeachers();

      // Filter Pending
      notifier.setFilter('pending');
      var state = container.read(adminVerificationNotifierProvider);
      expect(state.statusFilter, 'pending');
      for (final t in state.filteredTeachers) {
        expect(t.applicationStatus, 'pending');
      }

      // Filter Approved
      notifier.setFilter('approved');
      state = container.read(adminVerificationNotifierProvider);
      expect(state.statusFilter, 'approved');
      for (final t in state.filteredTeachers) {
        expect(t.applicationStatus, 'approved');
      }

      // Filter Rejected
      notifier.setFilter('rejected');
      state = container.read(adminVerificationNotifierProvider);
      expect(state.statusFilter, 'rejected');
      for (final t in state.filteredTeachers) {
        expect(t.applicationStatus, 'rejected');
      }
    });

    test('Search query matches teacher name, NIK, or email', () async {
      final notifier = container.read(adminVerificationNotifierProvider.notifier);
      await notifier.loadTeachers();

      // Search by Name
      notifier.setSearchQuery('Budi');
      var state = container.read(adminVerificationNotifierProvider);
      expect(state.filteredTeachers.any((t) => t.fullName.contains('Budi')), true);

      // Search by NIK
      notifier.setSearchQuery('3171012304950001');
      state = container.read(adminVerificationNotifierProvider);
      expect(state.filteredTeachers.length, 1);
      expect(state.filteredTeachers.first.nik, '3171012304950001');

      // Clear search
      notifier.setSearchQuery('');
      state = container.read(adminVerificationNotifierProvider);
      expect(state.filteredTeachers.length, state.teachers.length);
    });

    test('Approve teacher changes status to approved', () async {
      final notifier = container.read(adminVerificationNotifierProvider.notifier);
      await notifier.loadTeachers();

      final success = await notifier.approveTeacher('teacher-002', 'Budi Pratama, S.Hum');
      expect(success, true);

      final state = container.read(adminVerificationNotifierProvider);
      final approvedTeacher = state.teachers.firstWhere((t) => t.uid == 'teacher-002');
      expect(approvedTeacher.applicationStatus, 'approved');
      expect(approvedTeacher.reviewedAt, isNotNull);

      // Verify in repository
      final repo = container.read(teacherRepositoryProvider);
      final profile = await repo.getTeacherProfile('teacher-002');
      expect(profile?.applicationStatus, 'approved');
    });

    test('Reject teacher sets rejectionReason and updates status to rejected', () async {
      final notifier = container.read(adminVerificationNotifierProvider.notifier);
      await notifier.loadTeachers();

      const reason = 'Sertifikat tidak memenuhi standar CEFR B2.';
      final success = await notifier.rejectTeacher(
        'teacher-001',
        'Sarah Jenkins, S.Pd',
        reason,
      );
      expect(success, true);

      final state = container.read(adminVerificationNotifierProvider);
      final rejectedTeacher = state.teachers.firstWhere((t) => t.uid == 'teacher-001');
      expect(rejectedTeacher.applicationStatus, 'rejected');
      expect(rejectedTeacher.rejectionReason, reason);

      // Verify in repository
      final repo = container.read(teacherRepositoryProvider);
      final profile = await repo.getTeacherProfile('teacher-001');
      expect(profile?.applicationStatus, 'rejected');
      expect(profile?.rejectionReason, reason);
    });
  });
}
