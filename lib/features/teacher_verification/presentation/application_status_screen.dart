import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_notifier.dart';
import '../../auth/domain/user_role.dart';

class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isRejected = user?.teacherStatus == TeacherApplicationStatus.rejected;
    final teacherName = user?.name ?? 'Calon Guru';
    final rejectionReason = user?.rejectionReason ??
        'Dokumen yang diunggah belum memenuhi persyaratan kualifikasi minimum.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Status Pendaftaran Guru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              context.go('/welcome');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Status Icon Indicator
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: isRejected
                        ? AppColors.errorLight
                        : AppColors.warningLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isRejected ? AppColors.error : AppColors.warning)
                            .withValues(alpha: 0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRejected
                        ? Icons.cancel_outlined
                        : Icons.hourglass_top_rounded,
                    size: 46,
                    color: isRejected ? AppColors.error : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isRejected
                    ? 'Pendaftaran Belum Dapat Disetujui'
                    : 'Pendaftaran Sedang Ditinjau',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Center(
                child: StatusBadge(
                  status: isRejected ? 'rejected' : 'pending',
                  customLabel: isRejected
                      ? 'Status: Ditolak'
                      : 'Status: Menunggu Verifikasi Admin',
                ),
              ),
              const SizedBox(height: 24),

              // Detail Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            teacherName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'guru@temuguru.id',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Divider(height: 24),

                      if (isRejected) ...[
                        const Text(
                          'Catatan / Alasan Penolakan dari Admin:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            rejectionReason,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F1D1D),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Anda dapat melengkapi kembali dokumen yang sesuai atau menghubungi tim support Temu Guru.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Informasi Proses Peninjauan:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildVerificationStep(
                          stepNumber: '1',
                          title: 'Pemeriksaan NIK & Identitas',
                          isDone: true,
                        ),
                        const SizedBox(height: 10),
                        _buildVerificationStep(
                          stepNumber: '2',
                          title: 'Verifikasi Dokumen Sertifikat CEFR (Min. B2)',
                          isDone: false,
                          isCurrent: true,
                        ),
                        const SizedBox(height: 10),
                        _buildVerificationStep(
                          stepNumber: '3',
                          title: 'Persetujuan Akun Pengajar oleh Admin',
                          isDone: false,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Proses verifikasi biasanya memerlukan waktu 1-3 hari kerja. Anda belum dapat mengelola sesi les sampai akun disetujui.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryDark,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Bottom Actions
              if (!isRejected) ...[
                CustomButton(
                  text: 'Cek Status Verifikasi Terbaru',
                  icon: Icons.sync_rounded,
                  variant: ButtonVariant.primary,
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).refreshTeacherStatus();
                    if (!context.mounted) return;
                    final updatedUser = ref.read(authNotifierProvider).user;
                    if (updatedUser != null && updatedUser.isTeacherApproved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selamat! Pendaftaran Anda telah disetujui.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.go('/teacher/dashboard');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status belum berubah. Pendaftaran Anda masih dalam peninjauan.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (isRejected) ...[
                CustomButton(
                  text: 'Daftar Ulang / Perbarui Dokumen',
                  icon: Icons.refresh_rounded,
                  variant: ButtonVariant.primary,
                  onPressed: () {
                    context.push('/register/teacher');
                  },
                ),
                const SizedBox(height: 12),
              ],

              CustomButton(
                text: 'Keluar ke Halaman Utama',
                icon: Icons.logout_rounded,
                variant: ButtonVariant.outline,
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go('/welcome');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStep({
    required String stepNumber,
    required String title,
    required bool isDone,
    bool isCurrent = false,
  }) {
    Color circleColor;
    Widget leadingWidget;

    if (isDone) {
      circleColor = AppColors.successLight;
      leadingWidget = const Icon(Icons.check, size: 16, color: AppColors.success);
    } else if (isCurrent) {
      circleColor = AppColors.warningLight;
      leadingWidget = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
        ),
      );
    } else {
      circleColor = Colors.grey.shade200;
      leadingWidget = Text(
        stepNumber,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: leadingWidget),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
              color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
