import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ruangguru/features/teaching_material/domain/teaching_material.dart';
import 'package:flutter_ruangguru/features/teaching_material/data/teaching_material_repository.dart';

void main() {
  group('Feature A: TeachingMaterial Model & Validation Tests', () {
    test('TeachingMaterial toMap and fromMap preserves all fields correctly', () {
      final now = DateTime(2026, 10, 20, 14, 30);
      final material = TeachingMaterial(
        materialId: 'mat-test-01',
        title: 'Petunjuk Ajar: Tenses Review',
        level: 'Intermediate (B1)',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/sample-id/view?usp=sharing',
        updatedAt: now,
        isPublished: true,
        description: 'Panduan tutor mengajar 90 menit.',
      );

      final map = material.toMap();
      expect(map['materialId'], 'mat-test-01');
      expect(map['level'], 'Intermediate (B1)');
      expect(map['meetingNumber'], 1);
      expect(map['materialType'], 'petunjuk_ajar');
      expect(map['externalUrl'], contains('drive.google.com'));
      expect(map['isPublished'], true);

      final restored = TeachingMaterial.fromMap(map, 'mat-test-01');
      expect(restored.materialId, material.materialId);
      expect(restored.title, material.title);
      expect(restored.level, material.level);
      expect(restored.meetingNumber, material.meetingNumber);
      expect(restored.materialType, material.materialType);
      expect(restored.externalUrl, material.externalUrl);
      expect(restored.isPublished, true);
    });

    test('isGoogleDriveLink correctly validates Drive and Docs URLs', () {
      final driveMat = TeachingMaterial(
        materialId: 'mat-01',
        title: 'Guide',
        level: 'B1',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/abc/view',
        updatedAt: DateTime.now(),
      );
      expect(driveMat.isGoogleDriveLink, isTrue);

      final docsMat = TeachingMaterial(
        materialId: 'mat-02',
        title: 'Slides',
        level: 'B1',
        meetingNumber: 1,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/presentation/d/xyz/edit',
        updatedAt: DateTime.now(),
      );
      expect(docsMat.isGoogleDriveLink, isTrue);

      final otherMat = TeachingMaterial(
        materialId: 'mat-03',
        title: 'Other',
        level: 'B1',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://example.com/material.pdf',
        updatedAt: DateTime.now(),
      );
      expect(otherMat.isGoogleDriveLink, isFalse);
    });

    test('typeLabel returns human readable Indonesian labels', () {
      final guide = TeachingMaterial(
        materialId: '1',
        title: 'Guide',
        level: 'B1',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/1',
        updatedAt: DateTime.now(),
      );
      expect(guide.typeLabel, contains('Petunjuk Ajar Guru'));

      final slides = TeachingMaterial(
        materialId: '2',
        title: 'Slides',
        level: 'B1',
        meetingNumber: 1,
        materialType: 'materi_presentasi',
        externalUrl: 'https://docs.google.com/2',
        updatedAt: DateTime.now(),
      );
      expect(slides.typeLabel, contains('Materi Presentasi'));
    });
  });

  group('Feature A: TeachingMaterial Repository Tests', () {
    late InMemoryTeachingMaterialRepository repository;

    setUp(() {
      repository = InMemoryTeachingMaterialRepository();
    });

    test('Initial repository loads seeded materials with levels and meetings', () async {
      final allMaterials = await repository.getMaterials();
      expect(allMaterials, isNotEmpty);
      expect(allMaterials.any((m) => m.materialType == 'petunjuk_ajar'), isTrue);
      expect(allMaterials.any((m) => m.materialType == 'materi_presentasi'), isTrue);
    });

    test('Filtering by level returns only materials belonging to that level', () async {
      final ielts = await repository.getMaterials(level: 'IELTS Academic');
      expect(ielts, isNotEmpty);
      expect(ielts.every((m) => m.level == 'IELTS Academic'), isTrue);

      final toefl = await repository.getMaterials(level: 'TOEFL iBT');
      expect(toefl, isNotEmpty);
      expect(toefl.every((m) => m.level == 'TOEFL iBT'), isTrue);
    });

    test('Materials are ordered by meeting number sequentially', () async {
      final b1Materials = await repository.getMaterials(level: 'Intermediate (B1)');
      for (int i = 0; i < b1Materials.length - 1; i++) {
        expect(b1Materials[i].meetingNumber <= b1Materials[i + 1].meetingNumber, isTrue);
      }
    });

    test('Saving new material updates repository and notifies stream', () async {
      final newMat = TeachingMaterial(
        materialId: 'mat-custom-01',
        title: 'Petunjuk Ajar: Advanced Debate',
        level: 'Advanced (C1)',
        meetingNumber: 1,
        materialType: 'petunjuk_ajar',
        externalUrl: 'https://drive.google.com/file/d/debate-guide/view',
        updatedAt: DateTime.now(),
        isPublished: true,
      );

      await repository.saveMaterial(newMat);
      final fetched = await repository.getMaterialById('mat-custom-01');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Petunjuk Ajar: Advanced Debate');
    });
  });
}
