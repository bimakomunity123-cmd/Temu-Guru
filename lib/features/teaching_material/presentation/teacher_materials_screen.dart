import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/teaching_material_notifier.dart';
import '../domain/teaching_material.dart';

class TeacherMaterialsScreen extends ConsumerStatefulWidget {
  const TeacherMaterialsScreen({super.key});

  @override
  ConsumerState<TeacherMaterialsScreen> createState() =>
      _TeacherMaterialsScreenState();
}

class _TeacherMaterialsScreenState
    extends ConsumerState<TeacherMaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDrivePermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Izin Google Drive', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seluruh materi dan slide presentasi tersimpan terpusat di Google Drive Resmi Tim Akademik.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Petunjuk Akses:\n'
              '1. Pastikan Anda telah login ke akun Google yang terdaftar.\n'
              '2. Jika muncul pesan "Memerlukan Akses", silakan ajukan izin atau hubungi Admin Koordinator Akademik.\n'
              '3. Tautan materi akan langsung dibuka melalui aplikasi Google Drive atau Browser Anda.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teachingMaterialNotifierProvider);
    final notifier = ref.read(teachingMaterialNotifierProvider.notifier);

    final meetingMap = state.materialsByMeeting;
    final sortedMeetings = meetingMap.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bahan Ajar Guru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali ke Dashboard',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/teacher/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Panduan Izin Google Drive',
            onPressed: () => _showDrivePermissionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: () => notifier.loadInitialData(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header / Search & Filter Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Cari topik, pertemuan, atau materi...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Level Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: state.availableLevels.map((lvl) {
                        final isSelected = state.selectedLevel == lvl;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(lvl),
                            selected: isSelected,
                            onSelected: (_) => notifier.changeLevel(lvl),
                            selectedColor: AppColors.primaryContainer,
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            backgroundColor: AppColors.surfaceVariant,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Google Drive Cloud Storage Note Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: AppColors.accentDark, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tersimpan aman di Google Drive. Klik tautan untuk membuka via Drive / Browser.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showDrivePermissionDialog(context),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Izin Akses', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: () => notifier.loadInitialData(),
                      color: AppColors.primary,
                      child: state.errorMessage != null
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        size: 48, color: AppColors.error),
                                    const SizedBox(height: 12),
                                    Text(
                                      state.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => notifier.loadInitialData(),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Coba Lagi'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : sortedMeetings.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(32),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.folder_off_rounded,
                                            size: 56, color: AppColors.textTertiary),
                                        SizedBox(height: 12),
                                        Text(
                                          'Tidak ada bahan ajar ditemukan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Coba ubah kata kunci pencarian atau filter level.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  itemCount: sortedMeetings.length,
                                  itemBuilder: (context, index) {
                                    final meetingNum = sortedMeetings[index];
                                    final materials = meetingMap[meetingNum] ?? [];
                                    return _buildMeetingSection(context, meetingNum, materials, notifier);
                                  },
                                ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingSection(
    BuildContext context,
    int meetingNum,
    List<TeachingMaterial> materials,
    TeachingMaterialNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pertemuan $meetingNum',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    materials.isNotEmpty ? materials.first.level : '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${materials.length} Materi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Items inside this meeting
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: materials.map((item) {
                return _buildMaterialCard(context, item, notifier);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(
    BuildContext context,
    TeachingMaterial item,
    TeachingMaterialNotifier notifier,
  ) {
    final isGuide = item.materialType == 'petunjuk_ajar';
    final cardColor = isGuide
        ? AppColors.primary.withValues(alpha: 0.04)
        : AppColors.accent.withValues(alpha: 0.04);
    final borderColor = isGuide
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.accent.withValues(alpha: 0.3);
    final icon = isGuide ? Icons.menu_book_rounded : Icons.slideshow_rounded;
    final iconColor = isGuide ? AppColors.primary : AppColors.accentDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        item.typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.update_rounded, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Update: ${AppDateFormatter.formatShort(item.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => notifier.openMaterialUrl(context, item),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(
                  isGuide ? 'Buka Petunjuk' : 'Buka Slides',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 34),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
