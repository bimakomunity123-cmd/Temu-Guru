import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/student_profile.dart';
import 'firestore_student_repository.dart';

abstract class StudentRepository {
  Future<StudentProfile> registerStudent(StudentProfile profile);
  Future<StudentProfile?> getStudentProfile(String uid);
  Future<bool> isEmailRegistered(String email);
  Future<List<String>> getAvailableAreas();
  Future<List<String>> getAvailablePrograms();
}

class InMemoryStudentRepository implements StudentRepository {
  final Map<String, StudentProfile> _students = {};

  @override
  Future<StudentProfile> registerStudent(StudentProfile profile) async {
    // Check if email already registered
    final alreadyExists = await isEmailRegistered(profile.email);
    if (alreadyExists) {
      throw Exception('Email sudah terdaftar. Silakan gunakan email lain atau masuk.');
    }

    _students[profile.uid] = profile;
    return profile;
  }

  @override
  Future<StudentProfile?> getStudentProfile(String uid) async {
    return _students[uid];
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    final lower = email.trim().toLowerCase();
    return _students.values.any((p) => p.email.trim().toLowerCase() == lower);
  }

  @override
  Future<List<String>> getAvailableAreas() async {
    return const [
      'Jakarta Selatan (Tebet, Kuningan, Kebayoran Baru)',
      'Jakarta Pusat (Menteng, Sudirman, Thamrin)',
      'Jakarta Barat (Kebon Jeruk, Puri Indah, Tanjung Duren)',
      'Jakarta Timur (Rawamangun, Pulomas, Cibubur)',
      'Jakarta Utara (Kelapa Gading, Pluit, Sunter)',
      'Tangerang & Tangerang Selatan (BSD, Bintaro, Alam Sutera)',
      'Depok & Sekitarnya (Margonda, Cinere, Sawangan)',
      'Bekasi (Summarecon, Harapan Indah)',
      'Bogor (Pusat Kota, Sentul)',
    ];
  }

  @override
  Future<List<String>> getAvailablePrograms() async {
    return const [
      'General English & Conversation Booster',
      'English for Children / Primary Kids (Fun & Interactive)',
      'SMP / SMA English Curriculum & Exam Prep',
      'Business English & Professional Communication',
      'IELTS Preparation (Academic & General)',
      'TOEFL iBT / ITP Preparation Course',
      'Grammar & Academic Writing Masterclass',
    ];
  }
}

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  if (FirebaseService.isInitialized) {
    return FirestoreStudentRepository();
  }
  return InMemoryStudentRepository();
});
