import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../models/admin/admin_mock_models.dart';
import '../widgets/GlassCard.dart';

class AdminEmotionTrackingScreen extends StatefulWidget {
  const AdminEmotionTrackingScreen({super.key});

  @override
  State<AdminEmotionTrackingScreen> createState() => _AdminEmotionTrackingScreenState();
}

class _AdminEmotionTrackingScreenState extends State<AdminEmotionTrackingScreen> {
  late final AdminController _controller;
  late Future<MockInterview?> _interviewFuture;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminController>();
    final args = Get.arguments;
    if (args is MockInterview) {
      _interviewFuture = Future<MockInterview?>.value(args);
    } else if (args is String) {
      _interviewFuture = _controller.getInterview(args);
    } else {
      _interviewFuture = Future<MockInterview?>.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('Emotion Report')),
      body: FutureBuilder<MockInterview?>(
        future: _interviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final interview = snapshot.data;
          if (interview == null) {
            return const Center(child: Text('Emotion data unavailable.'));
          }

          final analysis = interview.confidenceAnalysis;
          final report = interview.emotionReport;
          final summary = report.summary;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Confidence Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('confidence_label: ${analysis.confidence_label}'),
                Text('confidence_level: ${analysis.confidence_level.toStringAsFixed(1)}'),
                Text('reasoning: ${analysis.reasoning}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('emotion_summary_used', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('dominant_emotion: ${analysis.emotion_summary_used.dominant_emotion}'),
                Text('average_confidence: ${analysis.emotion_summary_used.average_confidence.toStringAsFixed(1)}'),
                Text('volatility_assessment: ${analysis.emotion_summary_used.volatility_assessment}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('emotionReport.summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('average_confidence_overall: ${summary.average_confidence_overall.toStringAsFixed(1)}'),
                Text('session_quality: ${summary.session_quality}'),
                Text('total_duration_seconds: ${summary.total_duration_seconds.toStringAsFixed(0)}'),
                Text('total_frames_processed: ${summary.total_frames_processed}'),
                Text('unique_emotions_detected: ${summary.unique_emotions_detected}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: summary.dominant_emotions.map((e) => Chip(label: Text(e))).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('emotion_counts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...report.emotion_counts.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${entry.value}'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}
