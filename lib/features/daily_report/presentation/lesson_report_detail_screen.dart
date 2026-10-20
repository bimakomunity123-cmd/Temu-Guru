import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../domain/lesson_report.dart';
import 'create_lesson_report_screen.dart';
import '../../review/presentation/create_review_screen.dart';

class LessonReportDetailScreen extends StatelessWidget {
  final LessonReport report;

  const LessonReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final formattedDate = AppDateFormatter.formatFull(report.lessonDate);
    final formattedCreated = AppDateFormatter.formatDateTime(report.createdAt);
    final formattedUpdated = report.updatedAt != null
        ? AppDateFormatter.formatDateTime(report.updatedAt!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detail Pertemuan #${report.meetingNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Laporan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateLessonReportScreen(initialReport: report),
                ),
              ).then((_) {
                if (!context.mounted) return;
                Navigator.pop(context); // pop to refresh list
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan / Salin Ringkasan',
            onPressed: () => _copySummaryToClipboard(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sesi Pertemuan Ke-${report.meetingNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${report.startTime} - ${report.endTime}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            report.meetingLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Participants Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.accentLight,
                            child: Icon(Icons.person_rounded,
                                color: AppColors.accentDark, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Siswa Bimbingan:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  report.studentName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryContainer,
                            child: Icon(Icons.school_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tutor / Pengajar:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  report.teacherName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Materials Covered Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.library_books_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Materi Pembelajaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        report.materialsCovered,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Session Evaluation Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.rate_review_rounded,
                                color: AppColors.success, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Komentar & Evaluasi Sesi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        report.sessionComments,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Additional Notes (if any)
              if (report.additionalNotes != null &&
                  report.additionalNotes!.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.note_alt_rounded,
                                  color: AppColors.warning, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Catatan Tambahan / PR',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.additionalNotes!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Timestamps Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dibuat pada: $formattedCreated',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (formattedUpdated != null)
                      Text(
                        'Terakhir diperbarui: $formattedUpdated',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              CustomButton(
                text: 'Beri / Lihat Ulasan Sesi',
                icon: Icons.star_rate_rounded,
                variant: ButtonVariant.secondary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateReviewScreen(report: report),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Bagikan Ringkasan Laporan',
                icon: Icons.share_rounded,
                variant: ButtonVariant.primary,
                onPressed: () => _copySummaryToClipboard(context),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Edit Laporan Pertemuan',
                icon: Icons.edit_rounded,
                variant: ButtonVariant.outline,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateLessonReportScreen(initialReport: report),
                    ),
                  ).then((_) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _copySummaryToClipboard(BuildContext context) {
    final formattedDate = AppDateFormatter.formatFull(report.lessonDate);
    final summary = '''
*DAILY LESSON REPORT - TEMU GURU*
Pertemuan: Ke-${report.meetingNumber}
Tanggal: $formattedDate
Waktu: ${report.startTime} - ${report.endTime} WIB
Lokasi: ${report.meetingLocation}
Siswa: ${report.studentName}
Tutor: ${report.teacherName}

*Materi Yang Diajarkan:*
${report.materialsCovered}

*Evaluasi & Perkembangan:*
${report.sessionComments}
${report.additionalNotes != null && report.additionalNotes!.isNotEmpty ? '\n*Catatan / PR:*\n${report.additionalNotes}' : ''}

_Temu Guru - Temukan Guru Terbaik, Belajar di Tempat Pilihanmu._
''';

    Clipboard.setData(ClipboardData(text: summary.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan laporan berhasil disalin ke clipboard! Siap dibagikan ke WhatsApp siswa/wali.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
