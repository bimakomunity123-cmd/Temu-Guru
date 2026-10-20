import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/lesson_review.dart';
import 'lesson_review_repository.dart';

class LessonReviewState {
  final List<LessonReview> reviews;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const LessonReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  bool hasReviewed(String sessionId) {
    return reviews.any((r) => r.lessonSessionId == sessionId);
  }

  LessonReview? getReviewForSession(String sessionId) {
    try {
      return reviews.firstWhere((r) => r.lessonSessionId == sessionId);
    } catch (_) {
      return null;
    }
  }

  LessonReviewState copyWith({
    List<LessonReview>? reviews,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
  }) {
    return LessonReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class LessonReviewNotifier extends Notifier<LessonReviewState> {
  late final LessonReviewRepository _repo;

  @override
  LessonReviewState build() {
    _repo = ref.watch(lessonReviewRepositoryProvider);
    return const LessonReviewState();
  }

  Future<void> loadReviewsForStudent(String studentUid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getReviewsForStudent(studentUid);
      state = state.copyWith(
        reviews: list,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat ulasan: $e',
      );
    }
  }

  Future<bool> submitOrUpdateReview({
    required String? existingReviewId,
    required String lessonSessionId,
    required String studentUid,
    required String studentName,
    required String teacherUid,
    required String teacherName,
    required int rating,
    required String impression,
    String? messageAndExpectation,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);

    try {
      if (existingReviewId != null && existingReviewId.isNotEmpty) {
        // Edit existing review
        final review = LessonReview(
          reviewId: existingReviewId,
          lessonSessionId: lessonSessionId,
          studentUid: studentUid,
          studentName: studentName,
          teacherUid: teacherUid,
          teacherName: teacherName,
          rating: rating,
          impression: impression.trim(),
          messageAndExpectation: messageAndExpectation?.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updated = await _repo.updateReview(review);
        final currentList = state.reviews
            .map((r) => r.reviewId == updated.reviewId ? updated : r)
            .toList();

        state = state.copyWith(
          isSubmitting: false,
          reviews: currentList,
          successMessage: 'Ulasan Anda berhasil diperbarui!',
        );
        return true;
      } else {
        // Create new review
        final review = LessonReview(
          reviewId: '',
          lessonSessionId: lessonSessionId,
          studentUid: studentUid,
          studentName: studentName,
          teacherUid: teacherUid,
          teacherName: teacherName,
          rating: rating,
          impression: impression.trim(),
          messageAndExpectation: messageAndExpectation?.trim(),
          createdAt: DateTime.now(),
        );

        final saved = await _repo.createReview(review);
        state = state.copyWith(
          isSubmitting: false,
          reviews: [saved, ...state.reviews],
          successMessage: 'Terima kasih! Ulasan les Anda berhasil disimpan.',
        );
        return true;
      }
    } on DuplicateReviewException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Terjadi kesalahan saat menyimpan ulasan: $e',
      );
      return false;
    }
  }
}

final lessonReviewNotifierProvider =
    NotifierProvider<LessonReviewNotifier, LessonReviewState>(
  LessonReviewNotifier.new,
);
