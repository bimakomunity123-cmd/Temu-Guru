import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ruangguru/features/review/domain/lesson_review.dart';
import 'package:flutter_ruangguru/features/review/data/lesson_review_repository.dart';

void main() {
  group('Feature C: LessonReview Model & Anonymity Tests', () {
    test('LessonReview toMap and fromMap preserves all database fields', () {
      final now = DateTime(2026, 10, 20, 16, 0);
      final review = LessonReview(
        reviewId: 'rev-01',
        lessonSessionId: 'report-001',
        studentUid: 'student-001',
        studentName: 'Ahmad Faiz Pratama',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah Jenkins, S.Pd',
        rating: 5,
        impression: 'Tutor sangat sabar dan komunikatif.',
        messageAndExpectation: 'Ingin latihan speaking lebih banyak.',
        createdAt: now,
        updatedAt: null,
        moderationStatus: 'published',
      );

      final map = review.toMap();
      expect(map['reviewId'], 'rev-01');
      expect(map['lessonSessionId'], 'report-001');
      expect(map['studentUid'], 'student-001');
      expect(map['teacherUid'], 'teacher-001');
      expect(map['rating'], 5);
      expect(map['impression'], 'Tutor sangat sabar dan komunikatif.');
      expect(map['moderationStatus'], 'published');

      final restored = LessonReview.fromMap(map, 'rev-01');
      expect(restored.reviewId, review.reviewId);
      expect(restored.rating, 5);
      expect(restored.impression, review.impression);
      expect(restored.messageAndExpectation, review.messageAndExpectation);
    });

    test('publicStudentName correctly anonymizes full student name', () {
      final review = LessonReview(
        reviewId: 'rev-01',
        lessonSessionId: 'report-001',
        studentUid: 'student-001',
        studentName: 'Ahmad Faiz Pratama',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah Jenkins',
        rating: 5,
        impression: 'Bagus',
        createdAt: DateTime.now(),
      );

      // Protects student privacy on public listings: "Ahmad F." instead of full name
      expect(review.publicStudentName, 'Ahmad F.');
    });
  });

  group('Feature C: LessonReview Repository Validation & Anti-Duplicate Tests', () {
    late InMemoryLessonReviewRepository repository;

    setUp(() {
      repository = InMemoryLessonReviewRepository();
    });

    test('Initial repository has seeded review for report-001', () async {
      final existing = await repository.getReviewForSession('report-001', 'student-001');
      expect(existing, isNotNull);
      expect(existing!.rating, 5);
      expect(existing.impression, isNotEmpty);
    });

    test('Duplicate review for the same session and student throws DuplicateReviewException', () async {
      final duplicate = LessonReview(
        reviewId: '',
        lessonSessionId: 'report-001',
        studentUid: 'student-001',
        studentName: 'Ahmad Faiz Pratama',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah Jenkins',
        rating: 4,
        impression: 'Mencoba submit ulasan kedua kali.',
        createdAt: DateTime.now(),
      );

      expect(
        () async => await repository.createReview(duplicate),
        throwsA(isA<DuplicateReviewException>()),
      );
    });

    test('Rating must be strictly between 1 and 5 stars', () async {
      final invalidLow = LessonReview(
        reviewId: '',
        lessonSessionId: 'report-999',
        studentUid: 'student-001',
        studentName: 'Ahmad',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah',
        rating: 0, // Invalid: < 1
        impression: 'Terlalu rendah',
        createdAt: DateTime.now(),
      );

      expect(
        () async => await repository.createReview(invalidLow),
        throwsA(isA<ArgumentError>()),
      );

      final invalidHigh = invalidLow.copyWith(rating: 6); // Invalid: > 5
      expect(
        () async => await repository.createReview(invalidHigh),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Impression (kesan) is mandatory and cannot be empty', () async {
      final emptyImpression = LessonReview(
        reviewId: '',
        lessonSessionId: 'report-999',
        studentUid: 'student-001',
        studentName: 'Ahmad',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah',
        rating: 4,
        impression: '   ', // Blank
        createdAt: DateTime.now(),
      );

      expect(
        () async => await repository.createReview(emptyImpression),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Character length is capped at 500 characters', () async {
      final longText = 'A' * 501;
      final overLimit = LessonReview(
        reviewId: '',
        lessonSessionId: 'report-999',
        studentUid: 'student-001',
        studentName: 'Ahmad',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah',
        rating: 4,
        impression: longText,
        createdAt: DateTime.now(),
      );

      expect(
        () async => await repository.createReview(overLimit),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Valid review can be created for an unreviewed completed session', () async {
      final validReview = LessonReview(
        reviewId: '',
        lessonSessionId: 'report-002', // Session 2 is unreviewed
        studentUid: 'student-001',
        studentName: 'Ahmad Faiz Pratama',
        teacherUid: 'teacher-001',
        teacherName: 'Sarah Jenkins, S.Pd',
        rating: 5,
        impression: 'Sesi speaking simulasi 2 menit sangat membantu rasa percaya diri saya.',
        messageAndExpectation: 'Lanjutkan dengan topik abstract discussion.',
        createdAt: DateTime.now(),
      );

      final saved = await repository.createReview(validReview);
      expect(saved.reviewId, isNotEmpty);

      final hasReviewed = await repository.hasReviewedSession('report-002', 'student-001');
      expect(hasReviewed, isTrue);
    });

    test('Updating an existing review preserves reviewId and updates timestamp', () async {
      final existing = await repository.getReviewForSession('report-001', 'student-001');
      expect(existing, isNotNull);

      final updatedReview = existing!.copyWith(
        rating: 4,
        impression: 'Diperbarui: Penjelasan bagus dan ringkas.',
      );

      final result = await repository.updateReview(updatedReview);
      expect(result.rating, 4);
      expect(result.impression, 'Diperbarui: Penjelasan bagus dan ringkas.');
      expect(result.updatedAt, isNotNull);
    });
  });
}
