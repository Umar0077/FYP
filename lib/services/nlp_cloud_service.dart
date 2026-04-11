import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

class NLPCloudException implements Exception {
  NLPCloudException(
    this.code,
    this.message, {
    this.statusCode,
    this.details,
  });

  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() {
    final suffix = statusCode == null ? '' : ' (HTTP $statusCode)';
    return 'NLPCloudException[$code]: $message$suffix';
  }
}

class NLPCloudService {
  NLPCloudService({
    FirebaseFunctions? functions,
    http.Client? httpClient,
  })  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
        _httpClient = httpClient ?? http.Client();

  static const String _evaluateAttemptUrl =
      'https://us-central1-moiz-fyp.cloudfunctions.net/evaluateAttemptHttp';

  static const Duration _evaluateAttemptTimeout = Duration(seconds: 25);
  static const Duration _recomputeTimeout = Duration(seconds: 30);

  final FirebaseFunctions _functions;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> evaluateAttempt({
    required String interviewId,
    required String attemptId,
  }) async {
    final payload = <String, dynamic>{
      'interviewId': interviewId,
      'attemptId': attemptId,
    };

    developer.log(
      'Cloud evaluation requested for interviewId=$interviewId attemptId=$attemptId',
      name: 'NLPCloudService.evaluateAttempt',
    );

    final uri = Uri.parse(_evaluateAttemptUrl);
    http.Response response;

    try {
      response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_evaluateAttemptTimeout);
    } on TimeoutException catch (error) {
      throw NLPCloudException(
        'evaluate-timeout',
        'Cloud attempt evaluation timed out.',
        details: error.toString(),
      );
    } catch (error) {
      throw NLPCloudException(
        'evaluate-request-failed',
        'Could not reach evaluateAttemptHttp.',
        details: error.toString(),
      );
    }

    final envelope = _decodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NLPCloudException(
        'evaluate-http-error',
        envelope['error']?.toString() ?? 'Cloud evaluator returned an error response.',
        statusCode: response.statusCode,
        details: envelope,
      );
    }

    if (envelope['success'] != true) {
      throw NLPCloudException(
        'evaluate-unsuccessful',
        envelope['error']?.toString() ?? 'Cloud evaluator did not succeed.',
        statusCode: response.statusCode,
        details: envelope,
      );
    }

    final data = _asMap(envelope['data']);
    if (data.isEmpty) {
      throw NLPCloudException(
        'evaluate-empty-data',
        'Cloud evaluator response did not contain evaluated attempt data.',
        statusCode: response.statusCode,
        details: envelope,
      );
    }

    developer.log(
      'Cloud evaluation success for attemptId=$attemptId',
      name: 'NLPCloudService.evaluateAttempt',
    );

    return data;
  }

  Future<Map<String, dynamic>> recomputeInterviewResult({
    required String interviewId,
  }) async {
    developer.log(
      'Calling recomputeInterviewResultCallable for interviewId=$interviewId',
      name: 'NLPCloudService.recomputeInterviewResult',
    );

    final callable = _functions.httpsCallable(
      'recomputeInterviewResultCallable',
      options: HttpsCallableOptions(timeout: _recomputeTimeout),
    );

    HttpsCallableResult<dynamic> result;
    try {
      result = await callable
          .call(<String, dynamic>{'interviewId': interviewId})
          .timeout(_recomputeTimeout);
    } on TimeoutException catch (error) {
      throw NLPCloudException(
        'recompute-timeout',
        'recomputeInterviewResultCallable timed out.',
        details: error.toString(),
      );
    } on FirebaseFunctionsException catch (error) {
      throw NLPCloudException(
        'recompute-functions-error',
        error.message ?? 'Callable recomputeInterviewResult failed.',
        details: error.details,
      );
    } catch (error) {
      throw NLPCloudException(
        'recompute-unknown-error',
        'Unexpected error while recomputing interview result.',
        details: error.toString(),
      );
    }

    final data = _asMap(result.data);

    if (data['success'] == false) {
      throw NLPCloudException(
        'recompute-unsuccessful',
        data['error']?.toString() ?? 'Callable recomputeInterviewResult returned unsuccessful status.',
        details: data,
      );
    }

    developer.log(
      'recomputeInterviewResultCallable success for interviewId=$interviewId',
      name: 'NLPCloudService.recomputeInterviewResult',
    );

    return data;
  }

  Map<String, dynamic> _decodeMap(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw NLPCloudException(
        'invalid-json-shape',
        'Expected a JSON object from cloud evaluator.',
        details: decoded,
      );
    } on FormatException catch (error) {
      throw NLPCloudException(
        'invalid-json',
        'Cloud evaluator returned invalid JSON.',
        details: error.message,
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }
}
