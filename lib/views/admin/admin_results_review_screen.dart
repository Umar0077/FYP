import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../models/admin/admin_mock_models.dart';
import '../widgets/GlassCard.dart';

class AdminResultsReviewScreen extends StatefulWidget {
  const AdminResultsReviewScreen({super.key});

  @override
  State<AdminResultsReviewScreen> createState() => _AdminResultsReviewScreenState();
}

class _AdminResultsReviewScreenState extends State<AdminResultsReviewScreen> {
  late final AdminController _controller;
  String _interviewId = 'unknown';

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminController>();
    final args = Get.arguments;
    if (args is String) {
      _interviewId = args;
      _controller.loadAttemptsForInterview(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: Text('Results Review • $_interviewId')),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.attempts.isEmpty) {
          return const Center(child: Text('No attempts found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.attempts.length,
          itemBuilder: (context, index) {
            final MockAttempt a = _controller.attempts[index];
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('questionText: ${a.questionText}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('userAnswer: ${a.userAnswer}'),
                  Text('correctAnswer: ${a.correctAnswer}'),
                  const SizedBox(height: 8),
                  Text('accuracyScore: ${a.accuracyScore.toStringAsFixed(1)}'),
                  Text('relevanceScore: ${a.relevanceScore.toStringAsFixed(1)}'),
                  Text('geminiAccuracy: ${a.geminiAccuracy.toStringAsFixed(1)}'),
                  Text('geminiRelevance: ${a.geminiRelevance.toStringAsFixed(1)}'),
                  Text('embeddingSimilarity: ${a.embeddingSimilarity.toStringAsFixed(2)}'),
                  Text('status: ${a.status}'),
                  Text('createdAt: ${a.createdAt.toIso8601String()}'),
                  const SizedBox(height: 8),
                  Text('feedback: ${a.feedback}'),
                  if (a.missingPoints.isNotEmpty)
                    Text('missingPoints: ${a.missingPoints.join(', ')}'),
                  if (a.wrongClaims.isNotEmpty)
                    Text('wrongClaims: ${a.wrongClaims.join(', ')}'),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
