import 'package:flutter/material.dart';
import '../widgets/AppScaffold.dart';

class SupportChatScreen extends StatelessWidget {
	const SupportChatScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color userMsgColor = isDark ? const Color(0xFF0A1733) : const Color(0xFFE8EBF8);
		final Color botMsgColor = isDark ? const Color(0xFF1B215E) : const Color(0xFFF5F6FA);
		final Color inputBgColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF2F4FF);
		final Color inputFieldColor = isDark ? const Color(0xFF0A0F2E) : Colors.white;
		final Color borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color iconBgColor = isDark ? Colors.white : const Color(0xFFE8EBF8);
		final Color iconColor = isDark ? const Color(0xFF0A0F2E) : const Color(0xFF00002E);
		final Color inputHintColor = isDark ? Colors.white54 : const Color(0xFF7C86B2);
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;

		return AppScaffold(
			appBarTitle: 'Helpy',
			backgroundColor: backgroundColor,
			body: SafeArea(
				child: Column(
					children: [
						Expanded(
							child: ListView(
								padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 100),
								children: [
									Align(
										alignment: Alignment.centerLeft,
										child: Container(
											padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
											decoration: BoxDecoration(color: userMsgColor, borderRadius: BorderRadius.circular(12)),
											child: Text(
												'Hi, I just wanna know that how much time you\'ll be updated.',
												style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0A0F2E)),
											),
										),
									),
									const SizedBox(height: 10),
									Align(
										alignment: Alignment.centerLeft,
										child: Container(
											padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
											decoration: BoxDecoration(color: botMsgColor, borderRadius: BorderRadius.circular(12)),
											child: Text('Maybe, Nearly July, 2022', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF27308A))),
										),
									),
									const SizedBox(height: 10),
									Align(
										alignment: Alignment.centerLeft,
										child: Container(
											padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
											decoration: BoxDecoration(color: botMsgColor, borderRadius: BorderRadius.circular(12)),
											child: Text('Okay, I\'m Waiting...', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF27308A))),
										),
									),
								],
							),
						),

						SafeArea(
							top: false,
							child: Container(
								padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
								color: inputBgColor,
								child: Row(
									children: [
										Container(
											padding: const EdgeInsets.all(10),
											decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
											child: Icon(Icons.mic, color: iconColor, size: 18),
										),
										const SizedBox(width: 10),
										Expanded(
											child: Container(
												padding: const EdgeInsets.symmetric(horizontal: 12),
												decoration: BoxDecoration(
													color: inputFieldColor,
													borderRadius: BorderRadius.circular(30),
													border: Border.all(color: borderColor),
												),
												child: Row(
													children: [
														Expanded(
															child: TextField(
																decoration: InputDecoration.collapsed(hintText: 'Write now..', hintStyle: TextStyle(color: inputHintColor)),
																style: TextStyle(color: isDark ? Colors.white : Colors.black87),
															),
														),
													],
												),
											),
										),
										const SizedBox(width: 10),
										Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: Icon(Icons.send, color: iconColor, size: 18)),
									],
								),
							),
						),
					],
				),
			),
		);
	}
}