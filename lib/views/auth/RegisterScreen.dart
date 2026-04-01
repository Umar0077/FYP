import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
	const RegisterScreen({super.key});

	@override
	State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
	bool _loading = false;
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	final TextEditingController _nameController = TextEditingController();
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _dobController = TextEditingController();
	final TextEditingController _phoneController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();
	final TextEditingController _confirmPasswordController = TextEditingController();
	bool _obscure1 = true;
	bool _obscure2 = true;

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_dobController.dispose();
		_phoneController.dispose();
		_passwordController.dispose();
		_confirmPasswordController.dispose();
		super.dispose();
	}

	Future<void> _register() async {
		if (!_formKey.currentState!.validate()) return;
		setState(() => _loading = true);
		final AuthController authController = AuthController();
		try {
			final String email = _emailController.text.trim();
			final String password = _passwordController.text;
			final String name = _nameController.text.trim();
			final String phone = _phoneController.text.trim();
			final String dobText = _dobController.text.trim();
			DateTime? dobIso;
			try {
				if (dobText.contains('/')) {
					final parts = dobText.split('/');
					if (parts.length == 3) {
						final day = int.tryParse(parts[0]);
						final month = int.tryParse(parts[1]);
						final year = int.tryParse(parts[2]);
						if (day != null && month != null && year != null) dobIso = DateTime(year, month, day);
					}
				}
			} catch (_) {
				dobIso = null;
			}

			await authController.register(
				name: name,
				email: email,
				password: password,
				phone: phone,
				dobText: dobText,
				dobIso: dobIso,
			);
			if (mounted) Navigator.of(context).pushReplacementNamed('/home');
		} on FirebaseAuthException catch (e) {
			final String message = e.message ?? 'Registration failed';
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
		} on FirebaseException catch (fe) {
			final String message = fe.message ?? 'Failed to save profile';
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	Future<void> _pickDate() async {
		final DateTime now = DateTime.now();
		final DateTime? picked = await showDatePicker(
			context: context,
			initialDate: DateTime(now.year - 18, now.month, now.day),
			firstDate: DateTime(1900),
			lastDate: now,
			builder: (BuildContext context, Widget? child) {
				return Theme(
					data: Theme.of(context).copyWith(
						colorScheme: const ColorScheme.dark(primary: Colors.white, surface: Color(0xFF0B0F4E)),
					),
					child: child!,
				);
			},
		);
		if (picked != null) {
			_dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
			setState(() {});
		}
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color primaryTextColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color inputFillColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
		final Color inputBorderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color inputFocusedBorderColor = isDark ? const Color(0xFF3A45C3) : const Color(0xFF2D3DF0);
		final Color hintColor = isDark ? Colors.white38 : const Color(0xFF8A93B2);

		return Scaffold(
			backgroundColor: backgroundColor,
			body: Stack(
				children: [
					SafeArea(
						child: Center(
					child: SingleChildScrollView(
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 420),
							child: Padding(
								padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
								child: Form(
									key: _formKey,
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: <Widget>[
											IconButton(
												onPressed: () => Navigator.of(context).pop(),
												icon: Icon(Icons.arrow_back, color: primaryTextColor),
											),
											const SizedBox(height: 6),
											Text('Sign up', style: TextStyle(color: primaryTextColor, fontSize: 26, fontWeight: FontWeight.w800)),
											const SizedBox(height: 6),
											Text('Create an account to continue!', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											const SizedBox(height: 18),
											Text('Full Name', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											const SizedBox(height: 6),
											_InputField(
												controller: _nameController,
												hint: 'Your name',
												validator: _required,
												fillColor: inputFillColor,
												borderColor: inputBorderColor,
												focusedBorderColor: inputFocusedBorderColor,
												hintColor: hintColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 12),
											Text('Email', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											const SizedBox(height: 6),
											_InputField(
												controller: _emailController,
												hint: 'email@example.com',
												keyboardType: TextInputType.emailAddress,
												validator: _required,
												fillColor: inputFillColor,
												borderColor: inputBorderColor,
												focusedBorderColor: inputFocusedBorderColor,
												hintColor: hintColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 12),
											Text('Birth of date', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											const SizedBox(height: 6),
											_InputField(
												controller: _dobController,
												hint: 'DD/MM/YYYY',
												readOnly: true,
												suffix: IconButton(
													icon: Icon(Icons.calendar_today, color: secondaryTextColor, size: 20),
													onPressed: _pickDate,
												),
												fillColor: inputFillColor,
												borderColor: inputBorderColor,
												focusedBorderColor: inputFocusedBorderColor,
												hintColor: hintColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 12),
											Text('Phone Number', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											const SizedBox(height: 6),
											_InputField(
												controller: _phoneController,
												hint: '(454) 726-0592',
												keyboardType: TextInputType.phone,
												validator: _required,
												fillColor: inputFillColor,
												borderColor: inputBorderColor,
												focusedBorderColor: inputFocusedBorderColor,
												hintColor: hintColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 12),
											Text('Password', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											const SizedBox(height: 6),
											_InputField(
												controller: _passwordController,
												hint: 'Password',
												obscureText: _obscure1,
												suffix: IconButton(
													icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: secondaryTextColor),
													onPressed: () => setState(() => _obscure1 = !_obscure1),
												),
												validator: (String? v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
												fillColor: inputFillColor,
												borderColor: inputBorderColor,
												focusedBorderColor: inputFocusedBorderColor,
												hintColor: hintColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 12),
											Text('Confirm Password', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											const SizedBox(height: 6),
											_InputField(
												controller: _confirmPasswordController,
												hint: 'Re-enter password',
												obscureText: _obscure2,
												suffix: IconButton(
													icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: secondaryTextColor),
													onPressed: () => setState(() => _obscure2 = !_obscure2),
												),
												validator: (String? v) => v != _passwordController.text ? 'Passwords do not match' : null,
												fillColor: inputFillColor,
												borderColor: inputBorderColor,
												focusedBorderColor: inputFocusedBorderColor,
												hintColor: hintColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 18),
											_PrimaryButton(
												label: _loading ? 'Creating...' : 'Register',
												filled: true,
												onPressed: _loading ? null : () { _register(); },
												backgroundColor: isDark ? Colors.white : const Color(0xFF00002E),
												foregroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
												borderColor: Colors.white.withOpacity(0.6),
											),
											const SizedBox(height: 14),
											Row(children: <Widget>[
												Expanded(child: Container(height: 1, color: isDark ? Colors.white12 : Colors.black12)),
												Padding(
													padding: const EdgeInsets.symmetric(horizontal: 8),
													child: Text('Or', style: TextStyle(color: secondaryTextColor)),
												),
												Expanded(child: Container(height: 1, color: isDark ? Colors.white12 : Colors.black12)),
											]),
											const SizedBox(height: 14),
											_SocialButton(
												label: 'Continue with Google',
												assetPath: 'assets/images/google.png',
												onPressed: () {},
												borderColor: inputBorderColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 10),
											_SocialButton(
												label: 'Continue with Facebook',
												assetPath: 'assets/images/facebook.png',
												onPressed: () {},
												borderColor: inputBorderColor,
												textColor: primaryTextColor,
											),
											const SizedBox(height: 14),
											Row(
												mainAxisAlignment: MainAxisAlignment.center,
												children: <Widget>[
													Text('Already have an account?  ', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
													GestureDetector(
														onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
														child: Text('Login', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w700)),
													),
												],
											),
										],
									),
								),
							),
						),
					),
						),
					),
					if (_loading)
						Positioned.fill(
							child: Container(
								color: const Color(0xFF27308A).withOpacity(0.95), // overlay uses provided color code
								child: Center(
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: const [
											CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
											SizedBox(height: 12),
											Text('Creating account...', style: TextStyle(color: Colors.white, fontSize: 16)),
										],
									),
								),
							),
						),
				],
			),
		);
	}

	String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;
}

class _InputField extends StatelessWidget {
	const _InputField({
		required this.controller,
		required this.hint,
		this.obscureText = false,
		this.suffix,
		this.keyboardType,
		this.validator,
		this.readOnly = false,
		this.fillColor,
		this.borderColor,
		this.focusedBorderColor,
		this.hintColor,
		this.textColor,
	});

	final TextEditingController controller;
	final String hint;
	final bool obscureText;
	final Widget? suffix;
	final TextInputType? keyboardType;
	final String? Function(String?)? validator;
	final bool readOnly;
	final Color? fillColor;
	final Color? borderColor;
	final Color? focusedBorderColor;
	final Color? hintColor;
	final Color? textColor;

	@override
	Widget build(BuildContext context) {
		return TextFormField(
			controller: controller,
			obscureText: obscureText,
			validator: validator,
			keyboardType: keyboardType,
			readOnly: readOnly,
			style: TextStyle(color: textColor),
			decoration: InputDecoration(
				hintText: hint,
				hintStyle: TextStyle(color: hintColor),
				filled: true,
				fillColor: fillColor,
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(10),
					borderSide: BorderSide(color: borderColor ?? Colors.white, width: 1),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(10),
					borderSide: BorderSide(color: focusedBorderColor ?? Colors.white, width: 1),
				),
				contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
				suffixIcon: suffix,
			),
		);
	}
}

class _PrimaryButton extends StatelessWidget {
	const _PrimaryButton({
		required this.label,
		required this.filled,
		this.onPressed,
		this.backgroundColor,
		this.foregroundColor,
		this.borderColor,
	});

	final String label;
	final bool filled;
	final VoidCallback? onPressed;
	final Color? backgroundColor;
	final Color? foregroundColor;
	final Color? borderColor;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			child: ElevatedButton(
				style: ElevatedButton.styleFrom(
					backgroundColor: backgroundColor ?? Colors.white,
					foregroundColor: foregroundColor ?? const Color(0xFF00002E),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(10),
						side: BorderSide(color: filled ? Colors.transparent : (borderColor ?? Colors.white.withOpacity(0.6))),
					),
					padding: const EdgeInsets.symmetric(vertical: 14),
					elevation: 0,
				),
				onPressed: onPressed,
				child: Text(label),
			),
		);
	}
}

class _SocialButton extends StatelessWidget {
	const _SocialButton({
		required this.label,
		required this.assetPath,
		required this.onPressed,
		this.borderColor,
		this.textColor,
	});

	final String label;
	final String assetPath;
	final VoidCallback onPressed;
	final Color? borderColor;
	final Color? textColor;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			child: OutlinedButton.icon(
				style: OutlinedButton.styleFrom(
					side: BorderSide(color: borderColor ?? const Color(0xFF27308A)),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
					foregroundColor: textColor ?? Colors.white,
					padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
				),
				onPressed: onPressed,
				icon: Image.asset(assetPath, width: 20, height: 20),
				label: Text(label, style: TextStyle(color: textColor ?? Colors.white)),
			),
		);
	}
}