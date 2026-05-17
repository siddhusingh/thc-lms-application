import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assessments/presentation/assessment_attempt_screen.dart';
import '../features/assessments/presentation/assessment_list_screen.dart';
import '../features/assessments/presentation/assessment_result_screen.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/face_verification_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/certificates/presentation/certificate_list_screen.dart';
import '../features/courses/presentation/course_detail_screen.dart';
import '../features/courses/presentation/course_list_screen.dart';
import '../features/courses/presentation/video_lesson_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/face_images/presentation/face_images_screen.dart';
import '../features/face_references/presentation/face_reference_preparation_screen.dart';
import '../features/profile/presentation/personal_details_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../models/course_model.dart';
import 'main_shell.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final path = state.uri.path;
        if (!authProvider.initialized) {
          return path == '/splash' ? null : '/splash';
        }
        if (path == '/splash') {
          return authProvider.isAuthenticated ? '/face/preparing' : '/login';
        }
        final publicPaths = ['/login', '/register', '/forgot-password', '/otp'];
        final isPublic = publicPaths.any(
          (publicPath) => path.startsWith(publicPath),
        );
        if (!authProvider.isAuthenticated && !isPublic) {
          return '/login';
        }
        if (authProvider.isAuthenticated && path == '/login') {
          return '/face/preparing';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) =>
              OtpScreen(email: state.uri.queryParameters['email'] ?? ''),
        ),
        GoRoute(
          path: '/face/register',
          builder: (context, state) =>
              const FaceVerificationScreen(mode: FaceMode.register),
        ),
        GoRoute(
          path: '/face/verify',
          builder: (context, state) =>
              const FaceVerificationScreen(mode: FaceMode.verify),
        ),
        GoRoute(
          path: '/face/preparing',
          builder: (context, state) => const FaceReferencePreparationScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/courses',
              builder: (context, state) => const CourseListScreen(),
            ),
            GoRoute(
              path: '/assessments',
              builder: (context, state) => const AssessmentListScreen(),
            ),
            GoRoute(
              path: '/certificates',
              builder: (context, state) => const CertificateListScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/profile/personal-details',
              builder: (context, state) => const PersonalDetailsScreen(),
            ),
            GoRoute(
              path: '/profile/face-images',
              builder: (context, state) => const FaceImagesScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/courses/:id',
          builder: (context, state) => CourseDetailScreen(
            courseId: state.pathParameters['id']!,
            showAssessmentCompletedMessage:
                state.uri.queryParameters['assessment_completed'] == 'true',
          ),
        ),
        GoRoute(
          path: '/lessons',
          builder: (context, state) {
            final lesson = state.extra;
            if (lesson is LessonModel) return VideoLessonScreen(lesson: lesson);
            return const Scaffold(
              body: Center(child: Text('Lesson data unavailable.')),
            );
          },
        ),
        GoRoute(
          path: '/lessons/:id',
          builder: (context, state) {
            final lesson = state.extra;
            if (lesson is LessonModel) return VideoLessonScreen(lesson: lesson);
            return const Scaffold(
              body: Center(child: Text('Lesson data unavailable.')),
            );
          },
        ),
        GoRoute(
          path: '/assessments/:id',
          builder: (context, state) => AssessmentAttemptScreen(
            assessmentId: state.pathParameters['id']!,
            returnTo: state.uri.queryParameters['return_to'],
          ),
        ),
        GoRoute(
          path: '/assessment-result',
          builder: (context, state) => const AssessmentResultScreen(),
        ),
      ],
    );
  }
}
