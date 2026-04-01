import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart';
import '../widgets/AppScaffold.dart';

class EditInformationScreen extends StatefulWidget {
	const EditInformationScreen({super.key});

	@override
	State<EditInformationScreen> createState() => _EditInformationScreenState();
}

class _EditInformationScreenState extends State<EditInformationScreen> {
		final ProfileController _profileController = ProfileController();
	final TextEditingController _nameController = TextEditingController(text: 'Lois Becket');
	final TextEditingController _emailController = TextEditingController(text: 'loisbecket@gmail.com');
	final TextEditingController _dobController = TextEditingController(text: '18/03/2024');
	final TextEditingController _phoneController = TextEditingController(text: '(454) 726-0592');

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_dobController.dispose();
		_phoneController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return AppScaffold(
			appBarTitle: 'Edit Information',
			body: SingleChildScrollView(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>[
							const SizedBox(height: 8),
							Center(
								child: Column(
									children: <Widget>[
										CircleAvatar(
											radius: 42,
											backgroundColor: const Color(0xFF131964),
											child: const Icon(Icons.android, color: Colors.white, size: 36),
										),
										const SizedBox(height: 8),
										const Text('Change', style: TextStyle(color: Colors.white54, fontSize: 12)),
									],
								),
							),
							const SizedBox(height: 16),
							const Text('Full Name', style: TextStyle(color: Colors.white54, fontSize: 12)),
							const SizedBox(height: 6),
							_FilledField(
								child: TextField(
									controller: _nameController,
									style: const TextStyle(color: Colors.white),
									decoration: const InputDecoration.collapsed(
										hintText: 'Full name',
										hintStyle: TextStyle(color: Colors.white38),
									),
								),
							),
							const SizedBox(height: 12),
							const Text('Email', style: TextStyle(color: Colors.white54, fontSize: 12)),
							const SizedBox(height: 6),
							_FilledField(
								child: TextField(
									controller: _emailController,
									style: const TextStyle(color: Colors.white),
									decoration: const InputDecoration.collapsed(
										hintText: 'Email',
										hintStyle: TextStyle(color: Colors.white38),
									),
								),
							),
							const SizedBox(height: 12),
							const Text('Birth of date', style: TextStyle(color: Colors.white54, fontSize: 12)),
							const SizedBox(height: 6),
							_FilledField(
								child: Row(
									children: <Widget>[
										Expanded(
											child: TextField(
												controller: _dobController,
												style: const TextStyle(color: Colors.white),
												decoration: const InputDecoration.collapsed(
													hintText: 'DD/MM/YYYY',
													hintStyle: TextStyle(color: Colors.white38),
												),
											),
										),
										const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
									],
								),
							),
							const SizedBox(height: 12),
							const Text('Phone Number', style: TextStyle(color: Colors.white54, fontSize: 12)),
							const SizedBox(height: 6),
							_FilledField(
								child: Row(
									children: <Widget>[
										Container(
											padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
											decoration: BoxDecoration(
												color: const Color(0xFF131964),
												borderRadius: BorderRadius.circular(8),
											),
											child: const Text('+92', style: TextStyle(color: Colors.white)),
										),
										const SizedBox(width: 10),
										Expanded(
											child: TextField(
												controller: _phoneController,
												style: const TextStyle(color: Colors.white),
												decoration: const InputDecoration.collapsed(
													hintText: 'Phone',
													hintStyle: TextStyle(color: Colors.white38),
												),
											),
										),
									],
								),
							),
							const SizedBox(height: 16),
							SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									style: ElevatedButton.styleFrom(
										backgroundColor: Colors.white,
										foregroundColor: const Color(0xFF00002E),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
										padding: const EdgeInsets.symmetric(vertical: 14),
										elevation: 0,
									),
									onPressed: () async {
										final name = _nameController.text.trim();
										final email = _emailController.text.trim();
										final phone = _phoneController.text.trim();
										final dob = _dobController.text.trim();
										try {
											await _profileController.updateUserInfo(
												name: name.isNotEmpty ? name : null,
												email: email.isNotEmpty ? email : null,
												bio: 'Phone: $phone, DOB: $dob',
											);
											if (mounted) {
												Navigator.of(context).pop();
												ScaffoldMessenger.of(context).showSnackBar(
													const SnackBar(content: Text('Changes saved')),
												);
											}
										} catch (e) {
											if (mounted) {
												ScaffoldMessenger.of(context).showSnackBar(
													SnackBar(content: Text('Failed to save: $e')),
												);
											}
										}
									},
									child: const Text('Save Changes'),
								),
							),
							const SizedBox(height: 12),
						],
					),
				),
			),
		);
	}
}

class _FilledField extends StatelessWidget {
	const _FilledField({required this.child});
	final Widget child;
	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
			decoration: BoxDecoration(
				color: const Color(0xFF0B0F4E),
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: const Color(0xFF27308A)),
			),
			child: child,
		);
	}
}