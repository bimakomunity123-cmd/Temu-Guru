import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ruangguru/features/student/domain/student_profile.dart';
import 'package:flutter_ruangguru/features/teacher/domain/teacher_profile.dart';

void main() {
  group('StudentProfile Model Tests', () {
    test('toMap and fromMap preserves all fields correctly', () {
      final now = DateTime.now();
      final profile = StudentProfile(
        uid: 'std-123',
        fullName: 'Budi Santoso',
        birthDate: DateTime(2005, 5, 20),
        age: 19,
        whatsapp: '081234567890',
        email: 'budi@temuguru.id',
        address: 'Jl. Sudirman No. 10',
        preferredTeachingArea: 'Jakarta Selatan',
        hasEnglishLearningExperience: true,
        preferredProgram: 'General English',
        createdAt: now,
      );

      final map = profile.toMap();
      final reconstructed = StudentProfile.fromMap(map);

      expect(reconstructed.uid, profile.uid);
      expect(reconstructed.fullName, profile.fullName);
      expect(reconstructed.email, profile.email);
      expect(reconstructed.age, 19);
      expect(reconstructed.hasEnglishLearningExperience, isTrue);
      expect(reconstructed.preferredProgram, profile.preferredProgram);
    });
  });

  group('TeacherProfile Model Tests', () {
    test('toMap and fromMap preserves all fields and pending status', () {
      final now = DateTime.now();
      final profile = TeacherProfile(
        uid: 'tch-456',
        fullName: 'Sarah Jenkins, S.Pd',
        nik: '3171012345678901',
        birthDate: DateTime(1995, 8, 15),
        age: 29,
        whatsapp: '081987654321',
        email: 'sarah@temuguru.id',
        education: 'S1 (Sarjana)',
        educationBackground: 'Pendidikan Bahasa Inggris',
        englishLevel: 'CEFR C1',
        englishTestDocumentPath: 'teacher_documents/tch-456/certificate.pdf',
        englishTestDocumentName: 'certificate.pdf',
        englishTestDocumentSizeBytes: 1048576, // 1 MB
        address: 'Kebayoran Baru, Jakarta Selatan',
        availableTeachingAreas: ['Jakarta Selatan', 'Jakarta Pusat'],
        applicationStatus: 'pending',
        createdAt: now,
      );

      final map = profile.toMap();
      final reconstructed = TeacherProfile.fromMap(map);

      expect(reconstructed.uid, profile.uid);
      expect(reconstructed.nik, '3171012345678901');
      expect(reconstructed.age, 29);
      expect(reconstructed.isPending, isTrue);
      expect(reconstructed.isApproved, isFalse);
      expect(reconstructed.formattedDocumentSize, '1.00 MB');
      expect(reconstructed.englishTestDocumentPath, 'teacher_documents/tch-456/certificate.pdf');
    });
  });
}
