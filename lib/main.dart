import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'views/starting/SplashScreen.dart';
import 'views/starting/OnboardingScreen.dart';
import 'views/starting/WelcomeScreen.dart';
import 'views/auth/LoginScreen.dart';
import 'views/auth/RegisterScreen.dart';
import 'views/auth/ForgotPasswordMethodScreen.dart';
import 'views/auth/ForgotPasswordEmailScreen.dart';
import 'views/main/InterviewPrepScreen.dart';
import 'views/main/InterviewScreen.dart';
import 'views/main/InterviewResultScreen.dart';
import 'views/main/MainTabs.dart';
import 'views/main/PreferenceScreen.dart';
import 'views/main/EditInformationScreen.dart';
import 'views/main/SupportChatScreen.dart';
import 'views/main/PracticalQuestionsScreen.dart';
import 'views/main/JobSuggestionsScreen.dart';
import 'theme/app_theme.dart';
import 'bindings/app_bindings.dart';

import 'views/admin/admin_login_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'views/admin/admin_user_management_screen.dart';
import 'views/admin/admin_user_leaderboard_screen.dart';
import 'views/admin/admin_user_detail_screen.dart';
import 'views/admin/admin_interview_management_screen.dart';
import 'views/admin/admin_interview_detail_screen.dart';
import 'views/admin/admin_results_review_screen.dart';
import 'views/admin/admin_emotion_tracking_screen.dart';
import 'views/admin/admin_resources_management_screen.dart';
import 'views/admin/admin_job_suggestions_management_screen.dart';
import 'views/admin/admin_support_screen.dart';
import 'views/admin/admin_support_chat_detail_screen.dart';
import 'views/admin/admin_analytics_screen.dart';
import 'views/admin/admin_notifications_screen.dart';
import 'views/admin/admin_activity_logs_screen.dart';
import 'views/admin/admin_settings_screen.dart';
import 'bindings/admin/admin_binding.dart';
import 'core/guards/admin_route_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // safer initialization
    );

    // Print available Firebase apps for verification
    print(
      'Firebase initialized. Apps: ${Firebase.apps.map((a) => a.name).toList()}',
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nova Prep',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: currentMode,
          initialBinding: AppBinding(),
          home: const SplashScreen(),
          getPages: [
            GetPage(name: '/', page: () => const SplashScreen()),
            GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
            GetPage(name: '/welcome', page: () => const WelcomeScreen()),
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/register', page: () => const RegisterScreen()),
            GetPage(
              name: '/forgot',
              page: () => const ForgotPasswordMethodScreen(),
            ),
            GetPage(
              name: '/forgot/email',
              page: () => const ForgotPasswordEmailScreen(),
            ),
            GetPage(
              name: '/home',
              page: () => const MainTabs(),
              binding: MainBinding(),
            ),
            GetPage(
              name: '/resources_tab',
              page: () => const MainTabs(initialIndex: 1),
              binding: MainBinding(),
            ),
            GetPage(
              name: '/recent_tab',
              page: () => const MainTabs(initialIndex: 2),
              binding: MainBinding(),
            ),
            GetPage(
              name: '/profile_tab',
              page: () => const MainTabs(initialIndex: 3),
              binding: MainBinding(),
            ),
            GetPage(
              name: '/interview_prep',
              page: () => const InterviewPrepScreen(),
            ),
            GetPage(
              name: '/interview',
              page: () => const InterviewScreen(),
              binding: InterviewBinding(),
            ),
            GetPage(
              name: '/interview_result',
              page: () => const InterviewResultScreen(),
            ),
            GetPage(
              name: '/profile/preferences',
              page: () => const PreferenceScreen(),
            ),
            GetPage(
              name: '/profile/edit-info',
              page: () => const EditInformationScreen(),
            ),
            GetPage(
              name: '/profile/support',
              page: () => const SupportChatScreen(),
            ),
            GetPage(
              name: '/practical_questions',
              page: () => const PracticalQuestionsScreen(),
            ),
            GetPage(
              name: '/job_suggestions',
              page: () => const JobSuggestionsScreen(),
            ),

            // --- Admin Routes ---
            GetPage(name: '/admin/login', page: () => const AdminLoginScreen()),
            GetPage(
              name: '/admin/dashboard',
              page: () => const AdminDashboardScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/users',
              page: () => const AdminUserManagementScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/users/leaderboard',
              page: () => const AdminUserLeaderboardScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/users/detail',
              page: () => const AdminUserDetailScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/interviews',
              page: () => const AdminInterviewManagementScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/interviews/detail',
              page: () => const AdminInterviewDetailScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/interviews/results',
              page: () => const AdminResultsReviewScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/emotion_tracking',
              page: () => const AdminEmotionTrackingScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/resources',
              page: () => const AdminResourcesManagementScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/jobs',
              page: () => const AdminJobSuggestionsManagementScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/support',
              page: () => const AdminSupportScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/support/chat',
              page: () => const AdminSupportChatDetailScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/analytics',
              page: () => const AdminAnalyticsScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/notifications',
              page: () => const AdminNotificationsScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/logs',
              page: () => const AdminActivityLogsScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
            GetPage(
              name: '/admin/settings',
              page: () => const AdminSettingsScreen(),
              binding: AdminBinding(),
              middlewares: [AdminRouteGuard()],
            ),
          ],
        );
      },
    );
  }
}
