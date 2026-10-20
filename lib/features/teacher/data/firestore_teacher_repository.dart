import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/teacher_profile.dart';
import 'teacher_repository.dart';

class FirestoreTeacherRepository implements TeacherRepository {
  final FirebaseFirestore? _customFirestore;
  final InMemoryTeacherRepository _inMemoryFallback = InMemoryTeacherRepository();

  FirestoreTeacherRepository([FirebaseFirestore? firestore])
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<TeacherProfile> registerTeacher(TeacherProfile profile) async {
    if (!FirebaseService.isInitialized) {
      // Use fallback when live Firebase is not yet connected
      return await _inMemoryFallback.registerTeacher(profile);
    }

    // Validate email duplication
    if (await isEmailRegistered(profile.email)) {
      throw Exception('Email sudah terdaftar. Silakan gunakan email lain atau login.');
    }

    // Validate NIK duplication
    if (await isNikRegistered(profile.nik)) {
      throw Exception('NIK ini sudah terdaftar dalam sistem verifikasi guru Temu Guru.');
    }

    final data = profile.toMap();
    data['applicationStatus'] = 'pending';
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('teacherProfiles')
        .doc(profile.uid)
        .set(data);

    return profile;
  }

  @override
  Future<TeacherProfile?> getTeacherProfile(String uid) async {
    if (!FirebaseService.isInitialized) {
      return await _inMemoryFallback.getTeacherProfile(uid);
    }

    final doc =
        await _firestore.collection('teacherProfiles').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final data = doc.data()!;
    final createdTimestamp = data['createdAt'];
    final updatedTimestamp = data['updatedAt'];
    final reviewedTimestamp = data['reviewedAt'];

    return TeacherProfile(
      uid: data['uid'] as String? ?? uid,
      fullName: data['fullName'] as String? ?? '',
      nik: data['nik'] as String? ?? '',
      birthDate: DateTime.tryParse(data['birthDate'] as String? ?? '') ?? DateTime.now(),
      age: data['age'] as int? ?? 0,
      whatsapp: data['whatsapp'] as String? ?? '',
      email: data['email'] as String? ?? '',
      education: data['education'] as String? ?? '',
      educationBackground: data['educationBackground'] as String? ?? '',
      englishLevel: data['englishLevel'] as String? ?? '',
      englishTestDocumentPath: data['englishTestDocumentPath'] as String? ?? '',
      englishTestDocumentName: data['englishTestDocumentName'] as String? ?? '',
      englishTestDocumentSizeBytes: data['englishTestDocumentSizeBytes'] as int? ?? 0,
      address: data['address'] as String? ?? '',
      availableTeachingAreas: List<String>.from(data['availableTeachingAreas'] as List? ?? []),
      applicationStatus: data['applicationStatus'] as String? ?? 'pending',
      rejectionReason: data['rejectionReason'] as String?,
      reviewedAt: reviewedTimestamp is Timestamp
          ? reviewedTimestamp.toDate()
          : null,
      createdAt: createdTimestamp is Timestamp
          ? createdTimestamp.toDate()
          : DateTime.now(),
      updatedAt: updatedTimestamp is Timestamp
          ? updatedTimestamp.toDate()
          : null,
    );
  }

  @override
  Stream<TeacherProfile?> streamTeacherProfile(String uid) {
    if (!FirebaseService.isInitialized) {
      return _inMemoryFallback.streamTeacherProfile(uid);
    }

    return _firestore
        .collection('teacherProfiles')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return _mapDocToTeacherProfile(doc.data()!, doc.id);
    });
  }

  @override
  Future<List<TeacherProfile>> getAllTeacherProfiles({String? statusFilter}) async {
    if (!FirebaseService.isInitialized) {
      return await _inMemoryFallback.getAllTeacherProfiles(statusFilter: statusFilter);
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('teacherProfiles');
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        query = query.where('applicationStatus', isEqualTo: statusFilter);
      }
      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => _mapDocToTeacherProfile(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Fallback without ordering or in-memory fallback on error
      final snapshot = await _firestore.collection('teacherProfiles').get();
      var list = snapshot.docs
          .map((doc) => _mapDocToTeacherProfile(doc.data(), doc.id))
          .toList();
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        list = list.where((t) => t.applicationStatus == statusFilter).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
  }

  @override
  Stream<List<TeacherProfile>> streamAllTeacherProfiles({String? statusFilter}) {
    if (!FirebaseService.isInitialized) {
      return _inMemoryFallback.streamAllTeacherProfiles(statusFilter: statusFilter);
    }

    Query<Map<String, dynamic>> query = _firestore.collection('teacherProfiles');
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('applicationStatus', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => _mapDocToTeacherProfile(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> updateApplicationStatus({
    required String uid,
    required String status,
    String? rejectionReason,
  }) async {
    if (!FirebaseService.isInitialized) {
      return await _inMemoryFallback.updateApplicationStatus(
        uid: uid,
        status: status,
        rejectionReason: rejectionReason,
      );
    }

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    final teacherDocRef = _firestore.collection('teacherProfiles').doc(uid);
    batch.update(teacherDocRef, {
      'applicationStatus': status,
      'rejectionReason': status == 'rejected' ? rejectionReason : null,
      'reviewedAt': now,
      'updatedAt': now,
    });

    final userDocRef = _firestore.collection('users').doc(uid);
    batch.update(userDocRef, {
      'accountStatus': status == 'approved'
          ? 'active'
          : (status == 'rejected' ? 'rejected' : 'pending'),
      'updatedAt': now,
    });

    await batch.commit();
  }

  TeacherProfile _mapDocToTeacherProfile(Map<String, dynamic> data, String docId) {
    final createdTimestamp = data['createdAt'];
    final updatedTimestamp = data['updatedAt'];
    final reviewedTimestamp = data['reviewedAt'];

    return TeacherProfile(
      uid: data['uid'] as String? ?? docId,
      fullName: data['fullName'] as String? ?? '',
      nik: data['nik'] as String? ?? '',
      birthDate: DateTime.tryParse(data['birthDate'] as String? ?? '') ?? DateTime.now(),
      age: data['age'] as int? ?? 0,
      whatsapp: data['whatsapp'] as String? ?? '',
      email: data['email'] as String? ?? '',
      education: data['education'] as String? ?? '',
      educationBackground: data['educationBackground'] as String? ?? '',
      englishLevel: data['englishLevel'] as String? ?? '',
      englishTestDocumentPath: data['englishTestDocumentPath'] as String? ?? '',
      englishTestDocumentName: data['englishTestDocumentName'] as String? ?? '',
      englishTestDocumentSizeBytes: data['englishTestDocumentSizeBytes'] as int? ?? 0,
      address: data['address'] as String? ?? '',
      availableTeachingAreas: List<String>.from(data['availableTeachingAreas'] as List? ?? []),
      applicationStatus: data['applicationStatus'] as String? ?? 'pending',
      rejectionReason: data['rejectionReason'] as String?,
      reviewedAt: reviewedTimestamp is Timestamp
          ? reviewedTimestamp.toDate()
          : null,
      createdAt: createdTimestamp is Timestamp
          ? createdTimestamp.toDate()
          : DateTime.now(),
      updatedAt: updatedTimestamp is Timestamp
          ? updatedTimestamp.toDate()
          : null,
    );
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    if (!FirebaseService.isInitialized) {
      return await _inMemoryFallback.isEmailRegistered(email);
    }

    final lower = email.trim().toLowerCase();

    // Check in users collection
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: lower)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) return true;

    // Check in teacherProfiles collection
    final teacherQuery = await _firestore
        .collection('teacherProfiles')
        .where('email', isEqualTo: lower)
        .limit(1)
        .get();

    return teacherQuery.docs.isNotEmpty;
  }

  @override
  Future<bool> isNikRegistered(String nik) async {
    if (!FirebaseService.isInitialized) {
      return await _inMemoryFallback.isNikRegistered(nik);
    }

    final cleanNik = nik.trim();
    final query = await _firestore
        .collection('teacherProfiles')
        .where('nik', isEqualTo: cleanNik)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  @override
  Future<List<String>> getAvailableAreas() async {
    return _inMemoryFallback.getAvailableAreas();
  }

  @override
  Future<List<String>> getEducationDegrees() async {
    return _inMemoryFallback.getEducationDegrees();
  }

  @override
  Future<List<String>> getEnglishLevels() async {
    return _inMemoryFallback.getEnglishLevels();
  }
}
