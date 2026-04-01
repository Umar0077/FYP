import 'package:get/get.dart';

/// GetX Controller for interview session state management
class InterviewController extends GetxController {
  // Reactive state
  final RxInt currentQuestionIndex = 0.obs;
  final RxBool isChecking = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Interview session data
  final RxString sessionId = ''.obs;
  final RxString difficulty = ''.obs;
  final RxInt totalQuestions = 0.obs;
  final RxInt answeredCount = 0.obs;
  final RxInt skippedCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < totalQuestions.value - 1) {
      currentQuestionIndex.value++;
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex.value > 0) {
      currentQuestionIndex.value--;
    }
  }

  void setChecking(bool value) {
    isChecking.value = value;
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void incrementAnswered() {
    answeredCount.value++;
  }

  void incrementSkipped() {
    skippedCount.value++;
  }

  void resetSession() {
    currentQuestionIndex.value = 0;
    isChecking.value = false;
    isLoading.value = false;
    errorMessage.value = '';
    sessionId.value = '';
    answeredCount.value = 0;
    skippedCount.value = 0;
  }

  @override
  void onClose() {
    super.onClose();
  }
}

