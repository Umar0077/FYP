import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../models/admin/admin_mock_models.dart';
import '../widgets/GlassCard.dart';

class AdminInterviewDetailScreen extends StatefulWidget {
  const AdminInterviewDetailScreen({super.key});

  @override
  State<AdminInterviewDetailScreen> createState() => _AdminInterviewDetailScreenState();
}

class _AdminInterviewDetailScreenState extends State<AdminInterviewDetailScreen> {
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
      appBar: AppBar(title: const Text('Interview Session Detail')),
      body: FutureBuilder<MockInterview?>(
        future: _interviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final interview = snapshot.data;
          if (interview == null) {
            return const Center(child: Text('Interview not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
          _section(
            title: 'Interview Summary',
            children: [
              _row('userId', interview.userId),
              _row('difficulty', interview.difficulty),
              _row('status', interview.status),
              _row('questionCount', '${interview.questionCount}'),
              _row('answeredCount', '${interview.answeredCount}'),
              _row('skippedCount', '${interview.skippedCount}'),
              _row('wrongCount', '${interview.wrongCount}'),
              _row('totalCount', '${interview.totalCount}'),
              _row('avgAccuracy', interview.avgAccuracy.toStringAsFixed(1)),
              _row('avgRelevance', interview.avgRelevance.toStringAsFixed(1)),
              _row('startedAt', DateFormat('MMM d, y h:mm a').format(interview.startedAt)),
              _row('endedAt', DateFormat('MMM d, y h:mm a').format(interview.endedAt)),
              _row('updatedAt', DateFormat('MMM d, y h:mm a').format(interview.updatedAt)),
              _row('computedAt', DateFormat('MMM d, y h:mm a').format(interview.computedAt)),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Confidence Analysis',
            children: [
              _row('confidence_label', interview.confidenceAnalysis.confidence_label),
              _row('confidence_level', interview.confidenceAnalysis.confidence_level.toStringAsFixed(1)),
              _row('reasoning', interview.confidenceAnalysis.reasoning),
              _list('coaching_tips', interview.confidenceAnalysis.coaching_tips),
              _list('emotion_based_observations', interview.confidenceAnalysis.emotion_based_observations),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Emotion Report',
            children: [
              _row('average_confidence', interview.emotionReport.average_confidence.toStringAsFixed(1)),
              _row('average_confidence_overall', interview.emotionReport.summary.average_confidence_overall.toStringAsFixed(1)),
              _row('session_quality', interview.emotionReport.summary.session_quality),
              _row('total_duration_seconds', interview.emotionReport.summary.total_duration_seconds.toStringAsFixed(0)),
              _row('total_frames_processed', '${interview.emotionReport.summary.total_frames_processed}'),
              _row('unique_emotions_detected', '${interview.emotionReport.summary.unique_emotions_detected}'),
              _list('dominant_emotions', interview.emotionReport.summary.dominant_emotions),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/admin/interviews/results', arguments: interview.id),
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Results Review'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/admin/emotion_tracking', arguments: interview),
                  icon: const Icon(Icons.psychology),
                  label: const Text('Emotion Report'),
                ),
              ),
            ],
          ),
            ],
          );
        },
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _list(String key, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: values.map((v) => Text('• $v', style: const TextStyle(fontSize: 12))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
