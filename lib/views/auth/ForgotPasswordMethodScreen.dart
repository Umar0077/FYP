// Re-export of the original forgot password method view
import 'package:flutter/material.dart';

class ForgotPasswordMethodScreen extends StatelessWidget {
	const ForgotPasswordMethodScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color primaryTextColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color cardColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
		final Color cardBorder = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color iconBg = isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8);
		final Color iconColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color buttonBg = isDark ? Colors.white : const Color(0xFF00002E);
		final Color buttonFg = isDark ? const Color(0xFF00002E) : Colors.white;

		return Scaffold(
			backgroundColor: backgroundColor,
			body: SafeArea(
				child: Center(
					child: SingleChildScrollView(
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 420),
							child: Padding(
								padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										IconButton(
											onPressed: () => Navigator.of(context).pop(),
											icon: Icon(Icons.arrow_back, color: primaryTextColor),
										),
										const SizedBox(height: 12),
										Text(
											'Forget Password',
											style: TextStyle(color: primaryTextColor, fontSize: 28, fontWeight: FontWeight.w800),
										),
										const SizedBox(height: 8),
										Text(
											'Select which contact details should we use to reset your password',
											style: TextStyle(color: secondaryTextColor, fontSize: 12),
										),
										const SizedBox(height: 24),
										_MethodCard(
											icon: Icons.email_outlined,
											title: 'Email',
											subtitle: 'Code will be sent to your email',
											onTap: () => Navigator.of(context).pushNamed('/forgot/email'),
											cardColor: cardColor,
											cardBorder: cardBorder,
											iconBg: iconBg,
											iconColor: iconColor,
											titleColor: primaryTextColor,
											subtitleColor: secondaryTextColor,
										),
										const SizedBox(height: 16),
										// Phone method intentionally omitted as requested
										const SizedBox(height: 24),
										SizedBox(
											width: double.infinity,
											child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													backgroundColor: buttonBg,
													foregroundColor: buttonFg,
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													padding: const EdgeInsets.symmetric(vertical: 14),
													elevation: 0,
												),
												onPressed: () => Navigator.of(context).pushNamed('/forgot/email'),
												child: const Text('Next'),
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

class _MethodCard extends StatelessWidget {
	const _MethodCard({
		required this.icon,
		required this.title,
		required this.subtitle,
		required this.onTap,
		required this.cardColor,
		required this.cardBorder,
		required this.iconBg,
		required this.iconColor,
		required this.titleColor,
		required this.subtitleColor,
	});

	final IconData icon;
	final String title;
	final String subtitle;
	final VoidCallback onTap;
	final Color cardColor;
	final Color cardBorder;
	final Color iconBg;
	final Color iconColor;
	final Color titleColor;
	final Color subtitleColor;

	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(16),
			child: Ink(
				decoration: BoxDecoration(
					color: cardColor,
					borderRadius: BorderRadius.circular(16),
					border: Border.all(color: cardBorder),
					boxShadow: <BoxShadow>[
						BoxShadow(
							color: Colors.black.withOpacity(0.10),
							blurRadius: 10,
							offset: const Offset(0, 6),
						),
					],
				),
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Row(
						children: <Widget>[
							Container(
								width: 44,
								height: 44,
								decoration: BoxDecoration(
									color: iconBg,
									borderRadius: BorderRadius.circular(12),
								),
								child: Icon(icon, color: iconColor),
							),
							const SizedBox(width: 14),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										Text(title, style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w700)),
										const SizedBox(height: 4),
										Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
									],
								),
							),
						],
					),
				),
			),
		);
	}
}