import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
	const LoginScreen({super.key});

	@override
	State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();
	bool _obscure = true;
	bool _loading = false;

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	Future<void> _login() async {
		final email = _emailController.text.trim();
		final password = _passwordController.text;

		final bool isEmailValid = GetUtils.isEmail(email);
		final bool isPasswordValid = password.length >= 6;

		if (!isEmailValid && !isPasswordValid) {
			Get.snackbar(
				'Input Error',
				'enter correct email and password',
				snackPosition: SnackPosition.BOTTOM,
				backgroundColor: Colors.red,
				colorText: Colors.white,
			);
			return;
		} else if (!isEmailValid) {
			Get.snackbar(
				'Input Error',
				'enter a correct email please',
				snackPosition: SnackPosition.BOTTOM,
				backgroundColor: Colors.red,
				colorText: Colors.white,
			);
			return;
		} else if (!isPasswordValid) {
			Get.snackbar(
				'Input Error',
				'enter correct password please',
				snackPosition: SnackPosition.BOTTOM,
				backgroundColor: Colors.red,
				colorText: Colors.white,
			);
			return;
		}

		if (!_formKey.currentState!.validate()) return;
		
		final authController = Get.find<AuthController>();
		final success = await authController.login(email: email, password: password);
		
		if (success) {
			final bool requiresConsent = await authController.requiresCameraConsent();
			Get.offAllNamed(requiresConsent ? '/camera-consent' : '/home');
		} else if (authController.errorMessage.value.isNotEmpty) {
			Get.snackbar(
				'Login Failed',
				authController.errorMessage.value,
				snackPosition: SnackPosition.BOTTOM,
				backgroundColor: Colors.red,
				colorText: Colors.white,
			);
		}
	}

	Future<void> _signInWithGoogle() async {
		setState(() => _loading = true);
		
		final authController = Get.find<AuthController>();
		final success = await authController.signInWithGoogle();
		
		setState(() => _loading = false);
		
		if (success) {
			final bool requiresConsent = await authController.requiresCameraConsent();
			Get.offAllNamed(requiresConsent ? '/camera-consent' : '/home');
		} else if (authController.errorMessage.value.isNotEmpty) {
			Get.snackbar(
				'Google Sign-In Failed',
				authController.errorMessage.value,
				snackPosition: SnackPosition.BOTTOM,
				backgroundColor: Colors.red,
				colorText: Colors.white,
			);
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
													Row(
														children: <Widget>[
															Image.asset('assets/NovaPrepLogo.png', width: 36, height: 36),
														],
													),
													const SizedBox(height: 18),
													Text('Sign in to your Account', style: TextStyle(color: primaryTextColor, fontSize: 22, fontWeight: FontWeight.w800)),
													const SizedBox(height: 8),
													Text('Enter your email and password to log in', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
													const SizedBox(height: 22),

													Text('Email', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
													const SizedBox(height: 6),
													_InputField(
														controller: _emailController,
														hint: 'email@example.com',
														keyboardType: TextInputType.emailAddress,
														validator: (String? v) => (v == null || v.isEmpty || !GetUtils.isEmail(v)) ? 'enter a correct email please' : null,
														fillColor: inputFillColor,
														borderColor: inputBorderColor,
														focusedBorderColor: inputFocusedBorderColor,
														hintColor: hintColor,
														textColor: primaryTextColor,
													),

													const SizedBox(height: 14),
													Text('Password', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
													const SizedBox(height: 6),
													_InputField(
														controller: _passwordController,
														hint: 'Password',
														obscureText: _obscure,
														suffix: IconButton(
															icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: secondaryTextColor),
															onPressed: () => setState(() => _obscure = !_obscure),
														),
														validator: (String? v) => (v == null || v.length < 6) ? 'enter correct password please' : null,
														fillColor: inputFillColor,
														borderColor: inputBorderColor,
														focusedBorderColor: inputFocusedBorderColor,
														hintColor: hintColor,
														textColor: primaryTextColor,
													),

													const SizedBox(height: 8),
													Row(
														children: <Widget>[
															const Spacer(),
															TextButton(
																onPressed: () => Navigator.of(context).pushNamed('/forgot/email'),
																child: Text('Forgot Password?', style: TextStyle(color: secondaryTextColor)),
															),
														],
													),

													const SizedBox(height: 10),
													_PrimaryButton(
														label: _loading ? 'Logging in...' : 'Log In',
														filled: true,
														onPressed: _loading ? null : () { _login(); },
														backgroundColor: isDark ? Colors.white : const Color(0xFF00002E),
														foregroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
														borderColor: Colors.white.withOpacity(0.6),
													),

													const SizedBox(height: 18),
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
														onPressed: _loading ? null : _signInWithGoogle,
														borderColor: inputBorderColor,
														textColor: primaryTextColor,
													),

													const SizedBox(height: 18),
													Row(
														mainAxisAlignment: MainAxisAlignment.center,
														children: <Widget>[
															Text("Don't have an account?  ", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
															GestureDetector(
																onTap: () => Navigator.of(context).pushNamed('/register'),
																child: Text('Sign Up', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w700)),
															),
														],
													),
													const SizedBox(height: 24),
													Center(
														child: GestureDetector(
															onTap: () => Get.toNamed('/admin/login'),
															child: Text('Login as an Admin', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
														),
													),
												],
											),
										),
									),
								),
							),
						),
					),

					// purple overlay
					if (_loading)
						Positioned.fill(
							child: Container(
								color: Color(0xFF27308A).withOpacity(0.95), // overlay uses provided color code
								child: Center(
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: const [
											CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
											SizedBox(height: 12),
											Text('Checking credentials...', style: TextStyle(color: Colors.white, fontSize: 16)),
										],
									),
								),
							),
						),
				],
			),
		);
	}
}


class _InputField extends StatelessWidget {
	const _InputField({
		required this.controller,
		required this.hint,
		this.obscureText = false,
		this.suffix,
		this.keyboardType,
		this.validator,
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
		this.onPressed,
		this.borderColor,
		this.textColor,
	});

	final String label;
	final String assetPath;
	final VoidCallback? onPressed;
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
