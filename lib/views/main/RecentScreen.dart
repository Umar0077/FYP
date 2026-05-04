import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/AppScaffold.dart';
import '../ui/ui_colors.dart';
import '../../controllers/recent_interviews_controller.dart';
import 'InterviewResultScreen.dart';
import 'package:intl/intl.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecentInterviewsController>();
    
    return AppScaffold(
      appBarTitle: 'Recent',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                // Loading state
                if (controller.isLoading.value && controller.sessions.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A45C3)
                            : const Color(0xFF2D3DF0),
                      ),
                    ),
                  );
                }

                // Error state
                if (controller.errorMessage.value.isNotEmpty && controller.sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: secondaryTextColor(context)),
                        const SizedBox(height: 12),
                        Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: foregroundOnBackground(context), fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => controller.onInit(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Empty state
                if (controller.sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 64, color: secondaryTextColor(context)),
                        const SizedBox(height: 16),
                        Text(
                          'No Recent Interviews',
                          style: TextStyle(
                            color: foregroundOnBackground(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your first interview to see it here',
                          style: TextStyle(color: secondaryTextColor(context), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Data loaded - show list
                return ListView.separated(
                  itemCount: controller.sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int i) {
                    final session = controller.sessions[i];
                    return _RecentTile(
                      title: session.title,
                      dateTime: session.dateTime,
                      score: session.score,
                      onTap: () {
                        Get.to(
                          () => InterviewResultScreen(interviewId: session.id),
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.title,
    required this.dateTime,
    required this.score,
    required this.onTap,
  });
  
  final String title;
  final DateTime dateTime;
  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Format date and time
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final formattedDate = dateFormat.format(dateTime);
    final formattedTime = timeFormat.format(dateTime);

    return Container(
      decoration: filledBoxDecoration(context).copyWith(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            color: foregroundOnBackground(context),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$formattedDate • $formattedTime',
            style: TextStyle(
              color: secondaryTextColor(context),
              fontSize: 12,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(score, context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: foregroundOnBackground(context)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getScoreColor(int score, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (score >= 80) {
      return isDark ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50);
    } else if (score >= 70) {
      return isDark ? const Color(0xFF1976D2) : const Color(0xFF2196F3);
    } else if (score >= 50) {
      return isDark ? const Color(0xFFF57C00) : const Color(0xFFFF9800);
    } else {
      return isDark ? const Color(0xFFC62828) : const Color(0xFFF44336);
    }
  }
}
