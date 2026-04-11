import 'dart:convert';
import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service for analyzing confidence level using Gemini based on emotion data
class GeminiConfidenceAnalyzer {
  static const String _apiKey = 'AIzaSyAZT4J3ByOFJggpa-9GwvADivxQpvE5lv8';
  
  // List of models to try (fallback chain) - updated with valid models
  static const List<String> _modelNames = [
    'models/gemini-2.5-flash-lite',
    'models/gemini-2.5-flash',
    'models/gemini-1.5-flash',
    'models/gemini-pro',
  ];

  GenerativeModel? _model;
  String? _selectedModelId;
  
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
    try {
      developer.log(
        'Starting confidence analysis',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );
      
      // Get model with fallback
      final model = await _getModel();
      if (model == null) {
        developer.log(
          'No Gemini model available, returning fallback',
          name: 'GeminiAnalyzer.analyzeConfidence',
          level: 1000,
        );
        return _getFallbackAnalysis(nlpScores, emotionReport);
      }
      
      // Extract key metrics from emotion report
      final emotionSummary = _extractEmotionSummary(emotionReport);
      final timelineHighlights = _extractTimelineHighlights(emotionReport);
      
      // Build prompt
      final prompt = _buildPrompt(
        interviewSummary: interviewSummary,
        nlpScores: nlpScores,
        emotionSummary: emotionSummary,
        timelineHighlights: timelineHighlights,
      );

      developer.log(
        'Sending request to Gemini',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      if (text.isEmpty) {
        developer.log(
          'Empty response from Gemini',
          name: 'GeminiAnalyzer.analyzeConfidence',
          level: 900,
        );
        return _getFallbackAnalysis(nlpScores, emotionReport);
      }
      
      developer.log(
        'Parsing Gemini response',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );

      // Parse JSON response
      final result = json.decode(text) as Map<String, dynamic>;
      
      // Validate required fields
      if (!result.containsKey('confidence_level') || 
          !result.containsKey('confidence_label') ||
          !result.containsKey('reasoning')) {
        developer.log(
          'Invalid response structure',
          name: 'GeminiAnalyzer.analyzeConfidence',
          level: 900,
        );
        return _getFallbackAnalysis(nlpScores, emotionReport);
      }
      
      developer.log(
        'Confidence analysis successful',
        name: 'GeminiAnalyzer.analyzeConfidence',
      );
      return result;
    } catch (e) {
      developer.log(
        'Confidence analysis error: $e',
        name: 'GeminiAnalyzer.analyzeConfidence',
        error: e,
        level: 1000,
      );
      return _getFallbackAnalysis(nlpScores, emotionReport);
    }
  }
  
  /// Generate fallback analysis when Gemini is unavailable
  Map<String, dynamic> _getFallbackAnalysis(
    Map<String, dynamic> nlpScores,
    Map<String, dynamic> emotionReport,
  ) {
    // Calculate simple average from NLP scores
    double avgScore = 0.0;
    if (nlpScores.isNotEmpty) {
      final sum = nlpScores.values.fold<double>(
        0.0,
        (prev, val) => prev + (val is num ? val.toDouble() : 0.0),
      );
      avgScore = sum / nlpScores.length;
    }
    
    // Determine label
    String label;
    if (avgScore >= 0.8) {
      label = 'High';
    } else if (avgScore >= 0.6) {
      label = 'Moderate';
    } else {
      label = 'Low';
    }
    
    return {
      'confidence_level': avgScore,
      'confidence_label': label,
      'reasoning': 'Analysis based on NLP scores (Gemini unavailable)',
      'observations': ['Fallback analysis mode'],
      'coaching_tips': ['Continue practicing to improve performance'],
    };
  }

  /// Extract concise summary metrics from emotion report
  Map<String, dynamic> _extractEmotionSummary(Map<String, dynamic> report) {
    final summary = <String, dynamic>{};
    
    // Emotion counts
    if (report.containsKey('emotion_counts')) {
      summary['emotion_counts'] = report['emotion_counts'];
    }
    
    // Average confidence per emotion
    if (report.containsKey('average_confidence')) {
      summary['average_confidence'] = report['average_confidence'];
    }
    
    // Overall summary from backend
    if (report.containsKey('summary')) {
      final backendSummary = report['summary'] as Map<String, dynamic>;
      summary['dominant_emotions'] = backendSummary['dominant_emotions'] ?? [];
      summary['average_confidence_overall'] = backendSummary['average_confidence_overall'] ?? 0.0;
      summary['total_frames'] = backendSummary['total_frames'] ?? 0;
    }
    
    return summary;
  }

  /// Extract timeline highlights for Gemini analysis
  List<String> _extractTimelineHighlights(Map<String, dynamic> report) {
    final highlights = <String>[];
    
    if (!report.containsKey('timeline') || report['timeline'] == null) {
      return highlights;
    }
    
    final timeline = report['timeline'] as List<dynamic>;
    if (timeline.isEmpty) {
      return highlights;
    }
    
    // Find streaks of same emotion
    String? currentEmotion;
    int streakLength = 0;
    int maxStreakLength = 0;
    String? maxStreakEmotion;
    
    for (final entry in timeline) {
      final emotion = entry['emotion'] as String?;
      
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
    
    if (timeline.length > 0) {
      final volatility = (transitionCount / timeline.length * 100).toStringAsFixed(1);
      highlights.add('Emotion volatility: $volatility% (${transitionCount} transitions in ${timeline.length} frames)');
    }
    
    // Count spikes of specific emotions (fear, surprise)
    final emotionCounts = <String, int>{};
    for (final entry in timeline) {
      final emotion = entry['emotion'] as String?;
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
      final counts = summary['emotion_counts'] as Map<String, dynamic>;
      counts.forEach((emotion, count) {
        buffer.writeln('  - $emotion: $count frames');
      });
    }
    
    if (summary.containsKey('average_confidence')) {
      buffer.writeln('\nAverage Confidence per Emotion:');
      final avgConf = summary['average_confidence'] as Map<String, dynamic>;
      avgConf.forEach((emotion, conf) {
        buffer.writeln('  - $emotion: ${(conf as double).toStringAsFixed(2)}');
      });
    }
    
    if (summary.containsKey('dominant_emotions')) {
      final dominant = (summary['dominant_emotions'] as List).join(', ');
      buffer.writeln('\nDominant Emotions: $dominant');
    }
    
    if (summary.containsKey('average_confidence_overall')) {
      final avgOverall = summary['average_confidence_overall'];
      buffer.writeln('Overall Average Confidence: ${avgOverall.toStringAsFixed(2)}');
    }
    
    if (summary.containsKey('total_frames')) {
      buffer.writeln('Total Frames Analyzed: ${summary['total_frames']}');
    }
    
    return buffer.toString();
  }
}
