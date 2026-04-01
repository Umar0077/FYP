import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/admin_controller.dart';
import '../../models/admin/admin_mock_models.dart';
import '../widgets/GlassCard.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late final AdminController _controller;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AdminController>();
    final args = Get.arguments;
    if (args is String) {
      _userId = args;
    } else if (args is MockUser) {
      _userId = args.id;
    }
    if (_userId.isNotEmpty) {
      _controller.loadUserInterviews(_userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MockUser user = _controller.users.firstWhereOrNull((u) => u.id == _userId) ??
      MockUser(
          id: '',
          bio: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          currentStreak: 0,
          dob: '',
          dob_iso: '',
          email: '',
          lastPracticeDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
          longestStreak: 0,
          name: 'Unknown User',
          phone: '',
          practiceDates: <String>[],
        );
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('User Practice Stats')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    child: Text(user.name.isNotEmpty ? user.name[0] : 'U'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(user.email),
                        Text(user.phone),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('bio: ${user.bio}'),
                  Text('dob: ${user.dob}'),
                  Text('dob_iso: ${user.dob_iso}'),
                  Text(
                      'createdAt: ${DateFormat('MMM d, y').format(user.createdAt)}'),
                  Text(
                      'lastUpdated: ${DateFormat('MMM d, y').format(user.lastUpdated)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Practice Stats',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('currentStreak: ${user.currentStreak}'),
                  Text('longestStreak: ${user.longestStreak}'),
                  Text(
                      'lastPracticeDate: ${DateFormat('MMM d, y').format(user.lastPracticeDate)}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: user.practiceDates
                        .map((d) => Chip(label: Text(d.split('T').first)))
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
                  const Text('Recent Interviews',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_controller.userInterviews.isEmpty)
                    const Text('No interview sessions found for this user.')
                  else
                    ..._controller.userInterviews.map(
                      (i) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(i.id),
                        subtitle: Text(
                            '${i.status} • ${i.difficulty} • avgAccuracy ${i.avgAccuracy.toStringAsFixed(1)}'),
                        onTap: () =>
                            Get.toNamed('/admin/interviews/detail', arguments: i),
                      ),
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
