import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/student_profile.dart';
import 'student_repository.dart';

class FirestoreStudentRepository implements StudentRepository {
  final FirebaseFirestore? _customFirestore;
  final InMemoryStudentRepository _inMemoryFallback = InMemoryStudentRepository();

  FirestoreStudentRepository([FirebaseFirestore? firestore])
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<StudentProfile> registerStudent(StudentProfile profile) async {
    if (!FirebaseService.isInitialized) {
      // Use fallback when live Firebase is not yet connected
      return await _inMemoryFallback.registerStudent(profile);
    }

    final alreadyExists = await isEmailRegistered(profile.email);
    if (alreadyExists) {
      throw Exception('Email sudah terdaftar. Silakan gunakan email lain atau masuk.');
    }

    final data = profile.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('studentProfiles')
        .doc(profile.uid)
        .set(data);

    return profile;
  }

  @override
  Future<StudentProfile?> getStudentProfile(String uid) async {
    if (!FirebaseService.isInitialized) {
      return await _inMemoryFallback.getStudentProfile(uid);
    }

    final doc =
        await _firestore.collection('studentProfiles').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final data = doc.data()!;
    final createdTimestamp = data['createdAt'];
    final updatedTimestamp = data['updatedAt'];

    return StudentProfile(
      uid: data['uid'] as String? ?? uid,
      fullName: data['fullName'] as String? ?? '',
      birthDate: DateTime.tryParse(data['birthDate'] as String? ?? '') ?? DateTime.now(),
      age: data['age'] as int? ?? 0,
      whatsapp: data['whatsapp'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      preferredTeachingArea: data['preferredTeachingArea'] as String? ?? '',
      hasEnglishLearningExperience: data['hasEnglishLearningExperience'] as bool? ?? false,
      preferredProgram: data['preferredProgram'] as String? ?? '',
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

    // Check in studentProfiles collection
    final studentQuery = await _firestore
        .collection('studentProfiles')
        .where('email', isEqualTo: lower)
        .limit(1)
        .get();

    return studentQuery.docs.isNotEmpty;
  }

  @override
  Future<List<String>> getAvailableAreas() async {
    return _inMemoryFallback.getAvailableAreas();
  }

  @override
  Future<List<String>> getAvailablePrograms() async {
    return _inMemoryFallback.getAvailablePrograms();
  }
}
