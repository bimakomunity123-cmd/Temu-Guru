import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/data/auth_notifier.dart';
import '../../daily_report/domain/lesson_report.dart';
import '../data/lesson_review_notifier.dart';
import '../domain/lesson_review.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final LessonReport report;
  final LessonReview? existingReview;

  const CreateReviewScreen({
    super.key,
    required this.report,
    this.existingReview,
  });

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _rating;
  late TextEditingController _impressionController;
  late TextEditingController _messageController;
  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _impressionController =
        TextEditingController(text: widget.existingReview?.impression ?? '');
    _messageController = TextEditingController(
        text: widget.existingReview?.messageAndExpectation ?? '');
  }

  @override
  void dispose() {
    _impressionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Kurang Memuaskan 🙁';
      case 2:
        return 'Cukup Baik 😐';
      case 3:
        return 'Baik & Komunikatif 🙂';
      case 4:
        return 'Sangat Memuaskan 😊';
      case 5:
        return 'Luar Biasa & Sangat Terbantu! 🌟';
      default:
        return '';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rating 1 sampai 5 bintang.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(authNotifierProvider).user;
    final studentUid = user?.uid ?? widget.report.studentUid;
    final studentName = user?.name ?? widget.report.studentName;

    final success = await ref
        .read(lessonReviewNotifierProvider.notifier)
        .submitOrUpdateReview(
          existingReviewId: widget.existingReview?.reviewId,
          lessonSessionId: widget.report.reportId,
          studentUid: studentUid,
          studentName: studentName,
          teacherUid: widget.report.teacherUid,
          teacherName: widget.report.teacherName,
          rating: _rating,
          impression: _impressionController.text,
          messageAndExpectation: _messageController.text,
        );

    if (!mounted) return;

    if (success) {
      final isEdit = widget.existingReview != null;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                isEdit ? 'Ulasan Berhasil Diperbarui!' : 'Ulasan Berhasil Dikirim!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Terima kasih telah memberikan evaluasi untuk ${widget.report.teacherName}. Ulasan Anda sangat berharga untuk meningkatkan kualitas pembelajaran.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Kembali ke Dashboard',
                variant: ButtonVariant.primary,
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, true); // Return to previous screen
                },
              ),
            ],
          ),
        ),
      );
    } else {
      final error = ref.read(lessonReviewNotifierProvider).errorMessage ??
          'Gagal mengirim ulasan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authNotifierProvider).user;
    final studentName = authUser?.name ?? widget.report.studentName;
    final reviewState = ref.watch(lessonReviewNotifierProvider);
    final isEdit = widget.existingReview != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Ulasan Setelah Les' : 'Ulasan Setelah Les'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pertemuan Ke-${widget.report.meetingNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Sesi Les Selesai',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.report.materialsCovered,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppDateFormatter.formatShort(widget.report.lessonDate)} • ${widget.report.startTime} - ${widget.report.endTime} WIB',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Read-only Student Account Field
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nama Siswa (Otomatis dari Akun)',
                              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Tooltip(
                        message: 'Terkunci otomatis demi validitas ulasan',
                        child: Icon(Icons.lock_outline_rounded,
                            size: 18, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Read-only Teacher Field
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Guru Pembimbing yang Dinilai',
                              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                            Text(
                              widget.report.teacherName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Tooltip(
                        message: 'Diambil dari sesi les terkait',
                        child: Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Star Rating Selection (Mandatory 1-5)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Beri Nilai Sesi Belajar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bagaimana kualitas penjelasan dan interaksi tutor hari ini?',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            final isFilled = star <= _rating;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = star;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 44,
                                  color: isFilled ? Colors.amber : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getRatingDescription(_rating),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Impression (Kesan Belajar - Wajib)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Kesan Belajar Bersama Guru',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tuliskan hal yang Anda sukai dari metode mengajar, materi, atau pemahaman baru yang didapat.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _impressionController,
                          maxLines: 4,
                          maxLength: _maxChars,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Tutor sangat sabar saat saya latihan speaking, dan koreksi grammar diberikan dengan cara yang mudah dimengerti...',
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Kesan belajar wajib diisi.';
                            }
                            if (val.trim().length < 5) {
                              return 'Mohon tuliskan minimal 5 karakter.';
                            }
                            if (val.length > _maxChars) {
                              return 'Maksimal $_maxChars karakter.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Message and Expectation (Opsional)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Pesan dan Harapan untuk Sesi Selanjutnya',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '(Opsional)',
                              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ada topik khusus atau target yang ingin dipelajari pada pertemuan berikutnya?',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          maxLength: _maxChars,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Saya ingin latihan lebih banyak simulasi speaking part 3 dan grammar tenses...',
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) {
                            if (val != null && val.length > _maxChars) {
                              return 'Maksimal $_maxChars karakter.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Privacy Notice Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined,
                          size: 18, color: AppColors.textTertiary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Privasi Terjaga: Identitas Anda disamarkan saat ulasan ditampilkan kepada publik (cth: "Ahmad F.").',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  text: isEdit ? 'Simpan Perubahan Ulasan' : 'Kirim Ulasan Les',
                  icon: isEdit ? Icons.save_rounded : Icons.send_rounded,
                  isLoading: reviewState.isSubmitting,
                  variant: ButtonVariant.primary,
                  onPressed: reviewState.isSubmitting ? null : _handleSubmit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
