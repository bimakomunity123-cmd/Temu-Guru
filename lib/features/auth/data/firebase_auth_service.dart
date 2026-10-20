import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/user_role.dart';

class FirebaseAuthService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuthService([FirebaseAuth? auth, FirebaseFirestore? firestore])
      : _customAuth = auth,
        _customFirestore = firestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges {
    if (!FirebaseService.isInitialized) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  User? get currentFirebaseUser {
    if (!FirebaseService.isInitialized) return null;
    return _auth.currentUser;
  }

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!FirebaseService.isInitialized) {
      throw Exception('Layanan Firebase belum diinisialisasi dengan konfigurasi aktif.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Gagal melakukan otentikasi pengguna.');
      }

      return await getUserProfile(user.uid, user.email ?? email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } catch (e) {
      throw Exception('Gagal masuk: ${e.toString()}');
    }
  }

  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    if (!FirebaseService.isInitialized) {
      throw Exception('Layanan Firebase belum diinisialisasi.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Gagal membuat akun autentikasi.');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Save to 'users' collection per Section 11
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? email,
        'name': name,
        'role': role.name,
        'accountStatus': role == UserRole.teacher ? 'pending' : 'active',
        'createdAt': now,
        'updatedAt': now,
      });

      return AppUser(
        uid: user.uid,
        email: user.email ?? email,
        name: name,
        role: role,
        teacherStatus: role == UserRole.teacher
            ? TeacherApplicationStatus.pending
            : null,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } catch (e) {
      throw Exception('Gagal mendaftar: ${e.toString()}');
    }
  }

  Future<AppUser> getUserProfile(String uid, String email) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      // Fallback
      return AppUser(
        uid: uid,
        email: email,
        name: email.split('@').first,
        role: UserRole.student,
      );
    }

    final data = doc.data()!;
    final roleStr = data['role'] as String? ?? 'student';
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.student,
    );

    TeacherApplicationStatus? teacherStatus;
    String? rejectionReason;
    DateTime? reviewedAt;

    if (role == UserRole.teacher) {
      final teacherDoc =
          await _firestore.collection('teacherProfiles').doc(uid).get();
      if (teacherDoc.exists) {
        final teacherData = teacherDoc.data()!;
        final statusStr = teacherData['applicationStatus'] as String? ?? 'pending';
        teacherStatus = TeacherApplicationStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => TeacherApplicationStatus.pending,
        );
        rejectionReason = teacherData['rejectionReason'] as String?;
        final rev = teacherData['reviewedAt'];
        if (rev is Timestamp) {
          reviewedAt = rev.toDate();
        }
      } else {
        teacherStatus = TeacherApplicationStatus.pending;
      }
    }

    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? email,
      name: data['name'] as String? ?? email.split('@').first,
      role: role,
      teacherStatus: teacherStatus,
      rejectionReason: rejectionReason,
      reviewedAt: reviewedAt,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!FirebaseService.isInitialized) {
      throw Exception('Layanan Firebase belum aktif.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    }
  }

  Future<void> signOut() async {
    if (FirebaseService.isInitialized) {
      await _auth.signOut();
    }
  }

  String _mapAuthError(String code, String? defaultMessage) {
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Password yang Anda masukkan salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain atau login.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'user-disabled':
        return 'Akun pengguna ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan masuk yang gagal. Silakan coba beberapa saat lagi.';
      default:
        return defaultMessage ?? 'Terjadi kesalahan autentikasi ($code).';
    }
  }
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});
