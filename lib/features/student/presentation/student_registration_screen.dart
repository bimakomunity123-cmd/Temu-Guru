import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../data/student_repository.dart';
import '../domain/student_profile.dart';

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State Variables
  DateTime? _selectedBirthDate;
  int? _calculatedAge;
  String? _selectedArea;
  String? _selectedProgram;
  bool _hasLearningExperience = false;
  bool _agreedToTerms = false;
  bool _termsError = false;
  bool _isLoading = false;

  List<String> _areas = [];
  List<String> _programs = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final repo = ref.read(studentRepositoryProvider);
    final areas = await repo.getAvailableAreas();
    final programs = await repo.getAvailablePrograms();
    if (mounted) {
      setState(() {
        _areas = areas;
        _programs = programs;
        if (_areas.isNotEmpty) _selectedArea = _areas.first;
        if (_programs.isNotEmpty) _selectedProgram = _programs.first;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 15, 1, 1);
    final firstDate = DateTime(1960);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih Tanggal Lahir Siswa',
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
      setState(() {
        _selectedBirthDate = picked;
        _calculatedAge = FormValidators.calculateAge(picked);
      });
    }
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _termsError = !_agreedToTerms;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanggal lahir Anda.'),
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
      final repo = ref.read(studentRepositoryProvider);
      String uid = 'student-${DateTime.now().millisecondsSinceEpoch}';

      if (FirebaseService.isInitialized) {
        final authService = ref.read(firebaseAuthServiceProvider);
        final firebaseUser = await authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: UserRole.student,
        );
        uid = firebaseUser.uid;
      }

      final profile = StudentProfile(
        uid: uid,
        fullName: _nameController.text.trim(),
        birthDate: _selectedBirthDate!,
        age: _calculatedAge ?? 0,
        whatsapp: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        preferredTeachingArea: _selectedArea ?? '',
        hasEnglishLearningExperience: _hasLearningExperience,
        preferredProgram: _selectedProgram ?? '',
        createdAt: DateTime.now(),
      );

      // Save to repository (will validate email duplication)
      await repo.registerStudent(profile);

      // Update auth session
      final appUser = AppUser(
        uid: uid,
        email: profile.email,
        name: profile.fullName,
        role: UserRole.student,
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

  void _showSuccessConfirmationDialog(StudentProfile profile, AppUser user) {
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
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pendaftaran Berhasil!',
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
                'Akun siswa Anda telah siap. Berikut ringkasan pendaftaran Anda:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                    _buildSummaryRow('Nama Siswa', profile.fullName),
                    const Divider(height: 14),
                    _buildSummaryRow(
                      'Tgl Lahir / Usia',
                      '${DateFormat('dd MMM yyyy').format(profile.birthDate)} (${profile.age} Tahun)',
                    ),
                    const Divider(height: 14),
                    _buildSummaryRow('WhatsApp', profile.whatsapp),
                    const Divider(height: 14),
                    _buildSummaryRow('Email', profile.email),
                    const Divider(height: 14),
                    _buildSummaryRow('Area Pilihan', profile.preferredTeachingArea),
                    const Divider(height: 14),
                    _buildSummaryRow('Program', profile.preferredProgram),
                    const Divider(height: 14),
                    _buildSummaryRow(
                      'Pengalaman Les',
                      profile.hasEnglishLearningExperience ? 'Pernah' : 'Belum Pernah',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(
            text: 'Masuk ke Dashboard Siswa',
            variant: ButtonVariant.primary,
            height: 46,
            onPressed: () {
              Navigator.pop(ctx);
              // Authenticate user in session
              ref.read(authNotifierProvider.notifier).login(
                    profile.email,
                    _passwordController.text,
                  );
              context.go('/student/dashboard');
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
        title: const Text('Registrasi Siswa Baru'),
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
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formulir Siswa Temu Guru',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Lengkapi profil Anda untuk dicocokkan dengan guru les terbaik.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
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
                  label: 'Nama Lengkap Siswa *',
                  hint: 'Contoh: Ahmad Faiz Pratama',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      FormValidators.required(v, 'Nama lengkap wajib diisi'),
                ),
                const SizedBox(height: 18),

                // 2. Tanggal Lahir & 3. Usia Otomatis
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Lahir & Usia *',
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
                          border: Border.all(color: AppColors.border, width: 1.2),
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
                                    : 'Pilih tanggal lahir',
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
                                  color: AppColors.accentContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Usia: $_calculatedAge Tahun',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentDark,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_selectedBirthDate == null) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Usia akan dihitung otomatis dari tanggal lahir yang Anda pilih.',
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

                // 4. Nomor WhatsApp
                CustomTextField(
                  label: 'Nomor WhatsApp *',
                  hint: '081234567890',
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  helperText: 'Gunakan nomor WhatsApp aktif untuk koordinasi jadwal les.',
                  validator: FormValidators.whatsapp,
                ),
                const SizedBox(height: 18),

                // 5. Email
                CustomTextField(
                  label: 'Alamat Email *',
                  hint: 'nama@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  helperText: 'Email ini akan digunakan sebagai kredensial login.',
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 18),

                // 6. Alamat Tempat Tinggal
                CustomTextField(
                  label: 'Alamat Lengkap Tempat Tinggal *',
                  hint: 'Jl. Melati No. 12, Kelurahan, Kecamatan, Kota',
                  controller: _addressController,
                  maxLines: 2,
                  prefixIcon: Icons.home_outlined,
                  validator: (v) =>
                      FormValidators.required(v, 'Alamat lengkap wajib diisi'),
                ),
                const SizedBox(height: 18),

                // 7. Area Lokasi Les Pilihan
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Area Lokasi Les yang Diinginkan *',
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
                          value: _selectedArea,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.primary),
                          items: _areas.map((area) {
                            return DropdownMenuItem<String>(
                              value: area,
                              child: Text(
                                area,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedArea = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 8. Pengalaman Les Sebelumnya (Ya / Tidak)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pernah Mengikuti Les Bahasa Inggris Sebelumnya? *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _hasLearningExperience = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _hasLearningExperience
                                    ? AppColors.primaryContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasLearningExperience
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: _hasLearningExperience ? 1.8 : 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Ya, Pernah',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _hasLearningExperience
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _hasLearningExperience
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _hasLearningExperience = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_hasLearningExperience
                                    ? AppColors.primaryContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_hasLearningExperience
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: !_hasLearningExperience ? 1.8 : 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Belum Pernah',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: !_hasLearningExperience
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !_hasLearningExperience
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 9. Program / Level yang Diminati
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Program / Level yang Diminati *',
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
                          value: _selectedProgram,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.primary),
                          items: _programs.map((program) {
                            return DropdownMenuItem<String>(
                              value: program,
                              child: Text(
                                program,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedProgram = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 10. Password
                CustomTextField(
                  label: 'Buat Kata Sandi *',
                  hint: 'Minimal 6 karakter',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: FormValidators.password,
                ),
                const SizedBox(height: 18),

                // 11. Konfirmasi Password
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

                // 12. Persetujuan Kebijakan Privasi & Ketentuan Layanan
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
                            'Saya menyetujui Kebijakan Privasi dan Ketentuan Layanan aplikasi Temu Guru dalam perlindungan dan pemrosesan data pribadi saya.',
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
                      'Anda wajib menyetujui kebijakan privasi & ketentuan layanan untuk mendaftar.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Daftar sebagai Siswa',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: _isLoading,
                  onPressed: _submitRegistration,
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah memiliki akun? ',
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
