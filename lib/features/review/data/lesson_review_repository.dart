import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/lesson_review.dart';

class DuplicateReviewException implements Exception {
  final String message;
  DuplicateReviewException([this.message = 'Ulasan untuk sesi les ini sudah pernah dibuat.']);

  @override
  String toString() => message;
}

abstract class LessonReviewRepository {
  Future<LessonReview> createReview(LessonReview review);
  Future<LessonReview> updateReview(LessonReview review);
  Future<LessonReview?> getReviewForSession(String lessonSessionId, String studentUid);
  Future<List<LessonReview>> getReviewsForStudent(String studentUid);
  Future<List<LessonReview>> getReviewsForTeacher(String teacherUid);
  Stream<List<LessonReview>> streamReviewsForStudent(String studentUid);
  Future<bool> hasReviewedSession(String lessonSessionId, String studentUid);
}

class InMemoryLessonReviewRepository implements LessonReviewRepository {
  final Map<String, LessonReview> _reviews = {};
  final StreamController<List<LessonReview>> _streamController =
      StreamController<List<LessonReview>>.broadcast();

  InMemoryLessonReviewRepository() {
    _seedInitialReviews();
  }

  void _seedInitialReviews() {
    final now = DateTime.now();

    // Initial review for report-001
    final rev1 = LessonReview(
      reviewId: 'review-001',
      lessonSessionId: 'report-001',
      studentUid: 'student-001',
      studentName: 'Ahmad Faiz Pratama',
      teacherUid: 'teacher-001',
      teacherName: 'Sarah Jenkins, S.Pd',
      rating: 5,
      impression:
          'Penjelasan materi IELTS Writing Task 1 sangat terstruktur dan mudah dipahami. Tutor memberikan contoh konkret cara menguraikan data grafik.',
      messageAndExpectation:
          'Semoga sesi berikutnya bisa simulasi waktu pengerjaan 20 menit penuh.',
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: null,
      moderationStatus: 'published',
    );

    _reviews[rev1.reviewId] = rev1;
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(_reviews.values.toList());
    }
  }

  @override
  Future<LessonReview> createReview(LessonReview review) async {
    // Validate rating
    if (review.rating < 1 || review.rating > 5) {
      throw ArgumentError('Rating harus bernilai antara 1 sampai 5 bintang.');
    }
    // Validate impression
    if (review.impression.trim().isEmpty) {
      throw ArgumentError('Kesan belajar wajib diisi.');
    }
    if (review.impression.length > 500) {
      throw ArgumentError('Kesan belajar maksimal 500 karakter.');
    }
    if (review.messageAndExpectation != null && review.messageAndExpectation!.length > 500) {
      throw ArgumentError('Pesan dan harapan maksimal 500 karakter.');
    }

    // Check duplicate
    final existing = _reviews.values.any((r) =>
        r.lessonSessionId == review.lessonSessionId &&
        r.studentUid == review.studentUid);
    if (existing) {
      throw DuplicateReviewException();
    }

    final id = review.reviewId.isNotEmpty
        ? review.reviewId
        : 'rev-${DateTime.now().millisecondsSinceEpoch}';
    final saved = review.copyWith(
      reviewId: id,
      createdAt: DateTime.now(),
    );
    _reviews[id] = saved;
    _notify();
    return saved;
  }

  @override
  Future<LessonReview> updateReview(LessonReview review) async {
    if (review.rating < 1 || review.rating > 5) {
      throw ArgumentError('Rating harus bernilai antara 1 sampai 5 bintang.');
    }
    if (review.impression.trim().isEmpty) {
      throw ArgumentError('Kesan belajar wajib diisi.');
    }
    if (review.impression.length > 500) {
      throw ArgumentError('Kesan belajar maksimal 500 karakter.');
    }
    if (review.messageAndExpectation != null && review.messageAndExpectation!.length > 500) {
      throw ArgumentError('Pesan dan harapan maksimal 500 karakter.');
    }

    final id = review.reviewId;
    if (!_reviews.containsKey(id)) {
      // Find by session and student if id was blank
      final found = _reviews.values.firstWhere(
        (r) => r.lessonSessionId == review.lessonSessionId && r.studentUid == review.studentUid,
        orElse: () => throw ArgumentError('Ulasan tidak ditemukan untuk diperbarui.'),
      );
      final updated = review.copyWith(
        reviewId: found.reviewId,
        updatedAt: DateTime.now(),
      );
      _reviews[found.reviewId] = updated;
      _notify();
      return updated;
    }

    final updated = review.copyWith(updatedAt: DateTime.now());
    _reviews[id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<LessonReview?> getReviewForSession(String lessonSessionId, String studentUid) async {
    try {
      return _reviews.values.firstWhere(
        (r) => r.lessonSessionId == lessonSessionId && r.studentUid == studentUid,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<LessonReview>> getReviewsForStudent(String studentUid) async {
    final list = _reviews.values.where((r) => r.studentUid == studentUid).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<LessonReview>> getReviewsForTeacher(String teacherUid) async {
    final list = _reviews.values.where((r) => r.teacherUid == teacherUid).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<LessonReview>> streamReviewsForStudent(String studentUid) async* {
    yield await getReviewsForStudent(studentUid);
    yield* _streamController.stream.map((list) {
      final filtered = list.where((r) => r.studentUid == studentUid).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  @override
  Future<bool> hasReviewedSession(String lessonSessionId, String studentUid) async {
    return _reviews.values.any((r) =>
        r.lessonSessionId == lessonSessionId && r.studentUid == studentUid);
  }
}

class FirestoreLessonReviewRepository implements LessonReviewRepository {
  final FirebaseFirestore? _customFirestore;
  final InMemoryLessonReviewRepository _fallback = InMemoryLessonReviewRepository();

  FirestoreLessonReviewRepository([FirebaseFirestore? firestore])
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<LessonReview> createReview(LessonReview review) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.createReview(review);
    }

    try {
      final collection = _firestore.collection('lessonReviews');

      // Check duplicate in Firestore
      final existingQuery = await collection
          .where('lessonSessionId', isEqualTo: review.lessonSessionId)
          .where('studentUid', isEqualTo: review.studentUid)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw DuplicateReviewException();
      }

      final docRef = review.reviewId.isNotEmpty
          ? collection.doc(review.reviewId)
          : collection.doc();

      final data = review.toMap();
      data['reviewId'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = null;

      await docRef.set(data);
      return review.copyWith(reviewId: docRef.id, createdAt: DateTime.now());
    } on DuplicateReviewException {
      rethrow;
    } catch (_) {
      return await _fallback.createReview(review);
    }
  }

  @override
  Future<LessonReview> updateReview(LessonReview review) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.updateReview(review);
    }

    try {
      final docRef = _firestore.collection('lessonReviews').doc(review.reviewId);
      final data = review.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.update(data);
      return review.copyWith(updatedAt: DateTime.now());
    } catch (_) {
      return await _fallback.updateReview(review);
    }
  }

  @override
  Future<LessonReview?> getReviewForSession(String lessonSessionId, String studentUid) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getReviewForSession(lessonSessionId, studentUid);
    }

    try {
      final snapshot = await _firestore
          .collection('lessonReviews')
          .where('lessonSessionId', isEqualTo: lessonSessionId)
          .where('studentUid', isEqualTo: studentUid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return LessonReview.fromMap(doc.data(), doc.id);
    } catch (_) {
      return await _fallback.getReviewForSession(lessonSessionId, studentUid);
    }
  }

  @override
  Future<List<LessonReview>> getReviewsForStudent(String studentUid) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getReviewsForStudent(studentUid);
    }

    try {
      final snapshot = await _firestore
          .collection('lessonReviews')
          .where('studentUid', isEqualTo: studentUid)
          .get();

      if (snapshot.docs.isEmpty) {
        return await _fallback.getReviewsForStudent(studentUid);
      }

      final list = snapshot.docs
          .map((d) => LessonReview.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return await _fallback.getReviewsForStudent(studentUid);
    }
  }

  @override
  Future<List<LessonReview>> getReviewsForTeacher(String teacherUid) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getReviewsForTeacher(teacherUid);
    }

    try {
      final snapshot = await _firestore
          .collection('lessonReviews')
          .where('teacherUid', isEqualTo: teacherUid)
          .get();

      if (snapshot.docs.isEmpty) {
        return await _fallback.getReviewsForTeacher(teacherUid);
      }

      final list = snapshot.docs
          .map((d) => LessonReview.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return await _fallback.getReviewsForTeacher(teacherUid);
    }
  }

  @override
  Stream<List<LessonReview>> streamReviewsForStudent(String studentUid) async* {
    if (!FirebaseService.isInitialized) {
      yield* _fallback.streamReviewsForStudent(studentUid);
      return;
    }

    try {
      final stream = _firestore
          .collection('lessonReviews')
          .where('studentUid', isEqualTo: studentUid)
          .snapshots();

      await for (final snapshot in stream) {
        if (snapshot.docs.isEmpty) {
          yield await _fallback.getReviewsForStudent(studentUid);
        } else {
          final list = snapshot.docs
              .map((d) => LessonReview.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          yield list;
        }
      }
    } catch (_) {
      yield* _fallback.streamReviewsForStudent(studentUid);
    }
  }

  @override
  Future<bool> hasReviewedSession(String lessonSessionId, String studentUid) async {
    final rev = await getReviewForSession(lessonSessionId, studentUid);
    return rev != null;
  }
}

final lessonReviewRepositoryProvider = Provider<LessonReviewRepository>((ref) {
  if (FirebaseService.isInitialized) {
    return FirestoreLessonReviewRepository();
  }
  return InMemoryLessonReviewRepository();
});
