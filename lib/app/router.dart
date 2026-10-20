import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_notifier.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/student/presentation/student_registration_screen.dart';
import '../features/teacher/presentation/teacher_registration_screen.dart';
import '../features/student/presentation/student_dashboard_screen.dart';
import '../features/teacher/presentation/teacher_dashboard_screen.dart';
import '../features/teacher_verification/presentation/application_status_screen.dart';
import '../features/teacher_verification/presentation/admin_verification_screen.dart';
import '../features/daily_report/presentation/create_lesson_report_screen.dart';
import '../features/daily_report/presentation/lesson_report_history_screen.dart';
import '../features/teaching_material/presentation/teacher_materials_screen.dart';
import '../features/learning_module/presentation/student_modules_screen.dart';
import '../features/review/presentation/student_reviews_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes to trigger router re-evaluation
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register/student',
        builder: (context, state) => const StudentRegistrationScreen(),
      ),
      GoRoute(
        path: '/register/teacher',
        builder: (context, state) => const TeacherRegistrationScreen(),
      ),
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/dashboard',
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/status',
        builder: (context, state) => const ApplicationStatusScreen(),
      ),
      GoRoute(
        path: '/teacher/reports',
        builder: (context, state) => const LessonReportHistoryScreen(),
      ),
      GoRoute(
        path: '/teacher/reports/new',
        builder: (context, state) => const CreateLessonReportScreen(),
      ),
      GoRoute(
        path: '/teacher/materials',
        builder: (context, state) => const TeacherMaterialsScreen(),
      ),
      GoRoute(
        path: '/student/modules',
        builder: (context, state) => const StudentModulesScreen(),
      ),
      GoRoute(
        path: '/student/reviews',
        builder: (context, state) => const StudentReviewsScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminVerificationScreen(),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuth = authState.isAuthenticated;
      final user = authState.user;

      // Allow splash, welcome, login, and registration freely
      final isPublicRoute = loc == '/' ||
          loc == '/welcome' ||
          loc == '/login' ||
          loc.startsWith('/register');

      // If user is trying to access protected routes without being authenticated
      if (!isAuth && !isPublicRoute) {
        return '/welcome';
      }

      // If user is logged in and tries to access /login or /welcome
      if (isAuth && (loc == '/login' || loc == '/welcome')) {
        if (user != null) {
          if (user.isAdmin) {
            return '/admin/dashboard';
          } else if (user.isStudent) {
            return '/student/dashboard';
          } else if (user.isTeacher) {
            return user.isTeacherApproved
                ? '/teacher/dashboard'
                : '/teacher/status';
          }
        }
      }

      // Guard admin routes
      if (loc.startsWith('/admin')) {
        if (!isAuth || user == null || !user.isAdmin) {
          return '/welcome';
        }
      }

      // Guard teacher routes
      if (isAuth && user != null && user.isTeacher) {
        if (!user.isTeacherApproved && loc != '/teacher/status') {
          return '/teacher/status';
        }
        if (loc.startsWith('/student') || loc.startsWith('/admin')) {
          return user.isTeacherApproved ? '/teacher/dashboard' : '/teacher/status';
        }
      }

      // Guard student routes
      if (isAuth && user != null && user.isStudent) {
        if (loc.startsWith('/teacher') || loc.startsWith('/admin')) {
          return '/student/dashboard';
        }
      }

      return null;
    },
  );
});
