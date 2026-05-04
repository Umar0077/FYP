import 'dart:convert';
import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service for analyzing confidence level using Gemini based on emotion data
class GeminiConfidenceAnalyzer {
  static const String _apiKey = '??????';

  // List of models to try (fallback chain) - updated with valid models
  static const List<String> _modelNames = [
    'models/gemini-2.5-flash-lite',
    'models/gemini-2.5-flash',
    'models/gemini-1.5-flash',
    'models/gemini-pro',
  ];

  static const Set<String> _positiveEmotions = {
    'happy',
    'neutral',
    'calm',
    'engaged',
    'confident',
    'surprise',
  };

  static const Set<String> _negativeEmotions = {
    'fear',
    'sad',
    'angry',
    'disgust',
    'anxious',
    'nervous',
  };

  GenerativeModel? _model;
  String? _selectedModelId;

  void _log(String scope, String message, {Object? error, int level = 800}) {
    developer.log(message, name: 'GeminiAnalyzer.$scope', error: error, level: level);
  }

  /// Get or initialize Gemini model with fallback
  Future<GenerativeModel?> _getModel() async {
    if (_model != null) {
      print('🤖 Using cached Gemini model for confidence: $_selectedModelId');
      return _model;
    }
    
    print('🔍 Selecting Gemini model for confidence analysis...');
    
    for (final modelName in _modelNames) {
      try {
        print('   Testing: $modelName');
        developer.log(
          'Trying Gemini model: $modelName',
          name: 'GeminiAnalyzer.getModel',
        );
        
        final testModel = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );
        
        // Test the model with a simple request
        await testModel.generateContent([
          Content.text('Test: return {"status": "ok"}')
        ]).timeout(Duration(seconds: 5));
        
        _model = testModel;
        _selectedModelId = modelName;
        print('✅ Selected Gemini model for confidence: $modelName\n');
        developer.log(
          'Using Gemini model: $modelName',
          name: 'GeminiAnalyzer.getModel',
        );
        return _model;
      } catch (e) {
        print('   ❌ Failed: $e');
        developer.log(
          'Model $modelName failed: $e',
          name: 'GeminiAnalyzer.getModel',
          error: e,
          level: 900,
        );
      }
    }
    
    developer.log(
      'All Gemini models failed',
      name: 'GeminiAnalyzer.getModel',
      level: 1000,
    );
    return null;
  }

  /// Analyze confidence based on interview performance and emotion data
  /// 
  /// Parameters:
  /// - interviewSummary: Brief summary of interview (e.g., "3 questions, 2 correct")
  /// - nlpScores: Map of NLP evaluation scores (e.g., {"accuracy": 0.75, "fluency": 0.8})
  /// - emotionReport: Full emotion report from backend
  /// 
  /// Returns confidence analysis as structured JSON
  Future<Map<String, dynamic>?> analyzeConfidence({
    required String interviewSummary,
    required Map<String, dynamic> nlpScores,
    required Map<String, dynamic> emotionReport,
  }) async {
    final normalizedEmotion = _normalizeEmotionReport(emotionReport);
    _log('analyzeConfidence', 'Parsed emotion report object: ${_safeJson(normalizedEmotion)}');

    final validation = _validateEmotionReport(normalizedEmotion);
    if (!(validation['isValid'] as bool)) {
      final reason = validation['reason']?.toString() ?? 'emotion report invalid';
      _log('analyzeConfidence', 'Fallback used because report is invalid: $reason', level: 900);
      return _getFallbackAnalysis(
        nlpScores,
        normalizedEmotion,
        reason: reason,
      );
    }

    try {
      developer.log(
        'Starting confidence analysis',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );

      _log('analyzeConfidence', 'Input NLP scores: ${_safeJson(nlpScores)}');
      _log('analyzeConfidence', 'Input interview summary: $interviewSummary');
      
      // Get model with fallback
      final model = await _getModel();
      if (model == null) {
        developer.log(
          'No Gemini model available, returning deterministic emotion-driven result',
          name: 'GeminiAnalyzer.analyzeConfidence',
          level: 900,
        );
        return _buildDeterministicAnalysis(
          nlpScores: nlpScores,
          normalizedEmotion: normalizedEmotion,
          source: 'rule_engine_no_model',
          fallbackReason: 'gemini model unavailable',
        );
      }

      // Extract key metrics from emotion report
      final timelineHighlights = _extractTimelineHighlights(normalizedEmotion);

      // Build prompt
      final prompt = _buildPrompt(
        interviewSummary: interviewSummary,
        nlpScores: nlpScores,
        emotionSummary: normalizedEmotion,
        timelineHighlights: timelineHighlights,
      );

      developer.log(
        'Sending request to Gemini',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      if (text.isEmpty) {
        _log(
          'analyzeConfidence',
          'Empty response from Gemini. Using deterministic emotion-driven analysis.',
          level: 900,
        );
        return _buildDeterministicAnalysis(
          nlpScores: nlpScores,
          normalizedEmotion: normalizedEmotion,
          source: 'rule_engine_empty_gemini_response',
          fallbackReason: 'empty Gemini response',
        );
      }

      developer.log(
        'Parsing Gemini response',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );

      final parsed = _parseJsonResponse(text);
      if (parsed == null) {
        _log(
          'analyzeConfidence',
          'Gemini JSON parsing failed. Using deterministic emotion-driven analysis.',
          level: 900,
        );
        return _buildDeterministicAnalysis(
          nlpScores: nlpScores,
          normalizedEmotion: normalizedEmotion,
          source: 'rule_engine_gemini_parse_failed',
          fallbackReason: 'Gemini response was not valid JSON',
        );
      }

      final sanitized = _sanitizeGeminiResult(
        parsed,
        normalizedEmotion,
      );
      if (sanitized == null) {
        _log(
          'analyzeConfidence',
          'Gemini response missing required fields after sanitization. Using deterministic analysis.',
          level: 900,
        );
        return _buildDeterministicAnalysis(
          nlpScores: nlpScores,
          normalizedEmotion: normalizedEmotion,
          source: 'rule_engine_gemini_sanitization_failed',
          fallbackReason: 'Gemini response missing required confidence fields',
        );
      }

      developer.log(
        'Confidence analysis successful',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );

      _log('analyzeConfidence', 'Output returned by confidence analyzer: ${_safeJson(sanitized)}');
      return sanitized;
    } catch (e) {
      developer.log(
        'Confidence analysis error: $e',
        name: 'GeminiAnalyzer.analyzeConfidence',
        error: e,
        level: 900,
      );

      return _buildDeterministicAnalysis(
        nlpScores: nlpScores,
        normalizedEmotion: normalizedEmotion,
        source: 'rule_engine_gemini_exception',
        fallbackReason: 'Gemini call failed: $e',
      );
    }
  }

  /// Generate fallback analysis when Gemini is unavailable
  Map<String, dynamic> _getFallbackAnalysis(
    Map<String, dynamic> nlpScores,
    Map<String, dynamic> normalizedEmotion, {
    required String reason,
    }
  ) {
    final nlpPercent = _computeNlpPercent(nlpScores);
    final label = _labelFromScore(nlpPercent);
    final summaryUsed = _buildEmotionSummaryUsed(normalizedEmotion);

    return {
      'confidence_level': nlpPercent,
      'confidence_label': label,
      'reasoning': 'Emotion report unavailable or invalid. Confidence was estimated from NLP interview performance only.',
      'emotion_based_observations': [
        'Emotion-driven confidence could not be computed because required emotion report fields were invalid or missing.',
        'Fallback was used with reason: $reason',
      ],
      'coaching_tips': ['Continue practicing to improve performance'],
      'emotion_summary_used': summaryUsed,
      'analysis_source': 'fallback_nlp_only',
      'fallback_used': true,
      'fallback_reason': reason,
    };
  }

  Map<String, dynamic> _normalizeEmotionReport(Map<String, dynamic> rawReport) {
    final report = _extractEmotionPayload(rawReport);
    final summary = _asMap(report['summary']) ?? <String, dynamic>{};

    final emotionCounts = _parseEmotionCounts(report['emotion_counts']);
    final averageConfidence = _parseAverageConfidence(
      report['average_confidence'] ?? summary['average_confidence_overall'],
      emotionCounts,
    );

    int savedFrames =
        _asInt(report['saved_frames']) ??
        _asInt(report['total_frames_processed']) ??
        _asInt(summary['total_frames_processed']) ??
        _asInt(summary['total_frames']) ??
        0;

    if (savedFrames <= 0 && emotionCounts.isNotEmpty) {
      savedFrames = emotionCounts.values.fold<int>(0, (sum, count) => sum + count);
    }

    final durationSecondsRaw =
        _asDouble(report['duration_seconds']) ??
        _asDouble(report['total_duration_seconds']) ??
        _asDouble(summary['total_duration_seconds']) ??
        0.0;
    final durationSeconds = durationSecondsRaw > 0
        ? durationSecondsRaw
        : (savedFrames > 0 ? savedFrames * 0.9 : 0.0);

    final dominantEmotion = _deriveDominantEmotion(
      report: report,
      summary: summary,
      emotionCounts: emotionCounts,
    );

    final timeline = _normalizeTimeline(report['timeline'] ?? summary['timeline']);
    final volatilityPercent = _computeVolatilityPercent(timeline, emotionCounts);

    return {
      'emotion_counts': emotionCounts,
      'average_confidence': averageConfidence,
      'dominant_emotion': dominantEmotion,
      'duration_seconds': durationSeconds,
      'saved_frames': savedFrames,
      'timeline': timeline,
      'volatility_percent': volatilityPercent,
      'raw_report_keys': report.keys.toList(),
    };
  }

  Map<String, dynamic> _extractEmotionPayload(Map<String, dynamic> rawReport) {
    final nestedDirect = _asMap(rawReport['emotion_report']) ?? _asMap(rawReport['emotionReport']);
    if (nestedDirect != null) {
      return nestedDirect;
    }

    final nestedData = _asMap(rawReport['data']);
    final nestedDataReport = nestedData == null ? null : _asMap(nestedData['emotion_report']);
    if (nestedDataReport != null) {
      return nestedDataReport;
    }

    return rawReport;
  }

  Map<String, dynamic> _validateEmotionReport(Map<String, dynamic> normalizedEmotion) {
    final reasons = <String>[];

    final counts = (normalizedEmotion['emotion_counts'] as Map<String, int>?) ?? <String, int>{};
    final avgConfidence = _asDouble(normalizedEmotion['average_confidence']);
    final dominantEmotion = (normalizedEmotion['dominant_emotion'] ?? '').toString().trim().toLowerCase();
    final durationSeconds = _asDouble(normalizedEmotion['duration_seconds']) ?? 0.0;
    final savedFrames = _asInt(normalizedEmotion['saved_frames']) ?? 0;

    if (counts.isEmpty) {
      reasons.add('emotion_counts missing or empty');
    }

    if (avgConfidence == null || avgConfidence <= 0) {
      reasons.add('average_confidence missing or invalid');
    }

    if (dominantEmotion.isEmpty || dominantEmotion == 'unknown') {
      reasons.add('dominant_emotion missing or could not be derived');
    }

    if (durationSeconds <= 0) {
      reasons.add('duration_seconds missing or invalid');
    }

    if (savedFrames <= 0) {
      reasons.add('saved_frames missing or invalid');
    }

    return {
      'isValid': reasons.isEmpty,
      'reason': reasons.isEmpty ? '' : reasons.join('; '),
    };
  }

  Map<String, dynamic> _buildDeterministicAnalysis({
    required Map<String, dynamic> nlpScores,
    required Map<String, dynamic> normalizedEmotion,
    required String source,
    String? fallbackReason,
  }) {
    final nlpPercent = _computeNlpPercent(nlpScores);
    final emotionPercent = _computeEmotionPercent(normalizedEmotion);
    final finalScore = _clampPercent((emotionPercent * 0.65) + (nlpPercent * 0.35));
    final confidenceLabel = _labelFromScore(finalScore);
    final summaryUsed = _buildEmotionSummaryUsed(normalizedEmotion);
    final observations = _buildEmotionObservations(normalizedEmotion, emotionPercent, nlpPercent);
    final coachingTips = _buildCoachingTips(normalizedEmotion);

    final reasoning =
        'Confidence was computed from real emotion tracking data (dominant emotion: ${summaryUsed['dominant_emotion']}, '
        'average confidence: ${(summaryUsed['average_confidence'] as double).toStringAsFixed(1)}%) '
        'and interview NLP performance (${nlpPercent.toStringAsFixed(1)}%).';

    final result = <String, dynamic>{
      'confidence_level': finalScore,
      'confidence_label': confidenceLabel,
      'reasoning': reasoning,
      'emotion_based_observations': observations,
      'coaching_tips': coachingTips,
      'emotion_summary_used': summaryUsed,
      'analysis_source': source,
      'fallback_used': false,
    };

    if (fallbackReason != null && fallbackReason.trim().isNotEmpty) {
      result['analysis_note'] = fallbackReason;
    }

    _log('deterministic', 'Output returned by confidence analyzer: ${_safeJson(result)}');
    return result;
  }

  /// Extract timeline highlights for Gemini analysis
  List<String> _extractTimelineHighlights(Map<String, dynamic> normalizedEmotion) {
    final highlights = <String>[];

    final timeline = (normalizedEmotion['timeline'] as List<Map<String, dynamic>>?) ??
        const <Map<String, dynamic>>[];
    if (timeline.isEmpty) {
      return highlights;
    }

    // Find streaks of same emotion
    String? currentEmotion;
    int streakLength = 0;
    int maxStreakLength = 0;
    String? maxStreakEmotion;
    
    for (final entry in timeline) {
      final emotion = entry['emotion']?.toString();
      
      if (emotion == currentEmotion) {
        streakLength++;
      } else {
        if (streakLength > maxStreakLength) {
          maxStreakLength = streakLength;
          maxStreakEmotion = currentEmotion;
        }
        currentEmotion = emotion;
        streakLength = 1;
      }
    }
    
    // Check final streak
    if (streakLength > maxStreakLength) {
      maxStreakLength = streakLength;
      maxStreakEmotion = currentEmotion;
    }
    
    if (maxStreakLength > 5 && maxStreakEmotion != null) {
      highlights.add('Longest emotion streak: $maxStreakEmotion for $maxStreakLength frames');
    }
    
    // Count emotion transitions (volatility indicator)
    int transitionCount = 0;
    for (int i = 1; i < timeline.length; i++) {
      if (timeline[i]['emotion'] != timeline[i - 1]['emotion']) {
        transitionCount++;
      }
    }
    
    if (timeline.isNotEmpty) {
      final volatility = (transitionCount / timeline.length * 100).toStringAsFixed(1);
      highlights.add('Emotion volatility: $volatility% (${transitionCount} transitions in ${timeline.length} frames)');
    }
    
    // Count spikes of specific emotions (fear, surprise)
    final emotionCounts = <String, int>{};
    for (final entry in timeline) {
      final emotion = entry['emotion']?.toString();
      if (emotion != null) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }
    
    if ((emotionCounts['fear'] ?? 0) > timeline.length * 0.15) {
      highlights.add('Significant fear detected: ${emotionCounts['fear']} frames');
    }
    
    if ((emotionCounts['surprise'] ?? 0) > timeline.length * 0.15) {
      highlights.add('Frequent surprise: ${emotionCounts['surprise']} frames');
    }
    
    return highlights;
  }

  /// Build prompt for Gemini
  String _buildPrompt({
    required String interviewSummary,
    required Map<String, dynamic> nlpScores,
    required Map<String, dynamic> emotionSummary,
    required List<String> timelineHighlights,
  }) {
    return '''
You are an expert interview coach analyzing a candidate's confidence level during a technical interview.

INTERVIEW SUMMARY:
$interviewSummary

NLP EVALUATION SCORES:
${_formatNlpScores(nlpScores)}

EMOTION TRACKING DATA:
${_formatEmotionSummary(emotionSummary)}

TIMELINE HIGHLIGHTS:
${timelineHighlights.isEmpty ? 'No significant patterns detected' : timelineHighlights.map((h) => '- $h').join('\n')}

TASK:
Analyze the candidate's overall confidence level during the interview based on:
1. Interview performance (NLP scores)
2. Emotion distribution and patterns
3. Emotional stability vs volatility
4. Alignment between performance and emotional state

Return a JSON object with the following structure:
{
  "confidence_level": <number 0-100>,
  "confidence_label": "<low|medium|high>",
  "reasoning": "<short paragraph explaining the confidence assessment>",
  "emotion_based_observations": ["<observation 1>", "<observation 2>", ...],
  "coaching_tips": ["<tip 1>", "<tip 2>", ...],
  "emotion_summary_used": {
    "dominant_emotion": "<most common emotion>",
    "average_confidence": <average confidence score>,
    "volatility_assessment": "<low|medium|high>"
  }
}

GUIDELINES:
- confidence_level: 0-40 = low, 41-70 = medium, 71-100 = high
- reasoning: 2-3 sentences max
- emotion_based_observations: 2-4 key observations about emotional patterns
- coaching_tips: 3-5 actionable tips to improve confidence
- Consider that neutral/happy emotions with high confidence indicate good composure
- Fear/sad emotions or high volatility indicate nervousness
- Balance NLP scores with emotion data (someone with good answers but fearful emotions may still lack confidence)
- Return ONLY pure JSON. Do not wrap in markdown code fences.
''';
  }

  /// Format NLP scores for prompt
  String _formatNlpScores(Map<String, dynamic> scores) {
    final buffer = StringBuffer();
    scores.forEach((key, value) {
      buffer.writeln('- $key: $value');
    });
    return buffer.toString();
  }

  /// Format emotion summary for prompt
  String _formatEmotionSummary(Map<String, dynamic> summary) {
    final buffer = StringBuffer();

    if (summary.containsKey('emotion_counts')) {
      buffer.writeln('Emotion Distribution:');
      final counts = summary['emotion_counts'] as Map<String, int>;
      counts.forEach((emotion, count) {
        buffer.writeln('  - $emotion: $count frames');
      });
    }

    if (summary.containsKey('average_confidence')) {
      final avgConf = _asDouble(summary['average_confidence']) ?? 0.0;
      buffer.writeln('Average Confidence: ${avgConf.toStringAsFixed(2)}');
    }

    if (summary.containsKey('dominant_emotion')) {
      final dominant = summary['dominant_emotion'];
      buffer.writeln('Dominant Emotion: $dominant');
    }

    if (summary.containsKey('volatility_percent')) {
      final volatility = _asDouble(summary['volatility_percent']) ?? 0.0;
      buffer.writeln('Volatility: ${volatility.toStringAsFixed(1)}%');
    }

    if (summary.containsKey('saved_frames')) {
      buffer.writeln('Total Frames Analyzed: ${summary['saved_frames']}');
    }

    if (summary.containsKey('duration_seconds')) {
      final duration = _asDouble(summary['duration_seconds']) ?? 0.0;
      buffer.writeln('Duration Seconds: ${duration.toStringAsFixed(1)}');
    }

    return buffer.toString();
  }

  Map<String, dynamic>? _parseJsonResponse(String text) {
    String candidate = text.trim();
    if (candidate.isEmpty) {
      return null;
    }

    candidate = candidate.replaceAll(RegExp(r'^```json\s*', multiLine: false), '');
    candidate = candidate.replaceAll(RegExp(r'^```\s*', multiLine: false), '');
    candidate = candidate.replaceAll(RegExp(r'\s*```$', multiLine: false), '');

    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }

    candidate = candidate.substring(start, end + 1);

    try {
      final decoded = json.decode(candidate);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _sanitizeGeminiResult(
    Map<String, dynamic> result,
    Map<String, dynamic> normalizedEmotion,
  ) {
    double confidenceLevel = _asDouble(result['confidence_level'] ?? result['confidenceLevel']) ?? 0.0;
    if (confidenceLevel <= 1.0) {
      confidenceLevel = confidenceLevel * 100.0;
    }
    confidenceLevel = _clampPercent(confidenceLevel);

    final confidenceLabel = _normalizeLabel(
      result['confidence_label'] ?? result['confidenceLabel'],
      confidenceLevel,
    );

    final reasoning = (result['reasoning'] ?? '').toString().trim();
    if (reasoning.isEmpty) {
      return null;
    }

    final observations = _toStringList(
      result['emotion_based_observations'] ?? result['observations'],
    );
    final coachingTips = _toStringList(result['coaching_tips']);

    final summaryUsedFromGemini = _asMap(result['emotion_summary_used']);
    final defaultSummaryUsed = _buildEmotionSummaryUsed(normalizedEmotion);
    final summaryUsed = <String, dynamic>{
      'dominant_emotion':
          summaryUsedFromGemini?['dominant_emotion']?.toString().trim().isNotEmpty == true
              ? summaryUsedFromGemini!['dominant_emotion'].toString().trim().toLowerCase()
              : defaultSummaryUsed['dominant_emotion'],
      'average_confidence': _clampPercent(
        _asDouble(summaryUsedFromGemini?['average_confidence']) ??
            (defaultSummaryUsed['average_confidence'] as double),
      ),
      'volatility_assessment':
          (summaryUsedFromGemini?['volatility_assessment'] ?? defaultSummaryUsed['volatility_assessment'])
              .toString()
              .trim()
              .toLowerCase(),
      'duration_seconds': defaultSummaryUsed['duration_seconds'],
      'saved_frames': defaultSummaryUsed['saved_frames'],
    };

    return {
      'confidence_level': confidenceLevel,
      'confidence_label': confidenceLabel,
      'reasoning': reasoning,
      'emotion_based_observations': observations,
      'coaching_tips': coachingTips,
      'emotion_summary_used': summaryUsed,
      'analysis_source': 'gemini',
      'fallback_used': false,
    };
  }

  Map<String, int> _parseEmotionCounts(dynamic value) {
    final parsed = <String, int>{};
    final map = _asMap(value);
    if (map == null) {
      return parsed;
    }

    map.forEach((key, rawValue) {
      final count = _asInt(rawValue) ?? 0;
      if (count > 0) {
        parsed[key.trim().toLowerCase()] = count;
      }
    });

    return parsed;
  }

  double _parseAverageConfidence(dynamic value, Map<String, int> emotionCounts) {
    final direct = _asDouble(value);
    if (direct != null) {
      return _clampPercent(direct <= 1.0 ? direct * 100.0 : direct);
    }

    final map = _asMap(value);
    if (map == null || map.isEmpty) {
      return 0.0;
    }

    double weightedSum = 0.0;
    int totalWeight = 0;
    double simpleSum = 0.0;
    int simpleCount = 0;

    map.forEach((emotion, rawConfidence) {
      final conf = _asDouble(rawConfidence);
      if (conf == null) {
        return;
      }

      final normalizedConf = conf <= 1.0 ? conf * 100.0 : conf;
      final weight = emotionCounts[emotion.trim().toLowerCase()] ?? 0;
      if (weight > 0) {
        weightedSum += normalizedConf * weight;
        totalWeight += weight;
      }

      simpleSum += normalizedConf;
      simpleCount++;
    });

    if (totalWeight > 0) {
      return _clampPercent(weightedSum / totalWeight);
    }

    if (simpleCount > 0) {
      return _clampPercent(simpleSum / simpleCount);
    }

    return 0.0;
  }

  String _deriveDominantEmotion({
    required Map<String, dynamic> report,
    required Map<String, dynamic>? summary,
    required Map<String, int> emotionCounts,
  }) {
    final direct = report['dominant_emotion']?.toString().trim().toLowerCase();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final dominantList = _asList(summary?['dominant_emotions']);
    if (dominantList != null && dominantList.isNotEmpty) {
      final first = dominantList.first.toString().trim().toLowerCase();
      if (first.isNotEmpty) {
        return first;
      }
    }

    if (emotionCounts.isNotEmpty) {
      String dominant = 'unknown';
      int maxCount = -1;
      emotionCounts.forEach((emotion, count) {
        if (count > maxCount) {
          maxCount = count;
          dominant = emotion;
        }
      });
      return dominant;
    }

    return 'unknown';
  }

  List<Map<String, dynamic>> _normalizeTimeline(dynamic value) {
    final timeline = <Map<String, dynamic>>[];
    final list = _asList(value);
    if (list == null) {
      return timeline;
    }

    for (final item in list) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }

      final emotion = map['emotion']?.toString().trim().toLowerCase();
      if (emotion == null || emotion.isEmpty) {
        continue;
      }

      timeline.add({
        'emotion': emotion,
        if (map.containsKey('timestamp')) 'timestamp': map['timestamp'],
        if (map.containsKey('confidence')) 'confidence': map['confidence'],
      });
    }

    return timeline;
  }

  double _computeVolatilityPercent(
    List<Map<String, dynamic>> timeline,
    Map<String, int> emotionCounts,
  ) {
    if (timeline.length > 1) {
      int transitions = 0;
      for (int i = 1; i < timeline.length; i++) {
        if (timeline[i]['emotion'] != timeline[i - 1]['emotion']) {
          transitions++;
        }
      }
      return _clampPercent((transitions / (timeline.length - 1)) * 100.0);
    }

    final total = emotionCounts.values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return 0.0;
    }

    final uniqueEmotions = emotionCounts.length;
    final spreadRatio = uniqueEmotions / total;
    return _clampPercent(spreadRatio * 150.0);
  }

  Map<String, dynamic> _buildEmotionSummaryUsed(Map<String, dynamic> normalizedEmotion) {
    final dominantEmotion = (normalizedEmotion['dominant_emotion'] ?? 'unknown').toString();
    final averageConfidence = _clampPercent(_asDouble(normalizedEmotion['average_confidence']) ?? 0.0);
    final volatilityPercent = _clampPercent(_asDouble(normalizedEmotion['volatility_percent']) ?? 0.0);
    final durationSeconds = _asDouble(normalizedEmotion['duration_seconds']) ?? 0.0;
    final savedFrames = _asInt(normalizedEmotion['saved_frames']) ?? 0;

    return {
      'dominant_emotion': dominantEmotion,
      'average_confidence': averageConfidence,
      'volatility_assessment': _volatilityLabel(volatilityPercent),
      'duration_seconds': durationSeconds,
      'saved_frames': savedFrames,
    };
  }

  double _computeEmotionPercent(Map<String, dynamic> normalizedEmotion) {
    final counts = (normalizedEmotion['emotion_counts'] as Map<String, int>?) ?? <String, int>{};
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final avgConfidence = _clampPercent(_asDouble(normalizedEmotion['average_confidence']) ?? 0.0);
    final volatilityPercent = _clampPercent(_asDouble(normalizedEmotion['volatility_percent']) ?? 0.0);
    final stabilityScore = _clampPercent(100.0 - volatilityPercent);

    double positiveRatio = 0.0;
    double negativeRatio = 0.0;

    if (total > 0) {
      int positiveFrames = 0;
      int negativeFrames = 0;
      counts.forEach((emotion, count) {
        if (_positiveEmotions.contains(emotion)) {
          positiveFrames += count;
        }
        if (_negativeEmotions.contains(emotion)) {
          negativeFrames += count;
        }
      });

      positiveRatio = positiveFrames / total;
      negativeRatio = negativeFrames / total;
    }

    final composureScore = _clampPercent(50.0 + ((positiveRatio - negativeRatio) * 45.0));
    return _clampPercent((avgConfidence * 0.5) + (composureScore * 0.3) + (stabilityScore * 0.2));
  }

  double _computeNlpPercent(Map<String, dynamic> nlpScores) {
    final values = <double>[];
    nlpScores.forEach((_, rawValue) {
      final parsed = _asDouble(rawValue);
      if (parsed == null) {
        return;
      }

      final normalized = parsed <= 1.0 ? parsed * 100.0 : parsed;
      values.add(_clampPercent(normalized));
    });

    if (values.isEmpty) {
      return 50.0;
    }

    final sum = values.fold<double>(0.0, (total, value) => total + value);
    return _clampPercent(sum / values.length);
  }

  List<String> _buildEmotionObservations(
    Map<String, dynamic> normalizedEmotion,
    double emotionPercent,
    double nlpPercent,
  ) {
    final observations = <String>[];
    final counts = (normalizedEmotion['emotion_counts'] as Map<String, int>?) ?? <String, int>{};
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final dominantEmotion = (normalizedEmotion['dominant_emotion'] ?? 'unknown').toString();
    final avgConfidence = _clampPercent(_asDouble(normalizedEmotion['average_confidence']) ?? 0.0);
    final volatilityPercent = _clampPercent(_asDouble(normalizedEmotion['volatility_percent']) ?? 0.0);

    if (total > 0 && dominantEmotion != 'unknown') {
      final dominantCount = counts[dominantEmotion] ?? 0;
      final dominantShare = total > 0 ? (dominantCount / total) * 100.0 : 0.0;
      observations.add(
        'Dominant emotion was $dominantEmotion across ${dominantShare.toStringAsFixed(1)}% of captured frames ($dominantCount/$total).',
      );
    }

    observations.add(
      'Average facial confidence from backend tracking was ${avgConfidence.toStringAsFixed(1)}%.',
    );

    observations.add(
      'Emotion volatility was ${volatilityPercent.toStringAsFixed(1)}%, indicating ${_volatilityLabel(volatilityPercent)} emotional stability.',
    );

    observations.add(
      'Emotion-based confidence (${emotionPercent.toStringAsFixed(1)}%) was blended with NLP performance (${nlpPercent.toStringAsFixed(1)}%).',
    );

    return observations.take(4).toList();
  }

  List<String> _buildCoachingTips(Map<String, dynamic> normalizedEmotion) {
    final tips = <String>[];
    final dominantEmotion = (normalizedEmotion['dominant_emotion'] ?? 'unknown').toString();
    final volatilityPercent = _clampPercent(_asDouble(normalizedEmotion['volatility_percent']) ?? 0.0);

    if (_negativeEmotions.contains(dominantEmotion)) {
      tips.add('Practice short breathing resets before each answer to reduce visible tension and improve composure.');
    }

    if (volatilityPercent > 45.0) {
      tips.add('Use a consistent answer structure (problem, approach, result) to stabilize delivery when pressure increases.');
    }

    tips.add('Pause for 1-2 seconds before answering complex questions to sound deliberate and confident.');
    tips.add('Rehearse with timed mock interviews and review recorded sessions to improve non-verbal consistency.');
    tips.add('Keep answers concise and outcome-focused to project confidence even when unsure.');

    return tips.take(5).toList();
  }

  String _labelFromScore(double score) {
    if (score >= 71.0) {
      return 'high';
    }
    if (score >= 41.0) {
      return 'medium';
    }
    return 'low';
  }

  String _normalizeLabel(dynamic rawLabel, double score) {
    final normalized = rawLabel?.toString().trim().toLowerCase() ?? '';
    if (normalized == 'moderate') {
      return 'medium';
    }
    if (normalized == 'low' || normalized == 'medium' || normalized == 'high') {
      return normalized;
    }
    return _labelFromScore(score);
  }

  String _volatilityLabel(double volatilityPercent) {
    if (volatilityPercent <= 25.0) {
      return 'low';
    }
    if (volatilityPercent <= 45.0) {
      return 'medium';
    }
    return 'high';
  }

  double _clampPercent(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    return value.clamp(0.0, 100.0);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  List<dynamic>? _asList(dynamic value) {
    if (value is List<dynamic>) {
      return value;
    }
    if (value is List) {
      return value.cast<dynamic>();
    }
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  List<String> _toStringList(dynamic value) {
    final raw = _asList(value);
    if (raw == null) {
      return <String>[];
    }
    return raw.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
  }

  String _safeJson(Object? value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }
}
