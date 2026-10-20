import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/learning_module_notifier.dart';
import '../domain/learning_module.dart';
import 'pdf_viewer_screen.dart';

class StudentModulesScreen extends ConsumerStatefulWidget {
  const StudentModulesScreen({super.key});

  @override
  ConsumerState<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends ConsumerState<StudentModulesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPdfViewer(LearningModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(module: module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningModuleNotifierProvider);
    final notifier = ref.read(learningModuleNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modul Belajar Siswa'),
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
            onPressed: () => notifier.loadInitialData(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Category Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Cari modul, materi, atau topik...',
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

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: state.categories.map((cat) {
                        final isSelected = state.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => notifier.changeCategory(cat),
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

            // Cloud Storage Info Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_download_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modul PDF dimuat langsung dari cloud storage resmi Temu Guru.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main List
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
                          : state.filteredModules.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(32),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.menu_book_rounded,
                                            size: 56, color: AppColors.textTertiary),
                                        SizedBox(height: 12),
                                        Text(
                                          'Tidak ada modul ditemukan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Silakan ubah filter kategori atau kata kunci pencarian.',
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
                                  itemCount: state.filteredModules.length,
                                  itemBuilder: (context, index) {
                                    final module = state.filteredModules[index];
                                    if (module.isFlagship && index == 0 && state.searchQuery.isEmpty) {
                                      return _buildFlagshipCard(context, module);
                                    }
                                    return _buildStandardModuleCard(context, module);
                                  },
                                ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Special featured Hero card for the Stage 1 primary module: Buku Saku Grammar
  Widget _buildFlagshipCard(BuildContext context, LearningModule module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openPdfViewer(module),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'MODUL UTAMA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Versi ${module.version}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  module.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  module.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'PDF • ${module.totalPages} Hal • ${module.formattedFileSize}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      'Update: ${AppDateFormatter.formatShort(module.updatedAt)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openPdfViewer(module),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Buka Buku Saku PDF (In-App)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardModuleCard(BuildContext context, LearningModule module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    module.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    module.version,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppDateFormatter.formatShort(module.updatedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              module.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              module.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${module.totalPages} Halaman • ${module.formattedFileSize}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _openPdfViewer(module),
                  icon: const Icon(Icons.auto_stories_rounded, size: 14),
                  label: const Text('Baca Modul'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
