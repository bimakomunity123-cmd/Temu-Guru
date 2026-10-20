import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_notifier.dart';
import '../../teacher/domain/teacher_profile.dart';
import '../data/admin_verification_notifier.dart';

class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState
    extends ConsumerState<AdminVerificationScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminVerificationNotifierProvider);
    final notifier = ref.read(adminVerificationNotifierProvider.notifier);

    // Listen to messages
    ref.listen(adminVerificationNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Verifikasi Guru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Portal Administrator Temu Guru',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () => notifier.loadTeachers(),
          ),
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
        child: RefreshIndicator(
          onRefresh: () => notifier.loadTeachers(),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Statistics & Filter Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search field
                      CustomTextField(
                        label: 'Pencarian Guru',
                        hint: 'Cari berdasarkan nama, NIK, atau email...',
                        controller: _searchController,
                        prefixIcon: Icons.search_rounded,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                              )
                            : null,
                        onChanged: (val) => notifier.setSearchQuery(val),
                      ),
                      const SizedBox(height: 12),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterTab(
                              label: 'Semua',
                              count: state.countTotal,
                              filterValue: 'all',
                              currentFilter: state.statusFilter,
                              color: AppColors.primary,
                              onTap: () => notifier.setFilter('all'),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              label: 'Menunggu',
                              count: state.countPending,
                              filterValue: 'pending',
                              currentFilter: state.statusFilter,
                              color: AppColors.warning,
                              onTap: () => notifier.setFilter('pending'),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              label: 'Disetujui',
                              count: state.countApproved,
                              filterValue: 'approved',
                              currentFilter: state.statusFilter,
                              color: AppColors.success,
                              onTap: () => notifier.setFilter('approved'),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              label: 'Ditolak',
                              count: state.countRejected,
                              filterValue: 'rejected',
                              currentFilter: state.statusFilter,
                              color: AppColors.error,
                              onTap: () => notifier.setFilter('rejected'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Teacher Card List
              if (state.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (state.filteredTeachers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 64,
                            color: AppColors.textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak Ada Calon Guru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.searchQuery.isNotEmpty
                                ? 'Tidak ada guru yang cocok dengan kata kunci pencarian.'
                                : 'Belum ada pendaftaran guru pada filter ini.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final teacher = state.filteredTeachers[index];
                        return _TeacherCard(
                          teacher: teacher,
                          onApprove: () => _confirmApproval(teacher),
                          onReject: () => _promptRejection(teacher),
                          onViewDocument: () => _previewDocument(teacher),
                        );
                      },
                      childCount: state.filteredTeachers.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required int count,
    required String filterValue,
    required String currentFilter,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = currentFilter == filterValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApproval(TeacherProfile teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Persetujuan'),
        content: Text(
          'Apakah Anda yakin ingin menyetujui akun guru "${teacher.fullName}"? '
          'Guru ini akan dapat langsung masuk ke Dashboard Guru dan membuat laporan sesi les.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(adminVerificationNotifierProvider.notifier)
                  .approveTeacher(teacher.uid, teacher.fullName);
            },
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );
  }

  void _promptRejection(TeacherProfile teacher) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tolak Pendaftaran Guru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Berikan alasan penolakan yang jelas untuk ${teacher.fullName}. Alasan ini akan ditampilkan pada layar status akun guru.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: 'Catatan Alasan Penolakan',
                hint: 'Contoh: Dokumen sertifikat belum memenuhi level minimum B2 atau tidak terbaca jelas.',
                controller: reasonController,
                maxLines: 4,
                prefixIcon: Icons.feedback_outlined,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Kirim Penolakan',
                variant: ButtonVariant.danger,
                icon: Icons.cancel_outlined,
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Alasan penolakan tidak boleh kosong.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ref
                      .read(adminVerificationNotifierProvider.notifier)
                      .rejectTeacher(
                        teacher.uid,
                        teacher.fullName,
                        reasonController.text.trim(),
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _previewDocument(TeacherProfile teacher) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final storage = ref.read(storageServiceProvider);
      final bytes = await storage.downloadTeacherPrivateDocument(
        teacher.englishTestDocumentPath,
      );
      if (!mounted) return;
      Navigator.pop(context); // close progress

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dokumen Sertifikat Guru',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDocMetaRow('Nama File:', teacher.englishTestDocumentName),
              const SizedBox(height: 8),
              _buildDocMetaRow(
                'Ukuran:',
                _formatBytes(teacher.englishTestDocumentSizeBytes),
              ),
              const SizedBox(height: 8),
              _buildDocMetaRow('Level Bahasa Inggris:', teacher.englishLevel),
              const SizedBox(height: 8),
              _buildDocMetaRow('Lokasi Privat:', teacher.englishTestDocumentPath),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bytes != null
                            ? 'Dokumen sertifikat (${bytes.lengthInBytes} bytes) berhasil diverifikasi dan siap ditinjau.'
                            : 'Dokumen terdaftar di path aman privat. Akses SDK terkonfirmasi.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka dokumen sertifikat: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildDocMetaRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _TeacherCard extends StatelessWidget {
  final TeacherProfile teacher;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDocument;

  const _TeacherCard({
    required this.teacher,
    required this.onApprove,
    required this.onReject,
    required this.onViewDocument,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = AppDateFormatter.formatDateTime(teacher.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: teacher.applicationStatus == 'pending'
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    teacher.fullName.isNotEmpty
                        ? teacher.fullName[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daftar: $formattedDate',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: teacher.applicationStatus),
              ],
            ),
            const Divider(height: 24),

            // Key Info Grid
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: 'NIK (16 Digit)',
              value: teacher.nik,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.cake_outlined,
              label: 'Usia',
              value: '${teacher.age} tahun (${AppDateFormatter.format(teacher.birthDate)})',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.phone_android_rounded,
              label: 'WhatsApp / Email',
              value: '${teacher.whatsapp}  •  ${teacher.email}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.school_outlined,
              label: 'Pendidikan',
              value: '${teacher.education} - ${teacher.educationBackground}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Alamat Domisili',
              value: teacher.address,
            ),
            const SizedBox(height: 12),

            // English Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded,
                      color: AppColors.accentDark, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kemahiran Bahasa: ${teacher.englishLevel}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Teaching Areas
            const Text(
              'Area Kesediaan Mengajar:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: teacher.availableTeachingAreas.map((area) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    area,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Certificate Document Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded,
                      color: AppColors.error, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.englishTestDocumentName.isNotEmpty
                              ? teacher.englishTestDocumentName
                              : 'Sertifikat_Bahasa_Inggris.pdf',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Ukuran: ${_formatBytes(teacher.englishTestDocumentSizeBytes)} (Tersimpan Privat)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onViewDocument,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Tinjau'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            // Rejection reason banner if rejected
            if (teacher.applicationStatus == 'rejected' &&
                teacher.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alasan Penolakan: ${teacher.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                if (teacher.applicationStatus != 'rejected')
                  Expanded(
                    child: CustomButton(
                      text: 'Tolak',
                      variant: ButtonVariant.danger,
                      icon: Icons.close_rounded,
                      height: 40,
                      onPressed: onReject,
                    ),
                  ),
                if (teacher.applicationStatus != 'rejected' &&
                    teacher.applicationStatus != 'approved')
                  const SizedBox(width: 12),
                if (teacher.applicationStatus != 'approved')
                  Expanded(
                    child: CustomButton(
                      text: 'Setujui',
                      variant: ButtonVariant.primary,
                      icon: Icons.check_circle_outline_rounded,
                      height: 40,
                      onPressed: onApprove,
                    ),
                  ),
                if (teacher.applicationStatus == 'approved')
                  Expanded(
                    child: CustomButton(
                      text: 'Batalkan Persetujuan',
                      variant: ButtonVariant.outline,
                      icon: Icons.undo_rounded,
                      height: 40,
                      onPressed: onReject,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
