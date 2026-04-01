import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/recent_interviews_controller.dart';
import '../controllers/interview_controller.dart';
import '../services/interview_stats_service_getx.dart';

/// Initial binding that initializes core services and controllers
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Services (permanent, survive across routes)
    Get.put<InterviewStatsService>(InterviewStatsService(), permanent: true);
    
    // Auth controller (permanent, needed globally)
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}

/// Binding for main tabs (Home, Recent, Profile, Resources)
class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Dashboard controller
    Get.lazyPut<DashboardController>(() => DashboardController());
    
    // Recent interviews controller
    Get.lazyPut<RecentInterviewsController>(() => RecentInterviewsController());
  }
}

/// Binding for interview session
class InterviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InterviewController>(() => InterviewController());
  }
}
