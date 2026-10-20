import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/learning_module.dart';

abstract class LearningModuleRepository {
  Future<List<LearningModule>> getModules({String? category, bool onlyPublished = true});
  Future<LearningModule?> getModuleById(String moduleId);
  Stream<List<LearningModule>> streamModules({String? category});
  Future<LearningModule> saveModule(LearningModule module);
  Future<void> deleteModule(String moduleId);
  Future<List<String>> getCategories();
}

class InMemoryLearningModuleRepository implements LearningModuleRepository {
  final Map<String, LearningModule> _modules = {};
  final StreamController<List<LearningModule>> _streamController =
      StreamController<List<LearningModule>>.broadcast();

  InMemoryLearningModuleRepository() {
    _seedInitialModules();
  }

  void _seedInitialModules() {
    final now = DateTime.now();

    final seeds = [
      // Primary Flagship Module for Stage 1: Buku Saku Grammar
      LearningModule(
        moduleId: 'mod-grammar-001',
        title: 'Buku Saku Grammar: Panduan Tenses & Pola Kalimat Praktis',
        description:
            'Ringkasan esensial 16 Tenses bahasa Inggris, rumus kalimat aktif-pasif, conditional sentence, dan tips menghindari common grammatical errors saat berbicara dan menulis.',
        category: 'Grammar',
        version: 'v2.1',
        pdfUrl: 'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        fileSizeBytes: 2450000, // ~2.4 MB
        totalPages: 48,
        updatedAt: now.subtract(const Duration(days: 4)),
        isPublished: true,
        isFlagship: true,
      ),

      // Expandable Module 2: Vocabulary
      LearningModule(
        moduleId: 'mod-vocab-002',
        title: 'Essential Oxford 1000 Words & Collocations',
        description:
            'Daftar 1000 kosakata tingkat pemula hingga menengah yang paling sering digunakan dalam percakapan sehari-hari lengkap dengan contoh kalimat dan kolokasi kata.',
        category: 'Vocabulary',
        version: 'v1.4',
        pdfUrl: 'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        fileSizeBytes: 1820000, // ~1.8 MB
        totalPages: 36,
        updatedAt: now.subtract(const Duration(days: 14)),
        isPublished: true,
        isFlagship: false,
      ),

      // Expandable Module 3: Speaking
      LearningModule(
        moduleId: 'mod-speak-003',
        title: 'Daily Conversational English & Idioms Phrasebook',
        description:
            'Panduan ekspresi praktis perkenalan diri, diskusi santai di kafe, expressing opinions, dan 50 idiom populer untuk meningkatkan kelancaran speaking.',
        category: 'Speaking',
        version: 'v1.2',
        pdfUrl: 'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        fileSizeBytes: 1450000, // ~1.4 MB
        totalPages: 28,
        updatedAt: now.subtract(const Duration(days: 20)),
        isPublished: true,
        isFlagship: false,
      ),

      // Expandable Module 4: Exam Preparation
      LearningModule(
        moduleId: 'mod-ielts-004',
        title: 'IELTS Academic Writing Task 1 & 2 Roadmap',
        description:
            'Template paragraf introduction, overview, dan body paragraph untuk grafik data serta panduan essay argumentative dan opinion.',
        category: 'Exam Preparation',
        version: 'v1.0',
        pdfUrl: 'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        fileSizeBytes: 3100000, // ~3.1 MB
        totalPages: 52,
        updatedAt: now.subtract(const Duration(days: 30)),
        isPublished: true,
        isFlagship: false,
      ),
    ];

    for (final m in seeds) {
      _modules[m.moduleId] = m;
    }
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(_modules.values.toList());
    }
  }

  @override
  Future<List<LearningModule>> getModules({String? category, bool onlyPublished = true}) async {
    var list = _modules.values.where((m) {
      if (onlyPublished && !m.isPublished) return false;
      if (category != null && category.isNotEmpty && category != 'Semua Kategori' && m.category != category) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      // Flagship first, then alphabetical or updated date
      if (a.isFlagship != b.isFlagship) {
        return a.isFlagship ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return list;
  }

  @override
  Future<LearningModule?> getModuleById(String moduleId) async {
    return _modules[moduleId];
  }

  @override
  Stream<List<LearningModule>> streamModules({String? category}) async* {
    yield await getModules(category: category);
    yield* _streamController.stream.map((list) {
      var filtered = list.where((m) {
        if (!m.isPublished) return false;
        if (category != null && category.isNotEmpty && category != 'Semua Kategori' && m.category != category) {
          return false;
        }
        return true;
      }).toList();
      filtered.sort((a, b) {
        if (a.isFlagship != b.isFlagship) return a.isFlagship ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return filtered;
    });
  }

  @override
  Future<LearningModule> saveModule(LearningModule module) async {
    final id = module.moduleId.isNotEmpty
        ? module.moduleId
        : 'mod-${DateTime.now().millisecondsSinceEpoch}';
    final saved = module.copyWith(
      moduleId: id,
      updatedAt: DateTime.now(),
    );
    _modules[id] = saved;
    _notify();
    return saved;
  }

  @override
  Future<void> deleteModule(String moduleId) async {
    _modules.remove(moduleId);
    _notify();
  }

  @override
  Future<List<String>> getCategories() async {
    final cats = _modules.values.map((m) => m.category).toSet().toList();
    cats.sort();
    return ['Semua Kategori', ...cats];
  }
}

class FirestoreLearningModuleRepository implements LearningModuleRepository {
  final FirebaseFirestore? _customFirestore;
  final InMemoryLearningModuleRepository _fallback = InMemoryLearningModuleRepository();

  FirestoreLearningModuleRepository([FirebaseFirestore? firestore])
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<LearningModule>> getModules({String? category, bool onlyPublished = true}) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getModules(category: category, onlyPublished: onlyPublished);
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('learningModules');
      if (onlyPublished) {
        query = query.where('isPublished', isEqualTo: true);
      }
      if (category != null && category.isNotEmpty && category != 'Semua Kategori') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return await _fallback.getModules(category: category, onlyPublished: onlyPublished);
      }

      final list = snapshot.docs
          .map((doc) => LearningModule.fromMap(doc.data(), doc.id))
          .toList();

      list.sort((a, b) {
        if (a.isFlagship != b.isFlagship) return a.isFlagship ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    } catch (_) {
      return await _fallback.getModules(category: category, onlyPublished: onlyPublished);
    }
  }

  @override
  Future<LearningModule?> getModuleById(String moduleId) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getModuleById(moduleId);
    }

    try {
      final doc = await _firestore.collection('learningModules').doc(moduleId).get();
      if (!doc.exists || doc.data() == null) return null;
      return LearningModule.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return await _fallback.getModuleById(moduleId);
    }
  }

  @override
  Stream<List<LearningModule>> streamModules({String? category}) async* {
    if (!FirebaseService.isInitialized) {
      yield* _fallback.streamModules(category: category);
      return;
    }

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('learningModules')
          .where('isPublished', isEqualTo: true);

      if (category != null && category.isNotEmpty && category != 'Semua Kategori') {
        query = query.where('category', isEqualTo: category);
      }

      await for (final snapshot in query.snapshots()) {
        if (snapshot.docs.isEmpty) {
          yield await _fallback.getModules(category: category);
        } else {
          final list = snapshot.docs
              .map((doc) => LearningModule.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            if (a.isFlagship != b.isFlagship) return a.isFlagship ? -1 : 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
          yield list;
        }
      }
    } catch (_) {
      yield* _fallback.streamModules(category: category);
    }
  }

  @override
  Future<LearningModule> saveModule(LearningModule module) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.saveModule(module);
    }

    try {
      final collection = _firestore.collection('learningModules');
      final docRef = module.moduleId.isNotEmpty
          ? collection.doc(module.moduleId)
          : collection.doc();

      final data = module.toMap();
      data['moduleId'] = docRef.id;
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data, SetOptions(merge: true));
      return module.copyWith(moduleId: docRef.id, updatedAt: DateTime.now());
    } catch (_) {
      return await _fallback.saveModule(module);
    }
  }

  @override
  Future<void> deleteModule(String moduleId) async {
    if (!FirebaseService.isInitialized) {
      await _fallback.deleteModule(moduleId);
      return;
    }

    try {
      await _firestore.collection('learningModules').doc(moduleId).delete();
    } catch (_) {
      await _fallback.deleteModule(moduleId);
    }
  }

  @override
  Future<List<String>> getCategories() async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getCategories();
    }

    try {
      final snapshot = await _firestore.collection('learningModules').get();
      if (snapshot.docs.isEmpty) {
        return await _fallback.getCategories();
      }
      final cats = snapshot.docs
          .map((d) => (d.data()['category'] as String? ?? 'Umum'))
          .toSet()
          .toList();
      cats.sort();
      return ['Semua Kategori', ...cats];
    } catch (_) {
      return await _fallback.getCategories();
    }
  }
}

final learningModuleRepositoryProvider = Provider<LearningModuleRepository>((ref) {
  if (FirebaseService.isInitialized) {
    return FirestoreLearningModuleRepository();
  }
  return InMemoryLearningModuleRepository();
});
