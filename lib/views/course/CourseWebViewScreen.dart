import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/AppScaffold.dart';

class CourseWebViewScreen extends StatelessWidget {
  final String courseTitle;
  final String courseUrl;

  const CourseWebViewScreen({
    super.key,
    required this.courseTitle,
    required this.courseUrl,
  });

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(courseUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $courseUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF7C86B2);
    final Color buttonColor = isDark ? Colors.white : const Color(0xFF00002E);
    final Color buttonTextColor = isDark ? const Color(0xFF00002E) : Colors.white;

    return AppScaffold(
      appBarTitle: courseTitle,
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: secondaryTextColor,
            ),
            const SizedBox(height: 24),
            Text(
              courseTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This course will open in your default browser where you can access all the learning materials.',
              style: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _launchUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Open Course',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Go Back',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}