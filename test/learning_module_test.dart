import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ruangguru/features/learning_module/domain/learning_module.dart';
import 'package:flutter_ruangguru/features/learning_module/data/learning_module_repository.dart';

void main() {
  group('Feature B: LearningModule Model Tests', () {
    test('LearningModule toMap and fromMap preserves all fields correctly', () {
      final now = DateTime(2026, 10, 20, 10, 0);
      final module = LearningModule(
        moduleId: 'mod-grammar-test',
        title: 'Buku Saku Grammar',
        description: 'Panduan lengkap tenses & pola kalimat.',
        category: 'Grammar',
        version: 'v2.1',
        pdfUrl: 'https://example.com/storage/grammar_v2.pdf',
        fileSizeBytes: 2450000,
        totalPages: 48,
        updatedAt: now,
        isPublished: true,
        isFlagship: true,
      );

      final map = module.toMap();
      expect(map['moduleId'], 'mod-grammar-test');
      expect(map['title'], 'Buku Saku Grammar');
      expect(map['category'], 'Grammar');
      expect(map['version'], 'v2.1');
      expect(map['isFlagship'], true);
      expect(map['totalPages'], 48);

      final restored = LearningModule.fromMap(map, 'mod-grammar-test');
      expect(restored.moduleId, module.moduleId);
      expect(restored.title, module.title);
      expect(restored.description, module.description);
      expect(restored.category, module.category);
      expect(restored.version, module.version);
      expect(restored.pdfUrl, module.pdfUrl);
      expect(restored.fileSizeBytes, 2450000);
      expect(restored.totalPages, 48);
      expect(restored.isFlagship, true);
    });

    test('formattedFileSize converts bytes to readable KB/MB', () {
      final smallModule = LearningModule(
        moduleId: '1',
        title: 'Vocab',
        description: 'desc',
        category: 'Vocabulary',
        version: 'v1.0',
        pdfUrl: 'https://example.com/pdf',
        fileSizeBytes: 512 * 1024, // 512 KB
        totalPages: 10,
        updatedAt: DateTime.now(),
      );
      expect(smallModule.formattedFileSize, '512.0 KB');

      final largeModule = LearningModule(
        moduleId: '2',
        title: 'Grammar Book',
        description: 'desc',
        category: 'Grammar',
        version: 'v2.0',
        pdfUrl: 'https://example.com/pdf',
        fileSizeBytes: 2500000, // ~2.4 MB
        totalPages: 48,
        updatedAt: DateTime.now(),
      );
      expect(largeModule.formattedFileSize, contains('MB'));
    });
  });

  group('Feature B: LearningModule Repository Tests', () {
    late InMemoryLearningModuleRepository repository;

    setUp(() {
      repository = InMemoryLearningModuleRepository();
    });

    test('Initial repository contains flagship Buku Saku Grammar', () async {
      final modules = await repository.getModules();
      expect(modules, isNotEmpty);

      final grammarModule = modules.firstWhere((m) => m.isFlagship);
      expect(grammarModule.title, contains('Buku Saku Grammar'));
      expect(grammarModule.category, 'Grammar');
      expect(grammarModule.version, 'v2.1');
      expect(grammarModule.pdfUrl, isNotEmpty);
    });

    test('Categories list contains all available subjects', () async {
      final categories = await repository.getCategories();
      expect(categories, contains('Semua Kategori'));
      expect(categories, contains('Grammar'));
      expect(categories, contains('Vocabulary'));
      expect(categories, contains('Speaking'));
    });

    test('Filtering by category returns only modules of that category', () async {
      final vocabList = await repository.getModules(category: 'Vocabulary');
      expect(vocabList, isNotEmpty);
      expect(vocabList.every((m) => m.category == 'Vocabulary'), isTrue);
    });

    test('Saving and updating a module preserves version and details', () async {
      final newMod = LearningModule(
        moduleId: 'mod-custom-01',
        title: 'TOEFL Listening Tricks',
        description: 'Audio tips & tricks for TOEFL.',
        category: 'Exam Preparation',
        version: 'v1.1',
        pdfUrl: 'https://cdn.example.com/toefl.pdf',
        fileSizeBytes: 1200000,
        totalPages: 24,
        updatedAt: DateTime.now(),
      );

      await repository.saveModule(newMod);
      final fetched = await repository.getModuleById('mod-custom-01');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'TOEFL Listening Tricks');
      expect(fetched.version, 'v1.1');
    });
  });
}
