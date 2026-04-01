import 'package:get/get.dart';
import '../services/interview_stats_service_getx.dart';

/// GetX Controller for Recent Interviews screen
class RecentInterviewsController extends GetxController {
  final InterviewStatsService _statsService = Get.find<InterviewStatsService>();

  // Reactive state
  final RxList<InterviewSession> sessions = <InterviewSession>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxInt limit = 20.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSessions();
  }

  void _loadSessions() {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      _statsService.getRecentInterviewsStream(limit: limit.value).listen(
        (data) {
          sessions.value = data;
          isLoading.value = false;
        },
        onError: (error) {
          print('Error loading sessions: $error');
          errorMessage.value = 'Error loading interviews';
          isLoading.value = false;
        },
      );
    } catch (e) {
      print('Error setting up sessions stream: $e');
      errorMessage.value = 'Error loading interviews';
      isLoading.value = false;
    }
  }

  void loadMore() {
    limit.value += 20;
    _loadSessions();
  }

  bool get hasData => sessions.isNotEmpty;
  
  @override
  void onClose() {
    super.onClose();
  }
}
