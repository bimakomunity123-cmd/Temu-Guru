import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

abstract class StorageService {
  Future<String> uploadTeacherPrivateDocument({
    required String teacherUid,
    required String fileName,
    String? localFilePath,
    Uint8List? fileBytes,
  });

  Future<Uint8List?> downloadTeacherPrivateDocument(String storagePath);
}

/// Penyimpanan Dokumen Privat Berbasis Lokal (100% Gratis tanpa perlu kartu kredit / paket Blaze)
class LocalStorageService implements StorageService {
  static final Map<String, Uint8List> _inMemoryStorage = <String, Uint8List>{};

  @override
  Future<String> uploadTeacherPrivateDocument({
    required String teacherUid,
    required String fileName,
    String? localFilePath,
    Uint8List? fileBytes,
  }) async {
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'teacher_documents/$teacherUid/$sanitizedFileName';

    Uint8List? bytes = fileBytes;
    if (bytes == null && localFilePath != null && !kIsWeb) {
      final file = File(localFilePath);
      if (await file.exists()) {
        bytes = await file.readAsBytes();
      }
    }

    if (bytes == null) {
      throw Exception('Dokumen sertifikat tidak valid atau kosong.');
    }

    // Simpan ke in-memory cache untuk akses cepat & multi-platform (termasuk Web)
    _inMemoryStorage[storagePath] = bytes;

    // Simpan salinan lokal di storage perangkat jika bukan Web
    if (!kIsWeb) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${docsDir.path}/teacher_documents/$teacherUid');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final targetFile = File('${targetDir.path}/$sanitizedFileName');
        await targetFile.writeAsBytes(bytes);
      } catch (e) {
        debugPrint('Warning: Menyimpan ke file lokal gagal, menggunakan memory cache: $e');
      }
    }

    return storagePath;
  }

  @override
  Future<Uint8List?> downloadTeacherPrivateDocument(String storagePath) async {
    if (_inMemoryStorage.containsKey(storagePath)) {
      return _inMemoryStorage[storagePath];
    }

    if (!kIsWeb) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final filePath = '${docsDir.path}/$storagePath';
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _inMemoryStorage[storagePath] = bytes;
          return bytes;
        }
      } catch (e) {
        debugPrint('Error membaca dokumen lokal: $e');
      }
    }

    return null;
  }
}

/// Firebase Storage Service dengan Fallback Otomatis ke Local Storage jika Storage belum diaktifkan/Spark Free Tier
class FirebaseStorageService implements StorageService {
  final FirebaseStorage? _customStorage;
  final LocalStorageService _fallbackStorage = LocalStorageService();

  FirebaseStorageService([FirebaseStorage? storage])
      : _customStorage = storage;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadTeacherPrivateDocument({
    required String teacherUid,
    required String fileName,
    String? localFilePath,
    Uint8List? fileBytes,
  }) async {
    try {
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = 'teacher_documents/$teacherUid/$sanitizedFileName';
      final ref = _storage.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'uploadedBy': teacherUid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'documentType': 'EnglishTestCertificate',
        },
      );

      if (kIsWeb || localFilePath == null) {
        if (fileBytes == null) {
          throw Exception('File bytes tidak tersedia untuk proses upload.');
        }
        await ref.putData(fileBytes, metadata);
      } else {
        final file = File(localFilePath);
        if (!await file.exists()) {
          throw Exception('File fisik tidak ditemukan pada path: $localFilePath');
        }
        await ref.putFile(file, metadata);
      }

      return storagePath;
    } catch (e) {
      debugPrint('Firebase Storage belum aktif (Blaze diperlukan) atau gagal: $e. Mengalihkan ke Local Storage (Gratis)...');
      return await _fallbackStorage.uploadTeacherPrivateDocument(
        teacherUid: teacherUid,
        fileName: fileName,
        localFilePath: localFilePath,
        fileBytes: fileBytes,
      );
    }
  }

  @override
  Future<Uint8List?> downloadTeacherPrivateDocument(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getData(10 * 1024 * 1024);
    } catch (e) {
      debugPrint('Firebase Storage download gagal, mencoba dari Local Storage: $e');
      return await _fallbackStorage.downloadTeacherPrivateDocument(storagePath);
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return FirebaseStorageService();
});
