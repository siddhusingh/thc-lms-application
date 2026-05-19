import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/constants/app_config.dart';
import 'core/storage/secure_session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/assessments/data/assessment_repository.dart';
import 'features/assessments/presentation/assessment_provider.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/calendar/data/calendar_repository.dart';
import 'features/calendar/presentation/calendar_provider.dart';
import 'features/certificates/data/certificate_repository.dart';
import 'features/certificates/presentation/certificate_provider.dart';
import 'features/courses/data/course_repository.dart';
import 'features/courses/presentation/course_provider.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/dashboard/presentation/dashboard_provider.dart';
import 'features/face_images/data/face_image_repository.dart';
import 'features/face_images/data/face_image_service.dart';
import 'features/face_images/presentation/face_image_provider.dart';
import 'features/face_references/presentation/face_reference_provider.dart';
import 'features/learning_path/data/learning_path_repository.dart';
import 'features/learning_path/presentation/learning_path_provider.dart';
import 'features/notifications/notification_service.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/presentation/profile_provider.dart';
import 'features/study_time/data/study_time_repository.dart';
import 'features/study_time/presentation/study_time_provider.dart';
import 'routes/app_router.dart';
import 'services/face_reference_store.dart';
import 'services/face_reference_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final sessionStore = SecureSessionStore();
  final apiClient = ApiClient(sessionStore);
  final notificationService = NotificationService();
  await notificationService.initialize();

  final authRepository = AuthRepository(apiClient, sessionStore);
  final authProvider = AuthProvider(authRepository);
  unawaited(authProvider.restoreSession());

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: sessionStore),
        Provider.value(value: apiClient),
        Provider.value(value: notificationService),
        Provider.value(value: authRepository),
        ChangeNotifierProvider.value(value: authProvider),
        Provider(create: (_) => DashboardRepository(apiClient)),
        Provider(create: (_) => CalendarRepository(apiClient)),
        Provider(create: (_) => StudyTimeRepository(apiClient)),
        Provider(create: (_) => LearningPathRepository(apiClient)),
        Provider(create: (_) => CourseRepository(apiClient)),
        Provider(create: (_) => AssessmentRepository(apiClient)),
        Provider(create: (_) => CertificateRepository(apiClient)),
        Provider(create: (_) => ProfileRepository(apiClient)),
        Provider(create: (_) => FaceImageService(apiClient, sessionStore)),
        Provider(
          create: (context) =>
              FaceImageRepository(context.read<FaceImageService>()),
        ),
        Provider(create: (_) => FaceReferenceStore()),
        Provider(
          create: (context) => FaceReferenceSyncService(
            faceImageRepository: context.read<FaceImageRepository>(),
            dio: context.read<ApiClient>().dio,
            store: context.read<FaceReferenceStore>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              DashboardProvider(context.read<DashboardRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CalendarProvider(context.read<CalendarRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              StudyTimeProvider(context.read<StudyTimeRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              LearningPathProvider(context.read<LearningPathRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CourseProvider(context.read<CourseRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AssessmentProvider(context.read<AssessmentRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CertificateProvider(context.read<CertificateRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProfileProvider(context.read<ProfileRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              FaceImageProvider(context.read<FaceImageRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => FaceReferenceProvider(
            syncService: context.read<FaceReferenceSyncService>(),
            store: context.read<FaceReferenceStore>(),
          ),
        ),
      ],
      child: const ThcLmsApp(),
    ),
  );
}

class ThcLmsApp extends StatefulWidget {
  const ThcLmsApp({super.key});

  @override
  State<ThcLmsApp> createState() => _ThcLmsAppState();
}

class _ThcLmsAppState extends State<ThcLmsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
