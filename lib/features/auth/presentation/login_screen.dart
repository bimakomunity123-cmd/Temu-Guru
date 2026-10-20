import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/validators/form_validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/auth_notifier.dart';
import '../domain/user_role.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.setRememberMe(_rememberMe);

    final success = await authNotifier.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final user = ref.read(authNotifierProvider).user;
      if (user != null) {
        if (user.isAdmin) {
          context.go('/admin/dashboard');
        } else if (user.isStudent) {
          context.go('/student/dashboard');
        } else if (user.isTeacher) {
          if (user.isTeacherApproved) {
            context.go('/teacher/dashboard');
          } else {
            context.go('/teacher/status');
          }
        } else {
          context.go('/student/dashboard');
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController(text: _emailController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lupa Password?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan alamat email terdaftar Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Email',
                hint: 'nama@email.com',
                controller: emailResetController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Kirim Tautan Reset',
                icon: Icons.send_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan reset kata sandi telah dikirim ke email Anda.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon Header
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),

                  const Text(
                    'Selamat Datang Kembali',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masuk menggunakan email dan password terdaftar Anda.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Banner
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Email Field
                  CustomTextField(
                    label: 'Alamat Email',
                    hint: 'nama@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: FormValidators.password,
                  ),
                  const SizedBox(height: 12),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Ingat Saya',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    text: 'Masuk Sekarang',
                    icon: Icons.login_rounded,
                    isLoading: authState.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau daftar baru',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Registration Links
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Daftar Siswa',
                          variant: ButtonVariant.outline,
                          height: 44,
                          onPressed: () => context.push('/register/student'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Daftar Guru',
                          variant: ButtonVariant.secondary,
                          height: 44,
                          onPressed: () => context.push('/register/teacher'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Quick Demo Prototype Login Helper (Essential for Testing Tahap 1)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 18, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text(
                              'Akses Cepat Pengujian (Tahap 1)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickChip(
                              label: 'Siswa',
                              color: AppColors.accent,
                              onTap: () {
                                ref.read(authNotifierProvider.notifier).loginAsQuickDemo(UserRole.student);
                                context.go('/student/dashboard');
                              },
                            ),
                            _buildQuickChip(
                              label: 'Guru (Approved)',
                              color: AppColors.success,
                              onTap: () {
                                ref.read(authNotifierProvider.notifier).loginAsQuickDemo(
                                  UserRole.teacher,
                                  TeacherApplicationStatus.approved,
                                );
                                context.go('/teacher/dashboard');
                              },
                            ),
                            _buildQuickChip(
                              label: 'Guru (Pending)',
                              color: AppColors.warning,
                              onTap: () {
                                ref.read(authNotifierProvider.notifier).loginAsQuickDemo(
                                  UserRole.teacher,
                                  TeacherApplicationStatus.pending,
                                );
                                context.go('/teacher/status');
                              },
                            ),
                            _buildQuickChip(
                              label: 'Guru (Rejected)',
                              color: AppColors.error,
                              onTap: () {
                                ref.read(authNotifierProvider.notifier).loginAsQuickDemo(
                                  UserRole.teacher,
                                  TeacherApplicationStatus.rejected,
                                );
                                context.go('/teacher/status');
                              },
                            ),
                            _buildQuickChip(
                              label: 'Admin (Verifikator)',
                              color: AppColors.primary,
                              onTap: () {
                                ref.read(authNotifierProvider.notifier).loginAsQuickDemo(UserRole.admin);
                                context.go('/admin/dashboard');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
