import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../widgets/AppScaffold.dart';
import '../widgets/GlassCard.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return AppScaffold(
      showAppBar: true,
      appBarTitle: 'Admin Dashboard',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadDashboardData();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.errorState.value.isNotEmpty) ...[
                GlassCard(
                  child: Text(
                    controller.errorState.value,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildSectionTitle('Overview'),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SummaryCard(
                    title: 'Total Users',
                    value: controller.totalUsers.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    title: 'Completed Interviews',
                    value: controller.completedInterviews.toString(),
                    icon: Icons.video_call,
                    color: Colors.green,
                  ),
                  _SummaryCard(
                    title: 'Avg. Accuracy',
                    value: '${controller.averageAccuracy.toStringAsFixed(1)}%',
                    icon: Icons.check_circle,
                    color: Colors.orange,
                  ),
                  _SummaryCard(
                    title: 'Avg. Confidence',
                    value: '${controller.averageConfidence.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Interview Summary'),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total interviews: ${controller.totalInterviews}'),
                    const SizedBox(height: 6),
                    Text('Avg. relevance: ${controller.averageRelevance.toStringAsFixed(1)}%'),
                    const SizedBox(height: 6),
                    Text('answeredCount total: ${controller.answeredCountTotal}'),
                    Text('skippedCount total: ${controller.skippedCountTotal}'),
                    Text('wrongCount total: ${controller.wrongCountTotal}'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Difficulty Distribution'),
              const SizedBox(height: 12),
              GlassCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.difficultyDistribution.entries
                      .map(
                        (entry) => Chip(
                          label: Text('${entry.key}: ${entry.value}'),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Session Quality Distribution'),
              const SizedBox(height: 12),
              GlassCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.sessionQualityDistribution.entries
                      .map(
                        (entry) => Chip(
                          label: Text('${entry.key}: ${entry.value}'),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Recent Users'),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: controller.users
                      .take(5)
                      .map(
                        (u) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(u.name),
                          subtitle: Text(u.email),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Recent Interview Activity'),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: controller.interviews
                      .take(5)
                      .map(
                        (i) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(i.id),
                          subtitle: Text('${i.userId} • ${i.status} • ${i.difficulty}'),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Management'),
              const SizedBox(height: 16),
              _ActionTile(
                title: 'User Management',
                subtitle: 'Manage users, streaks, and activity',
                icon: Icons.manage_accounts,
                route: '/admin/users',
              ),
              _ActionTile(
                title: 'Interview Sessions',
                subtitle: 'Review all recorded interviews and stats',
                icon: Icons.assessment,
                route: '/admin/interviews',
              ),
              _ActionTile(
                title: 'Analytics & Insights',
                subtitle: 'View system health and growth',
                icon: Icons.analytics,
                route: '/admin/analytics',
              ),
              _ActionTile(
                title: 'Resources',
                subtitle: 'Update learning resources and tips',
                icon: Icons.library_books,
                route: '/admin/resources',
              ),
              _ActionTile(
                title: 'Job Suggestions',
                subtitle: 'Manage job board entries',
                icon: Icons.work,
                route: '/admin/jobs',
              ),
              _ActionTile(
                title: 'Support Tickets',
                subtitle: 'View and reply to user support requests',
                icon: Icons.support_agent,
                route: '/admin/support',
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isDark ? color.withValues(alpha: 0.8) : color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF0A0F2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.white12 : Colors.blue.withValues(alpha: 0.1),
          child: Icon(icon, color: isDark ? Colors.white70 : Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF27308A),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Get.toNamed(route),
      ),
    );
  }
}
