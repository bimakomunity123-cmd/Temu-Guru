import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/data/auth_notifier.dart';
import '../data/daily_report_notifier.dart';
import '../domain/lesson_report.dart';
import 'create_lesson_report_screen.dart';
import 'lesson_report_detail_screen.dart';

class LessonReportHistoryScreen extends ConsumerStatefulWidget {
  const LessonReportHistoryScreen({super.key});

  @override
  ConsumerState<LessonReportHistoryScreen> createState() =>
      _LessonReportHistoryScreenState();
}

class _LessonReportHistoryScreenState
    extends ConsumerState<LessonReportHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final user = ref.read(authNotifierProvider).user;
    final teacherUid = user?.uid ?? 'teacher-001';
    ref.read(dailyReportNotifierProvider.notifier).loadReportsForTeacher(teacherUid);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyReportNotifierProvider);
    final notifier = ref.read(dailyReportNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Daily Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateLessonReportScreen(),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Buat Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Search and Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        label: 'Cari Laporan',
                        hint: 'Cari berdasarkan nama siswa, materi, atau lokasi...',
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
                            _buildFilterChip('Semua Sesi', 'all', state.dateFilter,
                                (val) => notifier.setDateFilter(val)),
                            const SizedBox(width: 8),
                            _buildFilterChip('Hari Ini', 'today', state.dateFilter,
                                (val) => notifier.setDateFilter(val)),
                            const SizedBox(width: 8),
                            _buildFilterChip('7 Hari Terakhir', '7days',
                                state.dateFilter, (val) => notifier.setDateFilter(val)),
                            const SizedBox(width: 8),
                            _buildFilterChip('30 Hari Terakhir', '30days',
                                state.dateFilter, (val) => notifier.setDateFilter(val)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Reports List
              if (state.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (state.filteredReports.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: AppColors.textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum Ada Laporan Sesi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.searchQuery.isNotEmpty
                                ? 'Tidak ada laporan yang cocok dengan kata kunci pencarian.'
                                : 'Klik tombol di bawah untuk membuat laporan pertemuan baru.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'Buat Laporan Sekarang',
                            icon: Icons.add_rounded,
                            width: 220,
                            height: 44,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateLessonReportScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final report = state.filteredReports[index];
                        return _ReportCard(
                          report: report,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LessonReportDetailScreen(report: report),
                              ),
                            ).then((_) => _loadData());
                          },
                        );
                      },
                      childCount: state.filteredReports.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final LessonReport report;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = AppDateFormatter.format(report.lessonDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Meeting number tag & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pertemuan #${report.meetingNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${report.startTime} - ${report.endTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Student Name
              Row(
                children: [
                  const Icon(Icons.person_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.studentName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Date & Location
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.meetingLocation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Materials Preview
              Text(
                'Materi: ${report.materialsCovered}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Comments Preview
              Text(
                'Evaluasi: ${report.sessionComments}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
