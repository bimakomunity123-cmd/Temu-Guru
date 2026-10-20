import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/data/auth_notifier.dart';
import '../data/daily_report_notifier.dart';
import '../data/daily_report_repository.dart';
import '../domain/lesson_report.dart';

class CreateLessonReportScreen extends ConsumerStatefulWidget {
  final LessonReport? initialReport; // If provided, edit mode

  const CreateLessonReportScreen({super.key, this.initialReport});

  @override
  ConsumerState<CreateLessonReportScreen> createState() =>
      _CreateLessonReportScreenState();
}

class _CreateLessonReportScreenState
    extends ConsumerState<CreateLessonReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  Map<String, String>? _selectedStudent;
  List<Map<String, String>> _studentsList = [];
  bool _isLoadingStudents = true;

  DateTime _lessonDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 15, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  int _meetingNumber = 1;
  final _locationController = TextEditingController();
  final _materialsController = TextEditingController();
  final _commentsController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  String? _timeErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();

    if (widget.initialReport != null) {
      final r = widget.initialReport!;
      _lessonDate = r.lessonDate;
      _meetingNumber = r.meetingNumber;
      _locationController.text = r.meetingLocation;
      _materialsController.text = r.materialsCovered;
      _commentsController.text = r.sessionComments;
      _additionalNotesController.text = r.additionalNotes ?? '';

      // Parse start and end time
      try {
        final startParts = r.startTime.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
        final endParts = r.endTime.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      } catch (_) {}
    } else {
      _locationController.text = 'Kediaman Siswa';
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _materialsController.dispose();
    _commentsController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final user = ref.read(authNotifierProvider).user;
    final teacherUid = user?.uid ?? 'teacher-001';
    final repo = ref.read(dailyReportRepositoryProvider);

    try {
      final students = await repo.getAssignedStudents(teacherUid);
      if (mounted) {
        setState(() {
          _studentsList = students;
          _isLoadingStudents = false;
          if (widget.initialReport != null) {
            _selectedStudent = students.firstWhere(
              (s) => s['uid'] == widget.initialReport!.studentUid,
              orElse: () => {
                'uid': widget.initialReport!.studentUid,
                'name': widget.initialReport!.studentName,
                'program': 'General English',
              },
            );
          } else if (students.isNotEmpty) {
            _selectedStudent = students.first;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  bool _validateTimes() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      setState(() {
        _timeErrorMessage =
            'Waktu selesai harus setelah waktu mulai (durasi minimal 15 menit).';
      });
      return false;
    }

    setState(() {
      _timeErrorMessage = null;
    });
    return true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lessonDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      helpText: 'Pilih Tanggal Pertemuan Les',
    );
    if (picked != null) {
      setState(() => _lessonDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Pilih Waktu Mulai',
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _validateTimes();
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Pilih Waktu Selesai',
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _validateTimes();
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateTimes()) return;

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih siswa yang diajar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(authNotifierProvider).user;
    final teacherUid = user?.uid ?? 'teacher-001';
    final teacherName = user?.name ?? 'Sarah Jenkins, S.Pd';

    final report = LessonReport(
      reportId: widget.initialReport?.reportId ?? '',
      teacherUid: teacherUid,
      teacherName: teacherName,
      studentUid: _selectedStudent!['uid']!,
      studentName: _selectedStudent!['name']!,
      lessonDate: _lessonDate,
      meetingLocation: _locationController.text.trim(),
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      meetingNumber: _meetingNumber,
      materialsCovered: _materialsController.text.trim(),
      sessionComments: _commentsController.text.trim(),
      additionalNotes: _additionalNotesController.text.trim().isNotEmpty
          ? _additionalNotesController.text.trim()
          : null,
      createdAt: widget.initialReport?.createdAt ?? DateTime.now(),
      updatedAt: widget.initialReport != null ? DateTime.now() : null,
    );

    final isEdit = widget.initialReport != null;
    final notifier = ref.read(dailyReportNotifierProvider.notifier);

    final success = isEdit
        ? await notifier.updateReport(report)
        : await notifier.submitReport(report);

    if (success && mounted) {
      _showSuccessDialog(report.meetingNumber, isEdit);
    }
  }

  void _showSuccessDialog(int meetingNumber, bool isEdit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 28),
            const SizedBox(width: 8),
            Text(isEdit ? 'Laporan Diperbarui' : 'Laporan Tersimpan!'),
          ],
        ),
        content: Text(
          isEdit
              ? 'Perubahan laporan pertemuan ke-$meetingNumber berhasil disimpan.'
              : 'Daily Lesson Report untuk pertemuan ke-$meetingNumber telah berhasil disimpan dan dicatat dalam riwayat belajar siswa.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(); // return to dashboard or history
            },
            child: const Text('OK, Kembali'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(dailyReportNotifierProvider);
    final isEdit = widget.initialReport != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Laporan Pertemuan' : 'Buat Daily Report'),
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
                // Info Card: English Tutoring Session
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Form Daily Lesson Report',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Catat materi, durasi pertemuan, dan evaluasi hasil belajar siswa.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Siswa & Pertemuan
                _buildSectionHeader('1. Data Siswa & Pertemuan'),
                const SizedBox(height: 12),

                // Student Selector
                if (_isLoadingStudents)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else
                  DropdownButtonFormField<Map<String, String>>(
                    initialValue: _selectedStudent,
                    decoration: InputDecoration(
                      labelText: 'Pilih Siswa *',
                      prefixIcon: const Icon(Icons.person_search_rounded,
                          color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _studentsList.map((student) {
                      return DropdownMenuItem<Map<String, String>>(
                        value: student,
                        child: Text(
                          '${student['name']} (${student['program']?.split(' ').first})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedStudent = val);
                    },
                    validator: (val) =>
                        val == null ? 'Pilih siswa terlebih dahulu' : null,
                  ),
                const SizedBox(height: 14),

                // Meeting Number Stepper
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pertemuan Ke *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Nomor urutan sesi les',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: _meetingNumber > 1
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            onPressed: _meetingNumber > 1
                                ? () => setState(() => _meetingNumber--)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_meetingNumber',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: AppColors.primary,
                            onPressed: () => setState(() => _meetingNumber++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Waktu & Lokasi
                _buildSectionHeader('2. Waktu & Lokasi Pertemuan'),
                const SizedBox(height: 12),

                // Date Picker Card
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Pertemuan *',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppDateFormatter.formatFull(_lessonDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Time Pickers (Start & End)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Waktu Mulai *',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimeOfDay(_startTime),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Waktu Selesai *',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.done_all_rounded,
                                      size: 18, color: AppColors.accentDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimeOfDay(_endTime),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_timeErrorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _timeErrorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Location Field
                CustomTextField(
                  label: 'Lokasi Pertemuan *',
                  hint: 'Contoh: Kediaman Siswa (Tebet Barat) / Library / Online',
                  controller: _locationController,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Lokasi pertemuan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Section 3: Materi & Evaluasi
                _buildSectionHeader('3. Materi & Evaluasi Sesi'),
                const SizedBox(height: 12),

                // Materials Covered
                CustomTextField(
                  label: 'Materi yang Diajarkan *',
                  hint: 'Jelaskan topik, modul, latihan speaking, grammar, atau teks yang dibahas...',
                  controller: _materialsController,
                  maxLines: 3,
                  prefixIcon: Icons.library_books_outlined,
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Materi pembelajaran wajib diisi (minimal 5 karakter)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Session Comments / Evaluation
                CustomTextField(
                  label: 'Komentar & Evaluasi Selama Pertemuan *',
                  hint: 'Catat keaktifan, pemahaman kosakata, pronunciation, atau aspek yang berkembang...',
                  controller: _commentsController,
                  maxLines: 4,
                  prefixIcon: Icons.rate_review_outlined,
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Komentar / evaluasi pertemuan wajib diisi (minimal 5 karakter)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Additional Notes (Optional)
                CustomTextField(
                  label: 'Catatan Tambahan / PR (Opsional)',
                  hint: 'Tugas rumah, rekomendasi bacaan, atau persiapan untuk sesi berikutnya...',
                  controller: _additionalNotesController,
                  maxLines: 3,
                  prefixIcon: Icons.note_alt_outlined,
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: isEdit ? 'Simpan Perubahan Laporan' : 'Simpan Daily Report',
                  icon: Icons.check_circle_rounded,
                  isLoading: reportState.isSubmitting,
                  onPressed: reportState.isSubmitting ? null : _handleSubmit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
