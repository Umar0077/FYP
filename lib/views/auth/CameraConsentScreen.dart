import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';

class CameraConsentScreen extends StatefulWidget {
  const CameraConsentScreen({super.key});

  @override
  State<CameraConsentScreen> createState() => _CameraConsentScreenState();
}

class _CameraConsentScreenState extends State<CameraConsentScreen> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _continue() async {
    if (!_accepted || _saving) return;

    setState(() => _saving = true);
    final AuthController authController = Get.find<AuthController>();

    try {
      await authController.acceptCameraConsent();
      if (!mounted) return;
      Get.offAllNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save consent: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _declineAndLogout() async {
    if (_saving) return;
    setState(() => _saving = true);

    final AuthController authController = Get.find<AuthController>();
    await authController.logout();

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
    final Color borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
    final Color headingColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color bodyColor = isDark ? Colors.white70 : const Color(0xFF27308A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Camera & Facial Emotion Consent',
                      style: TextStyle(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This app uses your camera during interview sessions to detect facial emotions. '
                      'Your facial emotions may be captured and processed to generate interview feedback and confidence insights.',
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'By accepting, you confirm that you understand and allow this behavior.',
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: _saving
                          ? null
                          : (value) {
                              setState(() => _accepted = value ?? false);
                            },
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF27308A),
                      checkColor: Colors.white,
                      title: Text(
                        'I accept',
                        style: TextStyle(color: headingColor, fontWeight: FontWeight.w700),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_accepted && !_saving) ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: isDark ? Colors.white : const Color(0xFF00002E),
                          foregroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(_saving ? 'Saving...' : 'Continue'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _saving ? null : _declineAndLogout,
                        child: Text(
                          'Decline and Logout',
                          style: TextStyle(color: bodyColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
