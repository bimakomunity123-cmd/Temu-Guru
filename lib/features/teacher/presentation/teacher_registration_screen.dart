import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/validators/form_validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/data/auth_notifier.dart';
import '../../auth/data/firebase_auth_service.dart';
import '../../auth/domain/user_role.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/storage_service.dart';
import '../data/teacher_repository.dart';
import '../domain/teacher_profile.dart';

class TeacherRegistrationScreen extends ConsumerStatefulWidget {
  const TeacherRegistrationScreen({super.key});

  @override
  ConsumerState<TeacherRegistrationScreen> createState() =>
      _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState
    extends ConsumerState<TeacherRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _educationBackgroundController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State Variables
  DateTime? _selectedBirthDate;
  int? _calculatedAge;
  String? _ageValidationError;
  String? _selectedEducation;
  String? _selectedEnglishLevel;
  final List<String> _selectedTeachingAreas = [];
  bool _agreedToTerms = false;
  bool _termsError = false;
  bool _isLoading = false;

  // Document Upload State
  PlatformFile? _pickedPdfFile;
  int _pickedPdfFileSize = 0;
  String? _fileValidationError;

  // Options from Repository
  List<String> _educationOptions = [];
  List<String> _englishLevelOptions = [];
  List<String> _areaOptions = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final repo = ref.read(teacherRepositoryProvider);
    final edu = await repo.getEducationDegrees();
    final levels = await repo.getEnglishLevels();
    final areas = await repo.getAvailableAreas();
    if (mounted) {
      setState(() {
        _educationOptions = edu;
        _englishLevelOptions = levels;
        _areaOptions = areas;
        if (_educationOptions.isNotEmpty) _selectedEducation = _educationOptions.first;
        if (_englishLevelOptions.isNotEmpty) _selectedEnglishLevel = _englishLevelOptions.first;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _educationBackgroundController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 24, 1, 1);
    final firstDate = DateTime(1970);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Tanggal Lahir Guru',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final age = FormValidators.calculateAge(picked);
      final ageErr = FormValidators.teacherAge(picked);
      setState(() {
        _selectedBirthDate = picked;
        _calculatedAge = age;
        _ageValidationError = ageErr;
      });
    }
  }

  Future<void> _pickPdfDocument() async {
    setState(() {
      _fileValidationError = null;
    });

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isNotEmpty) {
        final file = files.first;

        // Validate PDF extension
        if (file.extension?.toLowerCase() != 'pdf') {
          setState(() {
            _fileValidationError = 'Hanya file dengan format .pdf yang diperbolehkan.';
          });
          return;
        }

        // Get file size in bytes
        final fileSize = (await file.length()) ?? file.lengthSync() ?? 0;

        // Validate file size (max 5MB = 5 * 1024 * 1024 bytes)
        final sizeErr = FormValidators.pdfFileSize(fileSize, 5);
        if (sizeErr != null) {
          setState(() {
            _fileValidationError = sizeErr;
          });
          return;
        }

        setState(() {
          _pickedPdfFile = file;
          _pickedPdfFileSize = fileSize;
          _fileValidationError = null;
        });
      }
    } catch (e) {
      setState(() {
        _fileValidationError = 'Gagal memilih dokumen: ${e.toString()}';
      });
    }
  }

  void _removeSelectedFile() {
    setState(() {
      _pickedPdfFile = null;
      _pickedPdfFileSize = 0;
      _fileValidationError = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _termsError = !_agreedToTerms;
      if (_selectedBirthDate == null) {
        _ageValidationError = 'Tanggal lahir guru wajib diisi';
      }
      if (_pickedPdfFile == null) {
        _fileValidationError = 'Dokumen sertifikat/hasil tes bahasa Inggris wajib dilampirkan (PDF maks 5MB)';
      }
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ageValidationError != null || _selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ageValidationError ?? 'Periksa kembali tanggal lahir.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_pickedPdfFile == null || _fileValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lampirkan dokumen hasil tes bahasa Inggris dalam format PDF.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTeachingAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu area kesediaan mengajar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(teacherRepositoryProvider);
      String uid = 'teacher-${DateTime.now().millisecondsSinceEpoch}';

      if (FirebaseService.isInitialized) {
        final authService = ref.read(firebaseAuthServiceProvider);
        final firebaseUser = await authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: UserRole.teacher,
        );
        uid = firebaseUser.uid;
      }

      String documentStoragePath = _pickedPdfFile!.path ?? _pickedPdfFile!.name;
      if (FirebaseService.isInitialized) {
        final storage = ref.read(storageServiceProvider);
        documentStoragePath = await storage.uploadTeacherPrivateDocument(
          teacherUid: uid,
          fileName: _pickedPdfFile!.name,
          localFilePath: _pickedPdfFile!.path,
        );
      }

      final profile = TeacherProfile(
        uid: uid,
        fullName: _nameController.text.trim(),
        nik: _nikController.text.trim(),
        birthDate: _selectedBirthDate!,
        age: _calculatedAge ?? 0,
        whatsapp: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        education: _selectedEducation ?? '',
        educationBackground: _educationBackgroundController.text.trim(),
        englishLevel: _selectedEnglishLevel ?? '',
        englishTestDocumentPath: documentStoragePath,
        englishTestDocumentName: _pickedPdfFile!.name,
        englishTestDocumentSizeBytes: _pickedPdfFileSize,
        address: _addressController.text.trim(),
        availableTeachingAreas: List.from(_selectedTeachingAreas),
        applicationStatus: 'pending',
        createdAt: DateTime.now(),
      );

      // Save to repository (validates NIK & Email duplication)
      await repo.registerTeacher(profile);

      // Create app user with pending status
      final appUser = AppUser(
        uid: uid,
        email: profile.email,
        name: profile.fullName,
        role: UserRole.teacher,
        teacherStatus: TeacherApplicationStatus.pending,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessConfirmationDialog(profile, appUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessConfirmationDialog(TeacherProfile profile, AppUser user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: AppColors.warning, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pendaftaran Berhasil Dikirim',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Formulir pendaftaran guru Anda telah kami terima dan berstatus Menunggu Verifikasi Admin.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('Nama Guru', profile.fullName),
                    const Divider(height: 14),
                    _buildSummaryRow('NIK (16 Digit Terlindungi)', '${profile.nik.substring(0, 6)}******${profile.nik.substring(12)}'),
                    const Divider(height: 14),
                    _buildSummaryRow(
                      'Tgl Lahir / Usia',
                      '${DateFormat('dd MMM yyyy').format(profile.birthDate)} (${profile.age} Tahun)',
                    ),
                    const Divider(height: 14),
                    _buildSummaryRow('Email / WhatsApp', '${profile.email} • ${profile.whatsapp}'),
                    const Divider(height: 14),
                    _buildSummaryRow('Pendidikan & Jurusan', '${profile.education} • ${profile.educationBackground}'),
                    const Divider(height: 14),
                    _buildSummaryRow('Level Bahasa Inggris', profile.englishLevel),
                    const Divider(height: 14),
                    _buildSummaryRow(
                      'Dokumen PDF',
                      '${profile.englishTestDocumentName} (${profile.formattedDocumentSize})',
                    ),
                    const Divider(height: 14),
                    _buildSummaryRow(
                      'Area Mengajar',
                      profile.availableTeachingAreas.join(', '),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Catatan: Anda belum dapat membuat sesi les hingga diverifikasi oleh tim kurikulum admin.',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(
            text: 'Lihat Status Pendaftaran',
            variant: ButtonVariant.primary,
            height: 46,
            onPressed: () {
              Navigator.pop(ctx);
              // Authenticate session as pending teacher
              ref.read(authNotifierProvider.notifier).login(
                    profile.email,
                    _passwordController.text,
                  );
              context.go('/teacher/status');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrasi Guru Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: AppColors.primary, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bergabung sebagai Guru Temu Guru',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kualifikasi minimum CEFR B2, usia maksimal 35 tahun, dan lampirkan sertifikat bahasa Inggris.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Nama Lengkap
                CustomTextField(
                  label: 'Nama Lengkap Beserta Gelar *',
                  hint: 'Contoh: Sarah Jenkins, S.Pd., M.Hum',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      FormValidators.required(v, 'Nama lengkap wajib diisi'),
                ),
                const SizedBox(height: 18),

                // 2. NIK (16 Digit Angka)
                CustomTextField(
                  label: 'Nomor Induk Kependudukan (NIK) *',
                  hint: '16 Digit Angka Sesuai KTP',
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  prefixIcon: Icons.badge_outlined,
                  helperText: 'NIK dilindungi dengan enkripsi privat dan hanya untuk verifikasi identitas resmi.',
                  validator: FormValidators.nik,
                ),
                const SizedBox(height: 18),

                // 3. Tanggal Lahir & 4. Usia Otomatis (Max 35 Thn)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Lahir & Usia (Maks. 35 Tahun) *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _ageValidationError != null
                                ? AppColors.error
                                : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedBirthDate != null
                                    ? dateFormat.format(_selectedBirthDate!)
                                    : 'Pilih tanggal lahir guru',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedBirthDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ),
                            if (_calculatedAge != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (_calculatedAge! <= 35 && _calculatedAge! >= 18)
                                      ? AppColors.successLight
                                      : AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Usia: $_calculatedAge Tahun',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: (_calculatedAge! <= 35 && _calculatedAge! >= 18)
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_ageValidationError != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _ageValidationError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Ketentuan program: Usia pengajar maksimal 35 tahun saat mendaftar.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),

                // 5. WhatsApp
                CustomTextField(
                  label: 'Nomor WhatsApp Aktif *',
                  hint: '081234567890',
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  validator: FormValidators.whatsapp,
                ),
                const SizedBox(height: 18),

                // 6. Email
                CustomTextField(
                  label: 'Alamat Email Guru *',
                  hint: 'guru@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  helperText: 'Email digunakan sebagai kredensial login akun pengajar.',
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 18),

                // 7. Pendidikan Terakhir
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pendidikan Terakhir *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedEducation,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.primary),
                          items: _educationOptions.map((edu) {
                            return DropdownMenuItem<String>(
                              value: edu,
                              child: Text(
                                edu,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedEducation = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 8. Latar Belakang Pendidikan / Jurusan
                CustomTextField(
                  label: 'Jurusan / Latar Belakang Pendidikan *',
                  hint: 'Contoh: Pendidikan Bahasa Inggris (Universitas Negeri Jakarta)',
                  controller: _educationBackgroundController,
                  prefixIcon: Icons.menu_book_outlined,
                  validator: (v) => FormValidators.required(
                    v,
                    'Latar belakang pendidikan wajib diisi',
                  ),
                ),
                const SizedBox(height: 18),

                // 9. Level Bahasa Inggris (Min B2)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tingkat Kecakapan Bahasa Inggris (CEFR Min. B2) *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedEnglishLevel,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.primary),
                          items: _englishLevelOptions.map((level) {
                            return DropdownMenuItem<String>(
                              value: level,
                              child: Text(
                                level,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedEnglishLevel = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Hanya pendaftar dengan kualifikasi minimal CEFR B2 yang dapat disetujui.',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 10. Upload Dokumen PDF Hasil Tes Bahasa Inggris
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Dokumen PDF Hasil Tes Bahasa Inggris *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_pickedPdfFile == null) ...[
                      InkWell(
                        onTap: _pickPdfDocument,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _fileValidationError != null
                                  ? AppColors.error
                                  : AppColors.border,
                              width: 1.4,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.upload_file_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Pilih Dokumen PDF Sertifikat',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Format PDF (IELTS, TOEFL, British Council EnglishScore, dll). Maksimal 5 MB.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // File Uploaded Card with options to change / remove
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: AppColors.error,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedPdfFile!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ukuran: ${_formatFileSize(_pickedPdfFileSize)} • Siap diunggah',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20),
                              tooltip: 'Ganti File',
                              onPressed: _pickPdfDocument,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error, size: 20),
                              tooltip: 'Hapus File',
                              onPressed: _removeSelectedFile,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_fileValidationError != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _fileValidationError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),

                // 11. Alamat Lengkap
                CustomTextField(
                  label: 'Alamat Lengkap Domisili Guru *',
                  hint: 'Alamat tempat tinggal lengkap untuk penyesuaian area mengajar',
                  controller: _addressController,
                  maxLines: 2,
                  prefixIcon: Icons.home_outlined,
                  validator: (v) => FormValidators.required(
                    v,
                    'Alamat domisili wajib diisi',
                  ),
                ),
                const SizedBox(height: 18),

                // 12. Area Kesediaan Mengajar (Multi Selection Chips)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Area Kesediaan Mengajar (Bisa Lebih Dari 1) *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _areaOptions.map((area) {
                        final isSelected = _selectedTeachingAreas.contains(area);
                        return FilterChip(
                          label: Text(
                            area,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryContainer,
                          backgroundColor: Colors.white,
                          checkmarkColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTeachingAreas.add(area);
                              } else {
                                _selectedTeachingAreas.remove(area);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_selectedTeachingAreas.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Pilih minimal satu area di mana Anda bersedia mengajar les tatap muka.',
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),

                // 13. Password
                CustomTextField(
                  label: 'Buat Kata Sandi Akun Pengajar *',
                  hint: 'Minimal 6 karakter',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: FormValidators.password,
                ),
                const SizedBox(height: 18),

                // 14. Konfirmasi Password
                CustomTextField(
                  label: 'Konfirmasi Kata Sandi *',
                  hint: 'Ulangi kata sandi Anda',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_clock_outlined,
                  textInputAction: TextInputAction.done,
                  validator: (v) => FormValidators.confirmPassword(
                    v,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 20),

                // 15. Persetujuan Kebijakan Privasi & Ketentuan Layanan
                InkWell(
                  onTap: () {
                    setState(() {
                      _agreedToTerms = !_agreedToTerms;
                      if (_agreedToTerms) _termsError = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _agreedToTerms = val ?? false;
                                if (_agreedToTerms) _termsError = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Saya menyatakan data yang saya kirimkan adalah benar, dan menyetujui Ketentuan Pengajar serta Kebijakan Privasi Temu Guru dalam pemrosesan data identitas dan dokumen kualifikasi.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_termsError) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 34, top: 4),
                    child: Text(
                      'Anda wajib menyetujui ketentuan dan kebijakan privasi untuk melanjutkan.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Kirim Pendaftaran Pengajar',
                  icon: Icons.send_rounded,
                  isLoading: _isLoading,
                  onPressed: _submitRegistration,
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah memiliki akun pengajar? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Masuk di Sini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
