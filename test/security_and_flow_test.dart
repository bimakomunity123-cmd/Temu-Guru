import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ruangguru/core/validators/form_validators.dart';
import 'package:flutter_ruangguru/features/auth/domain/user_role.dart';
import 'package:flutter_ruangguru/features/teacher/domain/teacher_profile.dart';

void main() {
  group('Tahap 6: Security and Form Validators Tests', () {
    test('NIK must be exactly 16 digits numeric', () {
      expect(FormValidators.nik(''), isNotNull);
      expect(FormValidators.nik('123456789012345'), isNotNull); // 15 digits
      expect(FormValidators.nik('12345678901234567'), isNotNull); // 17 digits
      expect(FormValidators.nik('317101234567890a'), isNotNull); // contains letter
      expect(FormValidators.nik('3171012345678901'), isNull); // Valid 16 digits
    });

    test('Teacher Age strictly enforced between 18 and 35 years', () {
      final now = DateTime.now();

      // 36 years old -> Rejected
      final tooOld = DateTime(now.year - 36, now.month, now.day);
      expect(FormValidators.teacherAge(tooOld), contains('maksimal 35 tahun'));

      // 17 years old -> Rejected
      final tooYoung = DateTime(now.year - 17, now.month, now.day);
      expect(FormValidators.teacherAge(tooYoung), contains('minimal 18 tahun'));

      // 25 years old -> Accepted
      final validAge = DateTime(now.year - 25, now.month, now.day);
      expect(FormValidators.teacherAge(validAge), isNull);

      // Exactly 35 years old -> Accepted
      final exactly35 = DateTime(now.year - 35, now.month, now.day);
      expect(FormValidators.teacherAge(exactly35), isNull);
    });

    test('English CEFR Level must be at least B2 (B2, C1, or C2)', () {
      expect(FormValidators.englishLevel('A1 - Beginner'), contains('minimal CEFR B2'));
      expect(FormValidators.englishLevel('A2 - Elementary'), contains('minimal CEFR B2'));
      expect(FormValidators.englishLevel('B1 - Intermediate'), contains('minimal CEFR B2'));
      expect(FormValidators.englishLevel('B2 - Upper Intermediate'), isNull);
      expect(FormValidators.englishLevel('C1 - Advanced'), isNull);
      expect(FormValidators.englishLevel('C2 - Proficient / Native'), isNull);
    });

    test('PDF File Size limit <= 5 MB', () {
      expect(FormValidators.pdfFileSize(null), contains('wajib dilampirkan'));
      expect(FormValidators.pdfFileSize(0), contains('wajib dilampirkan'));

      // 2 MB -> OK
      expect(FormValidators.pdfFileSize(2 * 1024 * 1024, 5), isNull);
      // Exactly 5 MB -> OK
      expect(FormValidators.pdfFileSize(5 * 1024 * 1024, 5), isNull);
      // 5.1 MB -> Rejected
      expect(FormValidators.pdfFileSize((5.1 * 1024 * 1024).toInt(), 5), contains('maksimal 5 MB'));
    });

    test('WhatsApp Number Indonesian format validation', () {
      expect(FormValidators.whatsapp('12345'), isNotNull);
      expect(FormValidators.whatsapp('0711234567'), isNotNull); // not 08 or 628
      expect(FormValidators.whatsapp('081234567890'), isNull); // 12 digits
      expect(FormValidators.whatsapp('6281234567890'), isNull); // 13 digits
    });

    test('Password and Confirmation matching', () {
      expect(FormValidators.password('12345'), contains('minimal 6 karakter'));
      expect(FormValidators.password('secret123'), isNull);
      expect(FormValidators.confirmPassword('secret456', 'secret123'), contains('tidak cocok'));
      expect(FormValidators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('Tahap 6: Role-Based Access Control and Security Rules Verification', () {
    test('Teacher Profile always defaults to pending application status upon creation', () {
      final newTeacher = TeacherProfile(
        uid: 'teacher-test-01',
        fullName: 'John Doe, S.Pd',
        nik: '3201012345678901',
        birthDate: DateTime(1995, 5, 10),
        age: 30,
        whatsapp: '081234567890',
        email: 'teacher@temuguru.id',
        education: 'S1',
        educationBackground: 'Pendidikan Bahasa Inggris',
        englishLevel: 'C1 - Advanced',
        englishTestDocumentPath: 'teachers/teacher-test-01/certificate.pdf',
        englishTestDocumentName: 'ielts_certificate.pdf',
        englishTestDocumentSizeBytes: 1024 * 500,
        address: 'Jl. Merdeka No. 10',
        availableTeachingAreas: const ['Jakarta Selatan'],
        createdAt: DateTime.now(),
      );

      expect(newTeacher.applicationStatus, equals('pending'));
      expect(newTeacher.rejectionReason, isNull);

      final map = newTeacher.toMap();
      expect(map['applicationStatus'], equals('pending'));
      expect(map['nik'], equals('3201012345678901'));
      expect(map['nik'].toString().length, equals(16));
    });

    test('AppUser role privileges and helper getters verify isolation', () {
      // 1. Student User
      const student = AppUser(
        uid: 'stu-1',
        email: 'student@test.com',
        name: 'Faiz',
        role: UserRole.student,
      );
      expect(student.isStudent, isTrue);
      expect(student.isTeacher, isFalse);
      expect(student.isAdmin, isFalse);

      // 2. Pending Teacher User
      const pendingTeacher = AppUser(
        uid: 'tch-pending',
        email: 'teacher@test.com',
        name: 'Sarah',
        role: UserRole.teacher,
        teacherStatus: TeacherApplicationStatus.pending,
      );
      expect(pendingTeacher.isTeacher, isTrue);
      expect(pendingTeacher.isTeacherApproved, isFalse);
      expect(pendingTeacher.isTeacherPending, isTrue);
      expect(pendingTeacher.isAdmin, isFalse);

      // 3. Approved Teacher User
      const approvedTeacher = AppUser(
        uid: 'tch-approved',
        email: 'teacher.approved@test.com',
        name: 'Sarah Approved',
        role: UserRole.teacher,
        teacherStatus: TeacherApplicationStatus.approved,
      );
      expect(approvedTeacher.isTeacher, isTrue);
      expect(approvedTeacher.isTeacherApproved, isTrue);
      expect(approvedTeacher.isAdmin, isFalse);

      // 4. Admin User
      const admin = AppUser(
        uid: 'adm-1',
        email: 'admin@temuguru.id',
        name: 'Administrator',
        role: UserRole.admin,
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.isTeacher, isFalse);
      expect(admin.isStudent, isFalse);
    });
  });
}
