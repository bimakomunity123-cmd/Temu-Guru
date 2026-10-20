import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/teacher_profile.dart';
import 'firestore_teacher_repository.dart';

abstract class TeacherRepository {
  Future<TeacherProfile> registerTeacher(TeacherProfile profile);
  Future<TeacherProfile?> getTeacherProfile(String uid);
  Stream<TeacherProfile?> streamTeacherProfile(String uid);
  Future<List<TeacherProfile>> getAllTeacherProfiles({String? statusFilter});
  Stream<List<TeacherProfile>> streamAllTeacherProfiles({String? statusFilter});
  Future<void> updateApplicationStatus({
    required String uid,
    required String status,
    String? rejectionReason,
  });
  Future<bool> isEmailRegistered(String email);
  Future<bool> isNikRegistered(String nik);
  Future<List<String>> getAvailableAreas();
  Future<List<String>> getEducationDegrees();
  Future<List<String>> getEnglishLevels();
}

class InMemoryTeacherRepository implements TeacherRepository {
  final Map<String, TeacherProfile> _teachers = {};
  final StreamController<List<TeacherProfile>> _teachersStreamController =
      StreamController<List<TeacherProfile>>.broadcast();

  InMemoryTeacherRepository() {
    _seedInitialMockTeachers();
  }

  void _seedInitialMockTeachers() {
    final now = DateTime.now();

    final teacherPending = TeacherProfile(
      uid: 'teacher-002',
      fullName: 'Budi Pratama, S.Hum',
      nik: '3171012304950001',
      birthDate: DateTime(1995, 4, 23),
      age: 29,
      whatsapp: '081234567891',
      email: 'budi.pratama@temuguru.id',
      education: 'S1 (Sarjana)',
      educationBackground: 'Pendidikan Bahasa Inggris, Universitas Indonesia',
      englishLevel: 'CEFR C1 (Effective Operational Proficiency / Advanced)',
      englishTestDocumentPath: 'teacher_documents/teacher-002/Sertifikat_IELTS_Budi.pdf',
      englishTestDocumentName: 'Sertifikat_IELTS_Budi.pdf',
      englishTestDocumentSizeBytes: 1845210,
      address: 'Jl. Tebet Barat Dalam No. 45, Jakarta Selatan',
      availableTeachingAreas: const [
        'Jakarta Selatan (Tebet, Kuningan, Kebayoran)',
        'Jakarta Pusat (Menteng, Sudirman)',
      ],
      applicationStatus: 'pending',
      createdAt: now.subtract(const Duration(hours: 12)),
    );

    final teacherApproved = TeacherProfile(
      uid: 'teacher-001',
      fullName: 'Sarah Jenkins, S.Pd',
      nik: '3171012304920002',
      birthDate: DateTime(1992, 8, 14),
      age: 32,
      whatsapp: '081298765432',
      email: 'sarah.jenkins@temuguru.id',
      education: 'S2 (Magister / Master)',
      educationBackground: 'Master of Applied Linguistics & TESOL, Melbourne',
      englishLevel: 'CEFR C2 (Mastery / Native Fluency)',
      englishTestDocumentPath: 'teacher_documents/teacher-001/Certificate_TESOL_Sarah.pdf',
      englishTestDocumentName: 'Certificate_TESOL_Sarah.pdf',
      englishTestDocumentSizeBytes: 2450300,
      address: 'Jl. Senopati Raya No. 12, Jakarta Selatan',
      availableTeachingAreas: const [
        'Jakarta Selatan (Tebet, Kuningan, Kebayoran)',
        'Tangerang Selatan (BSD, Bintaro)',
      ],
      applicationStatus: 'approved',
      reviewedAt: now.subtract(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(days: 4)),
    );

    final teacherRejected = TeacherProfile(
      uid: 'teacher-003',
      fullName: 'Doni Saputra, S.S.',
      nik: '3171012304970003',
      birthDate: DateTime(1997, 11, 5),
      age: 27,
      whatsapp: '081311223344',
      email: 'doni.saputra@temuguru.id',
      education: 'S1 (Sarjana)',
      educationBackground: 'Sastra Inggris, Universitas Padjadjaran',
      englishLevel: 'CEFR B2 (Vantage / Upper Intermediate)',
      englishTestDocumentPath: 'teacher_documents/teacher-003/Score_Report_Doni.pdf',
      englishTestDocumentName: 'Score_Report_Doni.pdf',
      englishTestDocumentSizeBytes: 1240000,
      address: 'Jl. Margonda Raya No. 100, Depok',
      availableTeachingAreas: const [
        'Depok (Margonda, Cinere)',
        'Jakarta Selatan (Tebet, Kuningan, Kebayoran)',
      ],
      applicationStatus: 'rejected',
      rejectionReason:
          'Masa berlaku sertifikat bahasa Inggris telah kedaluwarsa lebih dari 2 tahun. Silakan unggah sertifikat resmi terbaru.',
      reviewedAt: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 2)),
    );

    _teachers[teacherPending.uid] = teacherPending;
    _teachers[teacherApproved.uid] = teacherApproved;
    _teachers[teacherRejected.uid] = teacherRejected;
  }

  void _notifyListeners() {
    if (!_teachersStreamController.isClosed) {
      _teachersStreamController.add(_teachers.values.toList());
    }
  }

  @override
  Future<TeacherProfile> registerTeacher(TeacherProfile profile) async {
    if (await isEmailRegistered(profile.email)) {
      throw Exception('Email sudah terdaftar. Silakan gunakan email lain.');
    }

    if (await isNikRegistered(profile.nik)) {
      throw Exception('NIK sudah terdaftar dalam sistem verifikasi guru.');
    }

    _teachers[profile.uid] = profile;
    _notifyListeners();
    return profile;
  }

  @override
  Future<TeacherProfile?> getTeacherProfile(String uid) async {
    return _teachers[uid];
  }

  @override
  Stream<TeacherProfile?> streamTeacherProfile(String uid) {
    return _teachersStreamController.stream.map((list) {
      try {
        return list.firstWhere((t) => t.uid == uid);
      } catch (_) {
        return _teachers[uid];
      }
    });
  }

  @override
  Future<List<TeacherProfile>> getAllTeacherProfiles({String? statusFilter}) async {
    var list = _teachers.values.toList();
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      list = list.where((t) => t.applicationStatus == statusFilter).toList();
    }
    // Urutkan berdasarkan tanggal pendaftaran terbaru
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<TeacherProfile>> streamAllTeacherProfiles({String? statusFilter}) async* {
    yield await getAllTeacherProfiles(statusFilter: statusFilter);
    yield* _teachersStreamController.stream.map((list) {
      var result = list;
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        result = result.where((t) => t.applicationStatus == statusFilter).toList();
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    });
  }

  @override
  Future<void> updateApplicationStatus({
    required String uid,
    required String status,
    String? rejectionReason,
  }) async {
    final existing = _teachers[uid];
    if (existing == null) {
      throw Exception('Profil guru tidak ditemukan.');
    }

    final updated = existing.copyWith(
      applicationStatus: status,
      rejectionReason: status == 'rejected' ? rejectionReason : null,
      reviewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _teachers[uid] = updated;
    _notifyListeners();
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    final lower = email.trim().toLowerCase();
    return _teachers.values.any((p) => p.email.trim().toLowerCase() == lower);
  }

  @override
  Future<bool> isNikRegistered(String nik) async {
    final clean = nik.trim();
    return _teachers.values.any((p) => p.nik.trim() == clean);
  }

  @override
  Future<List<String>> getAvailableAreas() async {
    return const [
      'Jakarta Selatan (Tebet, Kuningan, Kebayoran)',
      'Jakarta Pusat (Menteng, Sudirman)',
      'Jakarta Barat (Kebon Jeruk, Puri)',
      'Jakarta Timur (Rawamangun, Pulomas)',
      'Jakarta Utara (Kelapa Gading, Pluit)',
      'Tangerang Selatan (BSD, Bintaro)',
      'Depok (Margonda, Cinere)',
      'Bekasi (Summarecon)',
      'Bogor (Kota & Sentul)',
    ];
  }

  @override
  Future<List<String>> getEducationDegrees() async {
    return const [
      'S1 (Sarjana)',
      'S2 (Magister / Master)',
      'S3 (Doktor)',
      'D4 (Diploma 4)',
      'D3 (Diploma 3)',
    ];
  }

  @override
  Future<List<String>> getEnglishLevels() async {
    return const [
      'CEFR B2 (Vantage / Upper Intermediate)',
      'CEFR C1 (Effective Operational Proficiency / Advanced)',
      'CEFR C2 (Mastery / Native Fluency)',
    ];
  }
}

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  if (FirebaseService.isInitialized) {
    return FirestoreTeacherRepository();
  }
  return InMemoryTeacherRepository();
});
