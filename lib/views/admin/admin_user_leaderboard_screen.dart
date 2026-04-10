import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/admin/admin_controller.dart';
import '../widgets/AppScaffold.dart';
import '../widgets/GlassCard.dart';

class AdminUserLeaderboardScreen extends StatelessWidget {
  const AdminUserLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return AppScaffold(
      appBarTitle: 'User Leaderboard',
      body: Obx(() {
        if (controller.isLoading.value && controller.userPerformanceLeaderboard.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final leaderboard = controller.userPerformanceLeaderboard;
        if (leaderboard.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 52),
                  const SizedBox(height: 12),
                  const Text(
                    'No user performance data available yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: controller.loadDashboardData,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadDashboardData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaderboard.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      'Ranked by highest success rate. Tie-breakers: more interviews, then higher average accuracy.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }

              final rank = index;
              final item = leaderboard[index - 1];
              final hasInterview = item.totalInterviews > 0;
              final lastInterview = item.lastInterviewAt.millisecondsSinceEpoch > 0
                  ? DateFormat('MMM d, y').format(item.lastInterviewAt)
                  : 'N/A';

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: _RankBadge(rank: rank),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        item.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetricChip(
                            label: 'Success',
                            value: '${item.successRate.toStringAsFixed(1)}%',
                            color: Colors.green,
                          ),
                          _MetricChip(
                            label: 'Accuracy',
                            value: '${item.averageAccuracy.toStringAsFixed(1)}%',
                            color: Colors.blue,
                          ),
                          _MetricChip(
                            label: 'Interviews',
                            value: '${item.totalInterviews}',
                            color: Colors.purple,
                          ),
                          _MetricChip(
                            label: 'Correct',
                            value: '${item.totalCorrect}',
                            color: Colors.teal,
                          ),
                          _MetricChip(
                            label: 'Wrong',
                            value: '${item.totalWrong}',
                            color: Colors.red,
                          ),
                          _MetricChip(
                            label: 'Skipped',
                            value: '${item.totalSkipped}',
                            color: Colors.orange,
                          ),
                          _MetricChip(
                            label: 'Streak',
                            value: '${item.currentStreak}',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasInterview ? 'Last interview: $lastInterview' : 'No completed interview yet',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed('/admin/users/detail', arguments: item.userId),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (rank == 1) {
      color = const Color(0xFFFFC107);
    } else if (rank == 2) {
      color = const Color(0xFFB0BEC5);
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32);
    } else {
      color = Theme.of(context).colorScheme.primary;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        '$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
