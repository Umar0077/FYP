import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/GlassCard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/profile_controller.dart';

import '../widgets/AppScaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  double _progress = 0.0;
  final ProfileController _profileController = ProfileController();

  String _uploadErrorMessage(Object e) {
    final String raw = e.toString();
    if (raw.contains('upload-failed') || raw.contains('object-not-found')) {
      return 'Upload failed due to Firebase Storage configuration. Please verify the Storage bucket in Firebase project settings.';
    }
    if (raw.contains('unauthorized')) {
      return 'Upload failed due to missing permissions for this account.';
    }
    return 'Upload failed: $e';
  }

  Future<void> _pickAndUpload() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      final file = File(picked.path);

      setState(() {
        _uploading = true;
        _progress = 0.0;
      });

      try {
        await _profileController.uploadAvatar(file, (p) {
          if (mounted) setState(() => _progress = p);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo uploaded')));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_uploadErrorMessage(e))));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_uploadErrorMessage(e))));
      }
    } finally {
      if (mounted)
        setState(() {
          _uploading = false;
          _progress = 0.0;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
    final Color avatarBg = isDark ? const Color(0xFF00002E) : const Color(0xFFE8EBF8);
    final Color nameColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color emailColor = isDark ? Colors.white70 : const Color(0xFF27308A);

    return AppScaffold(
      appBarTitle: 'Profile',
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Center(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                stream: FirebaseAuth.instance.currentUser == null
                    ? const Stream.empty()
                    : FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                builder: (context, snap) {
                  String displayName = 'Tom Hillson';
                  String displayEmail = FirebaseAuth.instance.currentUser?.email ?? 'you@domain.com';
                  String? photoUrl;
                  String? bio;
                  if (snap.hasData && snap.data != null && snap.data!.data() != null) {
                    final data = snap.data!.data();
                    if (data != null) {
                      if (data['name'] is String && (data['name'] as String).isNotEmpty) displayName = data['name'] as String;
                      if (data['email'] is String && (data['email'] as String).isNotEmpty) displayEmail = data['email'] as String;
                      if (data['photoUrl'] is String && (data['photoUrl'] as String).isNotEmpty) {
                        photoUrl = data['photoUrl'] as String;
                      } else if (data['photoURL'] is String && (data['photoURL'] as String).isNotEmpty) {
                        photoUrl = data['photoURL'] as String;
                      }
                      if (data['bio'] is String && (data['bio'] as String).isNotEmpty) bio = data['bio'] as String;
                    }
                  } else {
                    // fallback to auth profile if Firestore not ready
                    final authUser = FirebaseAuth.instance.currentUser;
                    if (authUser != null) {
                      if (authUser.displayName != null && authUser.displayName!.isNotEmpty) displayName = authUser.displayName!;
                      if (authUser.email != null && authUser.email!.isNotEmpty) displayEmail = authUser.email!;
                      if (authUser.photoURL != null && authUser.photoURL!.isNotEmpty) photoUrl = authUser.photoURL;
                    }
                  }
                  return Column(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: avatarBg,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null ? Icon(Icons.person, size: 36, color: isDark ? Colors.white54 : Colors.indigo) : null,
                          ),
                          Positioned(
                            bottom: -6,
                            right: -6,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickAndUpload,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_uploading) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(value: _progress),
                        ),
                      ] else
                        const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(displayName, style: TextStyle(color: nameColor, fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(displayEmail, style: TextStyle(color: emailColor, fontSize: 12)),
                      if (bio != null && bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(bio, style: TextStyle(color: emailColor, fontSize: 12)),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _ListTile(
              icon: Icons.tune,
              title: 'Preferences',
              subtitle: 'Theme, account and more',
              onTap: () => Navigator.of(context).pushNamed('/profile/preferences'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _ListTile(
              icon: Icons.support_agent,
              title: 'Customer Support',
              subtitle: 'Chat with our assistant',
              onTap: () => Navigator.of(context).pushNamed('/profile/support'),
              isDark: isDark,
            ),
            const Spacer(),
            _ListTile(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                // Capture navigator and messenger synchronously to avoid using `context` after async
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                FirebaseAuth.instance.signOut().then((_) {
                  navigator.pushNamedAndRemoveUntil('/login', (Route<dynamic> r) => false);
                }).catchError((e) {
                  messenger.showSnackBar(const SnackBar(content: Text('Logout failed')));
                });
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color subtitleColor = isDark ? Colors.white54 : const Color(0xFF27308A);
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: subtitleColor, fontSize: 12)) : null,
        trailing: Icon(Icons.chevron_right, color: iconColor),
        onTap: onTap,
      ),
    );
  }
}
