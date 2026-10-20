import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../domain/teaching_material.dart';

abstract class TeachingMaterialRepository {
  Future<List<TeachingMaterial>> getMaterials({String? level, bool onlyPublished = true});
  Future<TeachingMaterial?> getMaterialById(String materialId);
  Stream<List<TeachingMaterial>> streamMaterials({String? level});
  Future<TeachingMaterial> saveMaterial(TeachingMaterial material);
  Future<void> deleteMaterial(String materialId);
  Future<List<String>> getAvailableLevels();
}

class InMemoryTeachingMaterialRepository implements TeachingMaterialRepository {
  final Map<String, TeachingMaterial> _materials = {};
  final StreamController<List<TeachingMaterial>> _streamController =
      StreamController<List<TeachingMaterial>>.broadcast();

  InMemoryTeachingMaterialRepository() {
    _seedInitialMaterials();
  }

  void _seedInitialMaterials() {
    final now = DateTime.now();

    final seeds = [
      // Level B1 - Intermediate / General English
      TeachingMaterial(
        materialId: 'mat-001-guide',
        title: 'Petunjuk Ajar: Diagnostic Review & Daily Routine Habits',
        level: 'Intermediate (B1)',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/1_SampleTeacherGuide_B1_M1/view?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 7)),
        isPublished: true,
        description: 'Langkah pembelajaran 90 menit, rubrik observasi siswa, dan communicative warm-up games.',
      ),
      TeachingMaterial(
        materialId: 'mat-001-slides',
        title: 'Slides Presentasi: Present Simple vs Continuous in Real Life',
        level: 'Intermediate (B1)',
        meetingNumber: 1,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/presentation/d/1_SampleSlideDeck_B1_M1/edit?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 7)),
        isPublished: true,
        description: 'Slide interaktif 20 halaman dengan visual prompt, drill audio cue, dan mini quiz.',
      ),
      TeachingMaterial(
        materialId: 'mat-002-guide',
        title: 'Petunjuk Ajar: Past Tense Narratives & Storytelling',
        level: 'Intermediate (B1)',
        meetingNumber: 2,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/1_SampleTeacherGuide_B1_M2/view?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 5)),
        isPublished: true,
        description: 'Strategi mengoreksi irregular verbs secara natural dan aktivitas collaborative storytelling.',
      ),
      TeachingMaterial(
        materialId: 'mat-002-slides',
        title: 'Slides Presentasi: Expressing Past Events & Anecdotes',
        level: 'Intermediate (B1)',
        meetingNumber: 2,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/presentation/d/1_SampleSlideDeck_B1_M2/edit?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 5)),
        isPublished: true,
        description: 'Visual slide timeline tenses, vocabulary cards, dan conversation wheel.',
      ),
      TeachingMaterial(
        materialId: 'mat-003-guide',
        title: 'Petunjuk Ajar: Future Intentions & Conditional Type 1',
        level: 'Intermediate (B1)',
        meetingNumber: 3,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/1_SampleTeacherGuide_B1_M3/view?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 2)),
        isPublished: true,
        description: 'Panduan simulasi percakapan perencanaan karier dan conditional prompt.',
      ),
      TeachingMaterial(
        materialId: 'mat-003-slides',
        title: 'Slides Presentasi: Will vs Going To vs Conditionals',
        level: 'Intermediate (B1)',
        meetingNumber: 3,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/presentation/d/1_SampleSlideDeck_B1_M3/edit?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 2)),
        isPublished: true,
        description: 'Materi presentasi lengkap untuk pertemuan ke-3.',
      ),

      // Level IELTS Academic Preparation
      TeachingMaterial(
        materialId: 'mat-ielts-001-guide',
        title: 'Petunjuk Ajar: IELTS Writing Task 1 Overview & Trends',
        level: 'IELTS Academic',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/1_SampleTeacherGuide_IELTS_M1/view?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 10)),
        isPublished: true,
        description: 'Panduan tutor membedah band descriptors: Task Achievement & Lexical Resource.',
      ),
      TeachingMaterial(
        materialId: 'mat-ielts-001-slides',
        title: 'Slides Presentasi: Visualizing Data & Dynamic Trends',
        level: 'IELTS Academic',
        meetingNumber: 1,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/presentation/d/1_SampleSlideDeck_IELTS_M1/edit?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 10)),
        isPublished: true,
        description: 'Slide visual grafik batang, diagram garis, dan perbandingan tren data.',
      ),
      TeachingMaterial(
        materialId: 'mat-ielts-002-guide',
        title: 'Petunjuk Ajar: Speaking Part 2 Long Turn & Fluency',
        level: 'IELTS Academic',
        meetingNumber: 2,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/1_SampleTeacherGuide_IELTS_M2/view?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 4)),
        isPublished: true,
        description: 'Format timing 1 menit persiapan dan 2 menit bicara, feedback rubrik intonasi.',
      ),
      TeachingMaterial(
        materialId: 'mat-ielts-002-slides',
        title: 'Slides Presentasi: IELTS Speaking Part 2 Cue Cards',
        level: 'IELTS Academic',
        meetingNumber: 2,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/presentation/d/1_SampleSlideDeck_IELTS_M2/edit?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 4)),
        isPublished: true,
        description: 'Kumpulan 15 topik cue card populer dan vocabulary booster idiom.',
      ),

      // Level TOEFL iBT Preparation
      TeachingMaterial(
        materialId: 'mat-toefl-001-guide',
        title: 'Petunjuk Ajar: Integrated Reading & Listening Synthesizing',
        level: 'TOEFL iBT',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/1_SampleTeacherGuide_TOEFL_M1/view?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 12)),
        isPublished: true,
        description: 'Metode note-taking Cornell dan strategi menghubungkan point of contrast.',
      ),
      TeachingMaterial(
        materialId: 'mat-toefl-001-slides',
        title: 'Slides Presentasi: TOEFL Integrated Writing Templates',
        level: 'TOEFL iBT',
        meetingNumber: 1,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/presentation/d/1_SampleSlideDeck_TOEFL_M1/edit?usp=sharing',
        updatedAt: now.subtract(const Duration(days: 12)),
        isPublished: true,
        description: 'Slide transisi kalimat, struktur essay 4 paragraf, dan common pitfalls.',
      ),
    ];

    for (final mat in seeds) {
      _materials[mat.materialId] = mat;
    }
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(_materials.values.toList());
    }
  }

  @override
  Future<List<TeachingMaterial>> getMaterials({String? level, bool onlyPublished = true}) async {
    var list = _materials.values.where((m) {
      if (onlyPublished && !m.isPublished) return false;
      if (level != null && level.isNotEmpty && level != 'Semua Level' && m.level != level) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      final levelComp = a.level.compareTo(b.level);
      if (levelComp != 0) return levelComp;
      final meetComp = a.meetingNumber.compareTo(b.meetingNumber);
      if (meetComp != 0) return meetComp;
      return a.materialType.compareTo(b.materialType);
    });

    return list;
  }

  @override
  Future<TeachingMaterial?> getMaterialById(String materialId) async {
    return _materials[materialId];
  }

  @override
  Stream<List<TeachingMaterial>> streamMaterials({String? level}) async* {
    yield await getMaterials(level: level);
    yield* _streamController.stream.map((list) {
      var filtered = list.where((m) {
        if (!m.isPublished) return false;
        if (level != null && level.isNotEmpty && level != 'Semua Level' && m.level != level) {
          return false;
        }
        return true;
      }).toList();
      filtered.sort((a, b) {
        final levelComp = a.level.compareTo(b.level);
        if (levelComp != 0) return levelComp;
        return a.meetingNumber.compareTo(b.meetingNumber);
      });
      return filtered;
    });
  }

  @override
  Future<TeachingMaterial> saveMaterial(TeachingMaterial material) async {
    final id = material.materialId.isNotEmpty
        ? material.materialId
        : 'mat-${DateTime.now().millisecondsSinceEpoch}';
    final saved = material.copyWith(
      materialId: id,
      updatedAt: DateTime.now(),
    );
    _materials[id] = saved;
    _notify();
    return saved;
  }

  @override
  Future<void> deleteMaterial(String materialId) async {
    _materials.remove(materialId);
    _notify();
  }

  @override
  Future<List<String>> getAvailableLevels() async {
    final levels = _materials.values.map((m) => m.level).toSet().toList();
    levels.sort();
    return ['Semua Level', ...levels];
  }
}

class FirestoreTeachingMaterialRepository implements TeachingMaterialRepository {
  final FirebaseFirestore? _customFirestore;
  final InMemoryTeachingMaterialRepository _fallback = InMemoryTeachingMaterialRepository();

  FirestoreTeachingMaterialRepository([FirebaseFirestore? firestore])
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<TeachingMaterial>> getMaterials({String? level, bool onlyPublished = true}) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getMaterials(level: level, onlyPublished: onlyPublished);
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('teachingMaterials');
      if (onlyPublished) {
        query = query.where('isPublished', isEqualTo: true);
      }
      if (level != null && level.isNotEmpty && level != 'Semua Level') {
        query = query.where('level', isEqualTo: level);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return await _fallback.getMaterials(level: level, onlyPublished: onlyPublished);
      }

      final list = snapshot.docs
          .map((doc) => TeachingMaterial.fromMap(doc.data(), doc.id))
          .toList();

      list.sort((a, b) {
        final levelComp = a.level.compareTo(b.level);
        if (levelComp != 0) return levelComp;
        return a.meetingNumber.compareTo(b.meetingNumber);
      });
      return list;
    } catch (_) {
      return await _fallback.getMaterials(level: level, onlyPublished: onlyPublished);
    }
  }

  @override
  Future<TeachingMaterial?> getMaterialById(String materialId) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getMaterialById(materialId);
    }

    try {
      final doc = await _firestore.collection('teachingMaterials').doc(materialId).get();
      if (!doc.exists || doc.data() == null) return null;
      return TeachingMaterial.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return await _fallback.getMaterialById(materialId);
    }
  }

  @override
  Stream<List<TeachingMaterial>> streamMaterials({String? level}) async* {
    if (!FirebaseService.isInitialized) {
      yield* _fallback.streamMaterials(level: level);
      return;
    }

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('teachingMaterials')
          .where('isPublished', isEqualTo: true);

      if (level != null && level.isNotEmpty && level != 'Semua Level') {
        query = query.where('level', isEqualTo: level);
      }

      await for (final snapshot in query.snapshots()) {
        if (snapshot.docs.isEmpty) {
          yield await _fallback.getMaterials(level: level);
        } else {
          final list = snapshot.docs
              .map((doc) => TeachingMaterial.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.meetingNumber.compareTo(b.meetingNumber));
          yield list;
        }
      }
    } catch (_) {
      yield* _fallback.streamMaterials(level: level);
    }
  }

  @override
  Future<TeachingMaterial> saveMaterial(TeachingMaterial material) async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.saveMaterial(material);
    }

    try {
      final collection = _firestore.collection('teachingMaterials');
      final docRef = material.materialId.isNotEmpty
          ? collection.doc(material.materialId)
          : collection.doc();

      final data = material.toMap();
      data['materialId'] = docRef.id;
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data, SetOptions(merge: true));
      return material.copyWith(materialId: docRef.id, updatedAt: DateTime.now());
    } catch (_) {
      return await _fallback.saveMaterial(material);
    }
  }

  @override
  Future<void> deleteMaterial(String materialId) async {
    if (!FirebaseService.isInitialized) {
      await _fallback.deleteMaterial(materialId);
      return;
    }

    try {
      await _firestore.collection('teachingMaterials').doc(materialId).delete();
    } catch (_) {
      await _fallback.deleteMaterial(materialId);
    }
  }

  @override
  Future<List<String>> getAvailableLevels() async {
    if (!FirebaseService.isInitialized) {
      return await _fallback.getAvailableLevels();
    }

    try {
      final snapshot = await _firestore.collection('teachingMaterials').get();
      if (snapshot.docs.isEmpty) {
        return await _fallback.getAvailableLevels();
      }
      final levels = snapshot.docs
          .map((d) => (d.data()['level'] as String? ?? 'General English'))
          .toSet()
          .toList();
      levels.sort();
      return ['Semua Level', ...levels];
    } catch (_) {
      return await _fallback.getAvailableLevels();
    }
  }
}

final teachingMaterialRepositoryProvider = Provider<TeachingMaterialRepository>((ref) {
  if (FirebaseService.isInitialized) {
    return FirestoreTeachingMaterialRepository();
  }
  return InMemoryTeachingMaterialRepository();
});
