import 'dart:developer';

class AdminBackendService {
  Future<Map<String, dynamic>> getSystemHealth() async {
    log('TODO: integrate backend system health endpoint', name: 'AdminBackendService');
    return <String, dynamic>{'status': 'unknown', 'source': 'fallback'};
  }

  Future<Map<String, dynamic>> getInterviewSummary() async {
    log('TODO: integrate backend interview summary endpoint', name: 'AdminBackendService');
    return <String, dynamic>{'status': 'fallback'};
  }
}
