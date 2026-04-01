import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
	const ForgotPasswordEmailScreen({super.key});

	@override
	State<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	final TextEditingController _emailController = TextEditingController();
	final AuthController _authController = AuthController();
	bool _loading = false;

	@override
	void dispose() {
		_emailController.dispose();
		super.dispose();
	}

	String? _validateEmail(String? value) {
		if (value == null || value.isEmpty) {
			return 'Email is required';
		}
		final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
		if (!emailRegex.hasMatch(value)) {
			return 'Please enter a valid email address';
		}
		return null;
	}

	Future<void> _sendReset() async {
		if (!_formKey.currentState!.validate()) return;
		
		final email = _emailController.text.trim();
		setState(() => _loading = true);
		
		try {
			await _authController.sendPasswordResetEmail(email: email);
			if (!mounted) return;
			setState(() => _loading = false);
			
			showDialog<void>(
				context: context,
				builder: (context) => AlertDialog(
					title: const Text('Reset Email Sent'),
					content: Text('A password reset link has been sent to $email. Please check your email and follow the instructions to reset your password.'),
					actions: <Widget>[
						TextButton(
							onPressed: () {
								Navigator.of(context).pop(); // Close dialog
								Navigator.of(context).pop(); // Go back to login
							}, 
							child: const Text('OK')
						),
					],
				),
			);
		} on FirebaseAuthException catch (e) {
			if (!mounted) return;
			setState(() => _loading = false);
			
			String errorMessage;
			switch (e.code) {
				case 'user-not-found':
					errorMessage = 'No user found with this email address.';
					break;
				case 'invalid-email':
					errorMessage = 'The email address is invalid.';
					break;
				case 'too-many-requests':
					errorMessage = 'Too many requests. Please try again later.';
					break;
				default:
					errorMessage = e.message ?? 'Failed to send reset email.';
			}
			
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(errorMessage),
					backgroundColor: Colors.red,
				),
			);
		} catch (e) {
			if (!mounted) return;
			setState(() => _loading = false);
			
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('An unexpected error occurred. Please try again.'),
					backgroundColor: Colors.red,
				),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color bg = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color inputFillColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
		final Color inputBorderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color buttonBg = isDark ? Colors.white : const Color(0xFF00002E);
		final Color buttonFg = isDark ? const Color(0xFF00002E) : Colors.white;
		
		return Scaffold(
			backgroundColor: bg,
			appBar: AppBar(
				backgroundColor: Colors.transparent,
				elevation: 0,
				iconTheme: IconThemeData(color: textColor),
			),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 24),
					child: Form(
						key: _formKey,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: <Widget>[
								const SizedBox(height: 16),
								Text('Reset your password', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w700)),
								const SizedBox(height: 8),
								Text('Enter your email address and we will send a reset link.', style: TextStyle(color: secondaryTextColor)),
								const SizedBox(height: 24),
								TextFormField(
									controller: _emailController,
									keyboardType: TextInputType.emailAddress,
									style: TextStyle(color: textColor),
									validator: _validateEmail,
									decoration: InputDecoration(
										labelText: 'Email',
										labelStyle: TextStyle(color: secondaryTextColor),
										hintText: 'email@example.com',
										hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.6)),
										filled: true,
										fillColor: inputFillColor,
										border: OutlineInputBorder(
											borderRadius: BorderRadius.circular(12),
											borderSide: BorderSide(color: inputBorderColor),
										),
										enabledBorder: OutlineInputBorder(
											borderRadius: BorderRadius.circular(12),
											borderSide: BorderSide(color: inputBorderColor),
										),
										focusedBorder: OutlineInputBorder(
											borderRadius: BorderRadius.circular(12),
											borderSide: BorderSide(color: isDark ? const Color(0xFF3A45C3) : const Color(0xFF2D3DF0), width: 2),
										),
										errorBorder: OutlineInputBorder(
											borderRadius: BorderRadius.circular(12),
											borderSide: const BorderSide(color: Colors.red),
										),
										focusedErrorBorder: OutlineInputBorder(
											borderRadius: BorderRadius.circular(12),
											borderSide: const BorderSide(color: Colors.red, width: 2),
										),
									),
								),
								const SizedBox(height: 24),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										onPressed: _loading ? null : _sendReset,
										style: ElevatedButton.styleFrom(
											backgroundColor: buttonBg,
											foregroundColor: buttonFg,
											padding: const EdgeInsets.symmetric(vertical: 14), 
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
											elevation: 0,
										),
										child: _loading 
											? const SizedBox(
													width: 18, 
													height: 18, 
													child: CircularProgressIndicator(
														strokeWidth: 2,
														valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
													)
												) 
											: const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
									),
								),
							],
						),
					),
				),
			),
		);
	}
}