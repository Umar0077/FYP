import 'package:flutter/material.dart';
import '../widgets/AppScaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/profile_controller.dart';
import '../widgets/GlassCard.dart';

class PreferenceScreen extends StatelessWidget {
  const PreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF050A30) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF131964) : const Color(0xFFF2F4FF);
    final Color borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
    final Color iconColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color subtitleColor = isDark ? Colors.white54 : const Color(0xFF27308A);

    return AppScaffold(
      appBarTitle: 'Preference',
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),
            AccountInfoCard(),
            const SizedBox(height: 16),
            _Item(
              icon: Icons.lock_outline,
              title: 'Password',
              subtitle: 'Change your Password',
              onTap: () => Navigator.of(context).pushNamed('/forgot'),
              iconColor: iconColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              cardColor: cardColor,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class AccountInfoCard extends StatefulWidget {
  const AccountInfoCard({Key? key}) : super(key: key);

  @override
  State<AccountInfoCard> createState() => _AccountInfoCardState();
}

class _AccountInfoCardState extends State<AccountInfoCard> {
  final ProfileController _profileController = ProfileController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  bool _loading = false;

  void _showEditDialog(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _dobController.text = data['dob'] ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Account Information'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: _dobController, decoration: const InputDecoration(labelText: 'Date of Birth')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                try {
                  await _profileController.updateUserInfo(
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    bio: 'Phone: ${_phoneController.text.trim()}, DOB: ${_dobController.text.trim()}',
                  );
                  if (mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: _loading ? const CircularProgressIndicator() : const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: uid.isEmpty ? null : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Information', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Name: ${data['name'] ?? ''}'),
              Text('Email: ${data['email'] ?? ''}'),
              Text('Phone: ${data['phone'] ?? ''}'),
              Text('Date of Birth: ${data['dob'] ?? ''}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _showEditDialog(data),
                  child: const Text('Edit Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    required this.iconColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.cardColor,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: iconColor),
        onTap: onTap,
      ),
    );
  }
}