import 'package:get/get.dart';
import '../services/interview_stats_service_getx.dart';

/// GetX Controller for Dashboard screen state management
class DashboardController extends GetxController {
  final InterviewStatsService _statsService = Get.find<InterviewStatsService>();

  // Reactive state
  final Rxn<InterviewStats> stats = Rxn<InterviewStats>();
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadStats();
  }

  void _loadStats() {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      _statsService.getStatsStream().listen(
        (data) {
          stats.value = data;
          isLoading.value = false;
        },
        onError: (error) {
          print('Error loading stats: $error');
          errorMessage.value = 'Error loading interview statistics';
          isLoading.value = false;
        },
      );
    } catch (e) {
      print('Error setting up stats stream: $e');
      errorMessage.value = 'Error loading interview statistics';
      isLoading.value = false;
    }
  }

  bool get hasData => stats.value != null && stats.value!.interviewsCompleted > 0;
  
  int get interviewsCompleted => stats.value?.interviewsCompleted ?? 0;
  int get averageScore => stats.value?.averageScore ?? 0;
  double get successRate => stats.value?.successRate ?? 0.0;
  double get skillImprovement => stats.value?.skillImprovement ?? 0.0;
  
  @override
  void onClose() {
    super.onClose();
  }
}
