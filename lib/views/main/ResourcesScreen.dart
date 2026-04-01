import 'package:flutter/material.dart';
import '../widgets/GlassCard.dart';
import '../widgets/AppScaffold.dart';
import '../ui/ui_colors.dart';
import '../../models/interview_course.dart';
import '../course/CourseWebViewScreen.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;

    return AppScaffold(
      appBarTitle: 'Resources',
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            Text('Level Up Your Interview Skills', style: TextStyle(color: secondaryTextColor(context), fontSize: 12)),
            const SizedBox(height: 20),
            
            // Interview Training Courses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Interview Training Courses', style: TextStyle(color: foregroundOnBackground(context), fontSize: 18, fontWeight: FontWeight.w600)),
                Text('View All', style: TextStyle(color: secondaryTextColor(context).withOpacity(0.8), fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Course cards with proper height
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: interviewCourses.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 16),
                        child: _CourseCard(course: interviewCourses[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final InterviewCourse course;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color buttonColor = isDark ? Colors.white : const Color(0xFF00002E);
    final Color buttonTextColor = isDark ? const Color(0xFF00002E) : Colors.white;
    return SizedBox(
      width: 180,
      child: GlassCard(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Course image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  course.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Image loading error for ${course.courseTitle}: $error');
                    debugPrint('Failed URL: ${course.imageUrl}');
                    return Container(
                      color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFf0f0f0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 30,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Failed to load',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      debugPrint('Image loaded successfully for ${course.courseTitle}');
                      return child;
                    }
                    return Container(
                      color: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFf0f0f0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.white54 : Colors.grey[600]!,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Course title
                  SizedBox(
                    height: 36,
                    child: Text(
                      course.courseTitle,
                      style: TextStyle(
                        color: foregroundOnBackground(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Open course button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CourseWebViewScreen(
                              courseTitle: course.courseTitle,
                              courseUrl: course.courseLink,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: buttonTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'View Course',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
