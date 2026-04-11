import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../models/admin/admin_mock_models.dart';
import '../widgets/GlassCard.dart';

class AdminInterviewManagementScreen extends StatelessWidget {
  const AdminInterviewManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(
        title: const Text('Interview Sessions'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => controller.interviewSearchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search by userId or difficulty',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E3F) : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedInterviewStatus.value,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedInterviewStatus.value = value;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedInterviewDifficulty.value,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Difficulty')),
                        DropdownMenuItem(value: 'easy', child: Text('Easy')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedInterviewDifficulty.value = value;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              final interviews = controller.filteredInterviews;
              if (interviews.isEmpty) {
                return const Center(child: Text('No interview sessions found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: interviews.length,
                itemBuilder: (context, index) {
                  final MockInterview interview = interviews[index];
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Get.toNamed('/admin/interviews/detail', arguments: interview);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    interview.id,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _StatusBadge(status: interview.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'userId: ${interview.userId} • difficulty: ${interview.difficulty}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF27308A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetricChip(label: 'answeredCount', value: '${interview.answeredCount}'),
                                _MetricChip(label: 'skippedCount', value: '${interview.skippedCount}'),
                                _MetricChip(label: 'wrongCount', value: '${interview.wrongCount}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'avgAccuracy: ${interview.avgAccuracy.toStringAsFixed(1)}% • avgRelevance: ${interview.avgRelevance.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(interview.startedAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final Color color = lower == 'completed'
        ? Colors.green
        : lower == 'in_progress'
            ? Colors.orange
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11)),
    );
  }
}
