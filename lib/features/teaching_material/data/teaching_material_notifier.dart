import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/teaching_material.dart';
import 'teaching_material_repository.dart';

class TeachingMaterialState {
  final List<TeachingMaterial> materials;
  final List<String> availableLevels;
  final String selectedLevel;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const TeachingMaterialState({
    this.materials = const [],
    this.availableLevels = const ['Semua Level'],
    this.selectedLevel = 'Semua Level',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  List<TeachingMaterial> get filteredMaterials {
    return materials.where((m) {
      if (selectedLevel != 'Semua Level' && m.level != selectedLevel) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchTitle = m.title.toLowerCase().contains(q);
        final matchDesc = m.description?.toLowerCase().contains(q) ?? false;
        final matchMeeting = 'pertemuan ${m.meetingNumber}'.contains(q) ||
            'meeting ${m.meetingNumber}'.contains(q);
        if (!matchTitle && !matchDesc && !matchMeeting) return false;
      }
      return true;
    }).toList();
  }

  /// Groups filtered materials by meeting number
  Map<int, List<TeachingMaterial>> get materialsByMeeting {
    final map = <int, List<TeachingMaterial>>{};
    for (final mat in filteredMaterials) {
      map.putIfAbsent(mat.meetingNumber, () => []).add(mat);
    }
    return map;
  }

  TeachingMaterialState copyWith({
    List<TeachingMaterial>? materials,
    List<String>? availableLevels,
    String? selectedLevel,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TeachingMaterialState(
      materials: materials ?? this.materials,
      availableLevels: availableLevels ?? this.availableLevels,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TeachingMaterialNotifier extends Notifier<TeachingMaterialState> {
  late final TeachingMaterialRepository _repo;

  @override
  TeachingMaterialState build() {
    _repo = ref.watch(teachingMaterialRepositoryProvider);
    // Automatically trigger initial load
    Future.microtask(() => loadInitialData());
    return const TeachingMaterialState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final levels = await _repo.getAvailableLevels();
      final items = await _repo.getMaterials(level: state.selectedLevel);
      state = state.copyWith(
        isLoading: false,
        availableLevels: levels,
        materials: items,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat bahan ajar: $e',
      );
    }
  }

  Future<void> changeLevel(String level) async {
    if (state.selectedLevel == level) return;
    state = state.copyWith(selectedLevel: level, isLoading: true, errorMessage: null);
    try {
      final items = await _repo.getMaterials(level: level);
      state = state.copyWith(
        materials: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat materi untuk level $level',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> openMaterialUrl(BuildContext context, TeachingMaterial material) async {
    final urlString = material.externalUrl.trim();
    if (urlString.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tautan materi belum tersedia.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    final uri = Uri.tryParse(urlString);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format tautan Google Drive tidak valid.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka tautan: $urlString'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return launched;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka browser / Google Drive: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}

final teachingMaterialNotifierProvider =
    NotifierProvider<TeachingMaterialNotifier, TeachingMaterialState>(
  TeachingMaterialNotifier.new,
);
