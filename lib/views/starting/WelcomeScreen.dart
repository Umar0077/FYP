import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
	const WelcomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color primaryTextColor = isDark ? Colors.white : const Color(0xFF0A0F2E);

		return Scaffold(
			backgroundColor: backgroundColor,
			body: SafeArea(
				child: Center(
					child: SingleChildScrollView(
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24),
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: <Widget>[
									const SizedBox(height: 24),
									Image.asset(
										'assets/NovaPrepLogo.png',
										width: 160,
										height: 160,
									),
									const SizedBox(height: 24),
									Text(
										'Welcome to',
										style: TextStyle(
											color: primaryTextColor,
											fontSize: 24,
											fontWeight: FontWeight.w700,
										),
									),
									const SizedBox(height: 8),
									Text(
										'NovaPrep',
										style: TextStyle(
											color: primaryTextColor,
											fontSize: 28,
											fontWeight: FontWeight.w800,
										),
									),
									const SizedBox(height: 28),
									_PrimaryButton(
										label: 'Log in',
										filled: true,
										onPressed: () => Navigator.of(context).pushNamed('/login'),
										isDark: isDark,
									),
									const SizedBox(height: 14),
									_PrimaryButton(
										label: 'Sign up',
										filled: false,
										onPressed: () => Navigator.of(context).pushNamed('/register'),
										isDark: isDark,
									),
									const SizedBox(height: 24),
								],
							),
						),
					),
				),
			),
		);
	}
}

class _PrimaryButton extends StatelessWidget {
	const _PrimaryButton({
		required this.label,
		required this.filled,
		this.onPressed,
		required this.isDark,
	});

	final String label;
	final bool filled;
	final VoidCallback? onPressed;
	final bool isDark;

	@override
	Widget build(BuildContext context) {
		final Color bg = filled ? (isDark ? Colors.white : const Color(0xFF00002E)) : Colors.transparent;
		final Color fg = filled ? (isDark ? const Color(0xFF00002E) : Colors.white) : (isDark ? Colors.white : const Color(0xFF00002E));
		final Color border = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF00002E).withOpacity(0.6);
		return SizedBox(
			width: double.infinity,
			child: ElevatedButton(
				style: ElevatedButton.styleFrom(
					backgroundColor: bg,
					foregroundColor: fg,
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(24),
						side: BorderSide(color: filled ? Colors.transparent : border),
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