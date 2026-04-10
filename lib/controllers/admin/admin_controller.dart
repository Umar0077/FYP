import 'dart:developer';

import 'package:get/get.dart';

import '../../models/admin/admin_mock_models.dart';
import '../../services/admin/admin_auth_service.dart';
import '../../services/admin/admin_data_service.dart';

class AdminController extends GetxController {
  AdminController({AdminDataService? dataService, AdminAuthService? authService})
      : _dataService = dataService ?? AdminDataService(),
        _authService = authService ?? AdminAuthService();

  final AdminDataService _dataService;
  final AdminAuthService _authService;

  final users = <MockUser>[].obs;
  final totalUsersCount = 0.obs;
  final interviews = <MockInterview>[].obs;
  final attempts = <MockAttempt>[].obs;
  final userInterviews = <MockInterview>[].obs;
  final resources = <AdminResourceItem>[].obs;
  final jobSuggestions = <AdminJobItem>[].obs;
  final supportTickets = <AdminSupportTicket>[].obs;
  final notifications = <AdminNotificationItem>[].obs;
  final activityLogs = <AdminLogItem>[].obs;
  final userPerformanceLeaderboard = <AdminUserPerformance>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorState = ''.obs;
  final isAdminAuthorized = false.obs;

  final userSearchQuery = ''.obs;
  final interviewSearchQuery = ''.obs;
  final selectedInterviewStatus = 'all'.obs;
  final selectedInterviewDifficulty = 'all'.obs;

  final adminSettings = AdminSettings.defaults().obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    errorState.value = '';

    try {
      isAdminAuthorized.value = await _authService.isCurrentUserAdmin();
      if (!isAdminAuthorized.value) {
        errorState.value = 'You do not have admin access.';
        isLoading.value = false;
        return;
      }

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _dataService.fetchUsers(),
        _dataService.fetchUsersCount(),
        _dataService.fetchInterviews(),
        _dataService.fetchResources().catchError((_) => <AdminResourceItem>[]),
        _dataService.fetchJobSuggestions().catchError((_) => <AdminJobItem>[]),
        _dataService.fetchSupportTickets().catchError((_) => <AdminSupportTicket>[]),
        _dataService.fetchNotifications().catchError((_) => <AdminNotificationItem>[]),
        _dataService.fetchAdminLogs().catchError((_) => <AdminLogItem>[]),
        _dataService.fetchAdminSettings().catchError((_) => AdminSettings.defaults()),
        _dataService
            .fetchUserPerformanceLeaderboard()
            .catchError((_) => <AdminUserPerformance>[]),
      ]);

      users.assignAll(results[0] as List<MockUser>);
      totalUsersCount.value = results[1] as int;
      interviews.assignAll(results[2] as List<MockInterview>);
      resources.assignAll(results[3] as List<AdminResourceItem>);
      jobSuggestions.assignAll(results[4] as List<AdminJobItem>);
      supportTickets.assignAll(results[5] as List<AdminSupportTicket>);
      notifications.assignAll(results[6] as List<AdminNotificationItem>);
      activityLogs.assignAll(results[7] as List<AdminLogItem>);
      adminSettings.value = results[8] as AdminSettings;
      userPerformanceLeaderboard.assignAll(results[9] as List<AdminUserPerformance>);
    } catch (e, st) {
      log('Admin dashboard load failed: $e', name: 'AdminController', stackTrace: st);
      final text = e.toString().toLowerCase();
      if (text.contains('permission-denied') || text.contains('insufficient permissions')) {
        errorState.value = 'Access denied by Firestore rules. Sign in with an admin account and ensure users/{uid}.role is admin.';
      } else {
        errorState.value = 'Failed to load admin data. Please try again.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<MockUser> get filteredUsers {
    final q = userSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q);
    }).toList();
  }

  List<MockInterview> get filteredInterviews {
    final q = interviewSearchQuery.value.trim().toLowerCase();
    return interviews.where((i) {
      final statusMatch = selectedInterviewStatus.value == 'all' ||
          i.status.toLowerCase() == selectedInterviewStatus.value.toLowerCase();
      final difficultyMatch = selectedInterviewDifficulty.value == 'all' ||
          i.difficulty.toLowerCase() == selectedInterviewDifficulty.value.toLowerCase();
      final searchMatch = q.isEmpty ||
          i.id.toLowerCase().contains(q) ||
          i.userId.toLowerCase().contains(q) ||
          i.difficulty.toLowerCase().contains(q);
      return statusMatch && difficultyMatch && searchMatch;
    }).toList();
  }

  Future<void> loadAttemptsForInterview(String interviewId) async {
    try {
      isLoading.value = true;
      attempts.assignAll(await _dataService.fetchAttempts(interviewId));
    } catch (e, st) {
      log('Failed to load attempts: $e', name: 'AdminController', stackTrace: st);
      errorState.value = 'Failed to load interview attempts.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<MockInterview?> getInterview(String interviewId) async {
    final local = interviews.firstWhereOrNull((i) => i.id == interviewId);
    if (local != null) return local;
    return _dataService.fetchInterviewById(interviewId);
  }

  Future<void> loadUserInterviews(String userId) async {
    try {
      userInterviews.assignAll(await _dataService.fetchInterviewsByUser(userId));
    } catch (e, st) {
      log('Failed to load user interviews: $e',
          name: 'AdminController', stackTrace: st);
      userInterviews.clear();
    }
  }

  int get totalUsers => totalUsersCount.value;

  int get totalInterviews => interviews.length;

  int get completedInterviews =>
      interviews.where((i) => i.status.toLowerCase() == 'completed').length;

  double get averageAccuracy =>
      interviews.isEmpty ? 0 : interviews.map((e) => e.avgAccuracy).reduce((a, b) => a + b) / interviews.length;

  double get averageRelevance =>
      interviews.isEmpty ? 0 : interviews.map((e) => e.avgRelevance).reduce((a, b) => a + b) / interviews.length;

  double get averageConfidence {
    if (interviews.isEmpty) return 0;
    final values = interviews
        .map((e) {
          final level = e.confidenceAnalysis.confidence_level;
          if (level > 0) return level;
          return e.emotionReport.summary.average_confidence_overall;
        })
        .toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  int get answeredCountTotal => interviews.fold(0, (sum, i) => sum + i.answeredCount);

  int get skippedCountTotal => interviews.fold(0, (sum, i) => sum + i.skippedCount);

  int get wrongCountTotal => interviews.fold(0, (sum, i) => sum + i.wrongCount);

  Map<String, int> get difficultyDistribution {
    final map = <String, int>{};
    for (final i in interviews) {
      map[i.difficulty] = (map[i.difficulty] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get sessionQualityDistribution {
    final map = <String, int>{};
    for (final i in interviews) {
      final quality = i.emotionReport.summary.session_quality;
      if (quality.isEmpty) continue;
      map[quality] = (map[quality] ?? 0) + 1;
    }
    return map;
  }

  Future<void> createResource({
    required String title,
    required String description,
    required String url,
  }) async {
    isSaving.value = true;
    try {
      await _dataService.addResource(title: title, description: description, url: url);
      resources.assignAll(await _dataService.fetchResources());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> setResourceVisibility(String id, bool isVisible) async {
    await _dataService.updateResourceVisibility(id, isVisible);
    resources.assignAll(await _dataService.fetchResources());
  }

  Future<void> removeResource(String id) async {
    await _dataService.deleteResource(id);
    resources.removeWhere((r) => r.id == id);
  }

  Future<void> createJobSuggestion({
    required String title,
    required String description,
  }) async {
    await _dataService.addJobSuggestion(title: title, description: description);
    jobSuggestions.assignAll(await _dataService.fetchJobSuggestions());
  }

  Future<void> setJobPublished(String id, bool published) async {
    await _dataService.updateJobPublishState(id, published);
    jobSuggestions.assignAll(await _dataService.fetchJobSuggestions());
  }

  Future<void> removeJobSuggestion(String id) async {
    await _dataService.deleteJobSuggestion(id);
    jobSuggestions.removeWhere((j) => j.id == id);
  }

  Future<void> resolveSupportTicket({
    required String ticketId,
    required String reply,
  }) async {
    await _dataService.replySupportTicket(ticketId: ticketId, reply: reply);
    supportTickets.assignAll(await _dataService.fetchSupportTickets());
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    required String audience,
  }) async {
    await _dataService.createNotification(
      title: title,
      message: message,
      audience: audience,
    );
    notifications.assignAll(await _dataService.fetchNotifications());
  }

  Future<void> updateSettings(AdminSettings settings) async {
    adminSettings.value = settings;
    await _dataService.saveAdminSettings(settings);
  }
}
