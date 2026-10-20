import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Header Logo & Branding
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Temukan Guru Terbaik, Belajar di Tempat Pilihanmu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Feature highlights banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryContainer,
                            AppColors.accentContainer.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            Icons.verified_user_rounded,
                            'Guru Terverifikasi',
                            'Kualifikasi minimum CEFR B2 & tersaring ketat',
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          _buildFeatureRow(
                            Icons.calendar_today_rounded,
                            'Laporan Harian (Daily Report)',
                            'Pantau progres materi & evaluasi setiap sesi',
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          _buildFeatureRow(
                            Icons.location_on_rounded,
                            'Fleksibel & Terjadwal',
                            'Pilih area les yang sesuai dengan kebutuhan Anda',
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 28),

                    // Primary Button: Login
                    CustomButton(
                      text: 'Masuk ke Akun Anda',
                      icon: Icons.login_rounded,
                      variant: ButtonVariant.primary,
                      onPressed: () => context.push('/login'),
                    ),
                    const SizedBox(height: 14),

                    // Student Registration Button
                    _buildRoleOptionCard(
                      context: context,
                      title: 'Daftar sebagai Siswa',
                      subtitle: 'Cari tutor dan mulai belajar bahasa Inggris',
                      icon: Icons.person_add_alt_1_rounded,
                      color: AppColors.accent,
                      onTap: () => context.push('/register/student'),
                    ),
                    const SizedBox(height: 12),

                    // Teacher Registration Button
                    _buildRoleOptionCard(
                      context: context,
                      title: 'Daftar sebagai Guru',
                      subtitle: 'Bergabung dan mengajar privat atau kelompok',
                      icon: Icons.assignment_ind_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push('/register/teacher'),
                    ),
                    const SizedBox(height: 20),

                    // Terms Note
                    Text(
                      'Dengan mendaftar, Anda menyetujui Ketentuan Layanan dan Kebijakan Privasi Temu Guru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
