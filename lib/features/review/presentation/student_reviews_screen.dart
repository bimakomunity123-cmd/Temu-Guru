import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/data/auth_notifier.dart';
import '../../daily_report/data/daily_report_notifier.dart';
import '../../daily_report/domain/lesson_report.dart';
import '../data/lesson_review_notifier.dart';
import '../domain/lesson_review.dart';
import 'create_review_screen.dart';

class StudentReviewsScreen extends ConsumerStatefulWidget {
  const StudentReviewsScreen({super.key});

  @override
  ConsumerState<StudentReviewsScreen> createState() => _StudentReviewsScreenState();
}

class _StudentReviewsScreenState extends ConsumerState<StudentReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = ref.read(authNotifierProvider).user;
    final studentUid = user?.uid ?? 'student-001';
    ref.read(dailyReportNotifierProvider.notifier).loadReportsForStudent(studentUid);
    ref.read(lessonReviewNotifierProvider.notifier).loadReviewsForStudent(studentUid);
  }

  void _openReviewForm(LessonReport report, LessonReview? existingReview) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReviewScreen(
          report: report,
          existingReview: existingReview,
        ),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(dailyReportNotifierProvider);
    final reviewState = ref.watch(lessonReviewNotifierProvider);

    final completedReports = reportState.reports;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ulasan Setelah Les'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali ke Dashboard',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/student/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.rate_review_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Evaluasi Sesi Belajar Anda',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Beri ulasan dan rating pada setiap sesi les yang telah selesai demi mutu belajar terbaik.',
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Daftar Sesi Les Selesai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (reportState.isLoading || reviewState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (completedReports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.event_available_rounded,
                              size: 48, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text(
                            'Belum Ada Sesi Les yang Selesai',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Ulasan hanya dapat diberikan setelah tutor menyelesaikan sesi pembelajaran dan mengirimkan laporan sesi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...completedReports.map((report) {
                    final existingReview =
                        reviewState.getReviewForSession(report.reportId);
                    final isReviewed = existingReview != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isReviewed
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Pertemuan Ke-${report.meetingNumber}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isReviewed
                                        ? AppColors.successLight
                                        : AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isReviewed
                                            ? Icons.check_circle_rounded
                                            : Icons.pending_actions_rounded,
                                        size: 13,
                                        color: isReviewed
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isReviewed ? 'Sudah Diulas' : 'Belum Diulas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isReviewed
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              report.materialsCovered,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tutor: ${report.teacherName} • ${AppDateFormatter.formatShort(report.lessonDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),

                            // If already reviewed, display review snippet
                            if (isReviewed) ...[
                              const Divider(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              i < existingReview.rating
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${existingReview.rating}.0 / 5.0',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (existingReview.isEdited)
                                          const Text(
                                            '(Diedit)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textTertiary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '"${existingReview.impression}"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                    if (existingReview.messageAndExpectation != null &&
                                        existingReview.messageAndExpectation!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Harapan: "${existingReview.messageAndExpectation}"',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: isReviewed
                                  ? OutlinedButton.icon(
                                      onPressed: () =>
                                          _openReviewForm(report, existingReview),
                                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                                      label: const Text('Edit Ulasan'),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: () =>
                                          _openReviewForm(report, null),
                                      icon: const Icon(Icons.star_outline_rounded, size: 16),
                                      label: const Text('Tulis Ulasan Sesi'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
