import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/learning_module.dart';
import 'learning_module_repository.dart';

class LearningModuleState {
  final List<LearningModule> modules;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const LearningModuleState({
    this.modules = const [],
    this.categories = const ['Semua Kategori'],
    this.selectedCategory = 'Semua Kategori',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  LearningModule? get flagshipModule {
    try {
      return modules.firstWhere((m) => m.isFlagship);
    } catch (_) {
      return modules.isNotEmpty ? modules.first : null;
    }
  }

  List<LearningModule> get filteredModules {
    return modules.where((m) {
      if (selectedCategory != 'Semua Kategori' && m.category != selectedCategory) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchTitle = m.title.toLowerCase().contains(q);
        final matchDesc = m.description.toLowerCase().contains(q);
        final matchCat = m.category.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchCat) return false;
      }
      return true;
    }).toList();
  }

  LearningModuleState copyWith({
    List<LearningModule>? modules,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LearningModuleState(
      modules: modules ?? this.modules,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LearningModuleNotifier extends Notifier<LearningModuleState> {
  late final LearningModuleRepository _repo;

  @override
  LearningModuleState build() {
    _repo = ref.watch(learningModuleRepositoryProvider);
    Future.microtask(() => loadInitialData());
    return const LearningModuleState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cats = await _repo.getCategories();
      final items = await _repo.getModules(category: state.selectedCategory);
      state = state.copyWith(
        isLoading: false,
        categories: cats,
        modules: items,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat modul belajar: $e',
      );
    }
  }

  Future<void> changeCategory(String category) async {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category, isLoading: true, errorMessage: null);
    try {
      final items = await _repo.getModules(category: category);
      state = state.copyWith(
        modules: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat modul untuk kategori $category',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final learningModuleNotifierProvider =
    NotifierProvider<LearningModuleNotifier, LearningModuleState>(
  LearningModuleNotifier.new,
);
