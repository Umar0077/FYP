import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/GlassCard.dart';
import '../widgets/AppScaffold.dart';
import '../../services/streak_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final dashboardController = Get.find<DashboardController>();
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
    final Color primaryTextColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
    // Glass effect colors
    final Color glassBg = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.45);

    Widget primaryButton(String label, VoidCallback onPressed) => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : const Color(0xFF00002E),
              foregroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
              shadowColor: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.12),
            ),
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        );

    final bottomSpacing = MediaQuery.of(context).padding.bottom + 20.0;
    final minHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 56;

    return AppScaffold(
      backgroundColor: backgroundColor,
      showAppBar: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420, minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 8),

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome text with GetX reactive userName
                            Obx(() => Text(
                              'Welcome Back ${authController.userName}!',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            )),
                            const SizedBox(height: 8),
                            Text(
                              'Confidence comes from preparation.',
                              style: TextStyle(color: secondaryTextColor, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      // Avatar with subtle shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.35 : 0.08), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: CircleAvatar(radius: 28, backgroundColor: glassBg, child: const Icon(Icons.person, color: Colors.white, size: 22)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Progress Summary Card (bigger) - Now with GetX reactive data
                  Obx(() {
                    final hasData = dashboardController.hasData;
                    final successRate = dashboardController.successRate / 100.0;
                    
                    return GlassCard(
                      child: hasData
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Stack(alignment: Alignment.center, children: [
                                    SizedBox(
                                      width: 104,
                                      height: 104,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: successRate),
                                        duration: const Duration(milliseconds: 1500),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return CircularProgressIndicator(
                                            value: value,
                                            strokeWidth: 10,
                                            valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF3A45C3) : const Color(0xFF2D3DF0)),
                                            backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                          );
                                        },
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${dashboardController.successRate.round()}%', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w800, fontSize: 18)),
                                        Text('Success', style: TextStyle(color: secondaryTextColor))
                                      ],
                                    )
                                  ]),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    _statRow('Interviews Completed', '${dashboardController.interviewsCompleted}', primaryTextColor, secondaryTextColor),
                                    const SizedBox(height: 12),
                                    _statRow('Average Score', '${dashboardController.averageScore}', primaryTextColor, secondaryTextColor),
                                    const SizedBox(height: 12),
                                    _statRowWithBar('Skill Improvement', dashboardController.skillImprovement, primaryTextColor, secondaryTextColor, isDark),
                                  ]),
                                ),
                              ],
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.analytics_outlined, size: 48, color: secondaryTextColor),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Interview Data Yet',
                                      style: TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Complete your first interview to see your stats',
                                      style: TextStyle(color: secondaryTextColor, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text('Quick Actions', style: TextStyle(color: primaryTextColor, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      Expanded(child: primaryButton('Start New Interview', () => Get.toNamed('/interview_prep'))),
                      const SizedBox(width: 12),
                      Expanded(child: primaryButton('View Past Sessions', () => Get.toNamed('/recent_tab'))),
                    ]),
                  ),

                  const SizedBox(height: 18),

                  // Streak Tracker Card
                  StreamBuilder<StreakData>(
                    stream: StreakService.getStreakStream(),
                    builder: (context, snapshot) {
                      final streakData = snapshot.data ?? StreakData(currentStreak: 0, longestStreak: 0, lastPracticeDate: null);
                      final currentStreak = streakData.currentStreak;
                      final milestone = 7; // 7-day milestone
                      final progress = (currentStreak % milestone) / milestone;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Get.toNamed('/streaks'),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text('${currentStreak}-Day Practice Streak',
                                          style: TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w800)),
                                    ),
                                    const SizedBox(height: 6),
                                    Center(child: Text(currentStreak == 0 ? 'Start your streak today!' : 'Keep your streak alive!', 
                                                      style: TextStyle(color: secondaryTextColor, fontSize: 13))),
                                    const SizedBox(height: 10),
                                    // Progress bar toward milestone
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF3A45C3) : const Color(0xFF2D3DF0)),
                                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Flame icon on the right
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF3A45C3) : const Color(0xFF2D3DF0), borderRadius: BorderRadius.circular(12)),
                                child: const Center(child: Icon(Icons.local_fire_department, color: Colors.white, size: 22)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Fill remaining space and keep bottom spacing
                  const SizedBox(height: 20),
                  SizedBox(height: bottomSpacing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color primary, Color secondary) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(label, style: TextStyle(color: secondary, fontSize: 13))), Text(value, style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 16))]);
  }

  Widget _statRowWithBar(String label, double progress, Color primary, Color secondary, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: secondary, fontSize: 13)), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 10, valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF3A45C3) : const Color(0xFF2D3DF0)), backgroundColor: isDark ? Colors.white12 : Colors.black12))]);
  }

}
