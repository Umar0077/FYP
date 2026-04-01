import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../widgets/GlassCard.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('Analytics')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ChartCard(
              title: 'User Growth',
              icon: Icons.show_chart,
              subtitle: 'Total users: ${controller.totalUsers}',
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Interview Completion',
              icon: Icons.analytics,
              subtitle:
                  'Completed: ${controller.completedInterviews} / ${controller.totalInterviews}',
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Average Accuracy',
              icon: Icons.check_circle,
              subtitle: '${controller.averageAccuracy.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Average Relevance',
              icon: Icons.track_changes,
              subtitle: '${controller.averageRelevance.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Average Confidence',
              icon: Icons.trending_up,
              subtitle: '${controller.averageConfidence.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Difficulty Distribution',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.difficultyDistribution.entries
                        .map((entry) => Chip(label: Text('${entry.key}: ${entry.value}')))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session Quality Distribution',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.sessionQualityDistribution.entries
                        .map((entry) => Chip(label: Text('${entry.key}: ${entry.value}')))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;

  const _ChartCard({required this.title, required this.icon, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      child: SizedBox(
        height: 140,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0A0F2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF27308A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
