import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
	const OnboardingScreen({super.key});

	@override
	State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
	final PageController _pageController = PageController();
	int _currentIndex = 0;

	final List<_OnboardingPageData> _pages = const <_OnboardingPageData>[
		_OnboardingPageData(
			imagePath: 'assets/images/Onboarding1.png',
			title: 'Your Personal AI\nInterview Coach',
			description:
					'Interview anytime. Get instant feedback on\nanswers, expressions, and confidence.',
		),
		_OnboardingPageData(
			imagePath: 'assets/images/Onboarding2.png',
			title: 'Simulate Real\nInterviews',
			description:
					'Answer AI questions and feel real interview\npressure—minus the stress.',
		),
		_OnboardingPageData(
			imagePath: 'assets/images/Onboarding3.png',
			title: 'Personalized\nImprovement Plans',
			description:
					'Get tips, practice, and resources to boost skills\nand land your dream job.',
		),
	];

	void _goToHome() async {
		// mark onboarding as seen so we don't show it again
		try {
			final SharedPreferences prefs = await SharedPreferences.getInstance();
			await prefs.setBool('seenOnboarding', true);
		} catch (e) {
			// ignore prefs errors and still navigate
		}
		if (!mounted) return;
		Navigator.of(context).pushReplacementNamed('/welcome');
	}

	void _nextPage() {
		if (_currentIndex < _pages.length - 1) {
			_pageController.nextPage(
				duration: const Duration(milliseconds: 300),
				curve: Curves.easeOut,
			);
		} else {
			_goToHome();
		}
	}

	void _prevPage() {
		if (_currentIndex > 0) {
			_pageController.previousPage(
				duration: const Duration(milliseconds: 300),
				curve: Curves.easeOut,
			);
		}
	}

	@override
	void dispose() {
		_pageController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final double maxContentWidth = 420;
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color skipColor = isDark ? Colors.white70 : const Color(0xFF27308A);

		return Scaffold(
			backgroundColor: backgroundColor,
			body: SafeArea(
				child: Center(
					child: ConstrainedBox(
						constraints: BoxConstraints(maxWidth: maxContentWidth),
						child: Column(
							children: <Widget>[
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
									child: Row(
										children: <Widget>[
											const Spacer(),
											TextButton(
												onPressed: _goToHome,
												child: Text('Skip', style: TextStyle(color: skipColor)),
											),
										],
									),
								),
								Expanded(
									child: PageView.builder(
										controller: _pageController,
										itemCount: _pages.length,
										onPageChanged: (int index) => setState(() => _currentIndex = index),
										itemBuilder: (BuildContext context, int index) {
											final _OnboardingPageData data = _pages[index];
											return _OnboardingCard(
												data: data,
												pageIndex: index,
												currentIndex: _currentIndex,
												totalCount: _pages.length,
											);
										},
									),
								),
								const SizedBox(height: 8),
								_BottomNavBar(
									onBack: _prevPage,
									onNext: _nextPage,
									isFirst: _currentIndex == 0,
									isLast: _currentIndex == _pages.length - 1,
								),
								const SizedBox(height: 20),
							],
						),
					),
				),
			),
		);
	}
}

class _OnboardingCard extends StatelessWidget {
	const _OnboardingCard({
		required this.data,
		required this.pageIndex,
		required this.currentIndex,
		required this.totalCount,
	});

	final _OnboardingPageData data;
	final int pageIndex;
	final int currentIndex;
	final int totalCount;

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color titleColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color descColor = isDark ? Colors.white70 : const Color(0xFF27308A);

		final double screenH = MediaQuery.of(context).size.height;
		double imageHeight = screenH * 0.42;
		if (imageHeight < 260) imageHeight = 260;
		if (imageHeight > 420) imageHeight = 420;

		return Align(
			alignment: Alignment.topCenter,
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
				child: Container(
					decoration: const BoxDecoration(
						// Transparent container to remove purple background
					),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: <Widget>[
							const SizedBox(height: 20),
							Container(
								decoration: BoxDecoration(
									boxShadow: <BoxShadow>[
										BoxShadow(
											color: Colors.black.withOpacity(0.45),
											blurRadius: 42,
											spreadRadius: 6,
											offset: const Offset(0, 18),
										),
									],
									borderRadius: BorderRadius.circular(16),
								),
								child: ClipRRect(
									borderRadius: BorderRadius.circular(16),
									child: Image.asset(
										data.imagePath,
										height: imageHeight,
										fit: BoxFit.cover,
									),
								),
							),
							const SizedBox(height: 14),
						Row(
							mainAxisAlignment: MainAxisAlignment.center,
							children: List<Widget>.generate(totalCount, (int i) {
								final bool isActive = i == currentIndex;
								return AnimatedContainer(
									duration: const Duration(milliseconds: 250),
									margin: const EdgeInsets.symmetric(horizontal: 4),
									width: isActive ? 8 : 6,
									height: isActive ? 8 : 6,
									decoration: BoxDecoration(
										color: isActive ? Colors.white : Colors.white30,
										shape: BoxShape.circle,
									),
								);
							}),
						),
						const SizedBox(height: 14),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 20),
							child: Text(
								data.title,
								textAlign: TextAlign.center,
								style: TextStyle(
									color: titleColor,
									fontSize: 20,
									fontWeight: FontWeight.w700,
									height: 1.3,
								),
							),
						),
						const SizedBox(height: 8),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 20),
							child: Text(
								data.description,
								textAlign: TextAlign.center,
								style: TextStyle(
									color: descColor,
									fontSize: 13,
									height: 1.35,
								),
							),
						),
							const SizedBox(height: 14),
						],
					),
				),
			),
		);
	}
}

class _BottomNavBar extends StatelessWidget {
	const _BottomNavBar({
		required this.onBack,
		required this.onNext,
		required this.isFirst,
		required this.isLast,
	});

	final VoidCallback onBack;
	final VoidCallback onNext;
	final bool isFirst;
	final bool isLast;

	@override
	Widget build(BuildContext context) {
		final Color containerBg = const Color(0xFF141A69);
		final Color innerBtn = const Color(0xFF2B2FA4);
		final Color enabledIcon = Colors.white;
		final Color disabledIcon = Colors.white38;
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
			decoration: BoxDecoration(
				color: containerBg.withOpacity(0.9),
				borderRadius: BorderRadius.circular(16),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: <Widget>[
					_RoundIconButton(
						icon: Icons.arrow_back_rounded,
						onTap: isFirst ? null : onBack,
						color: isFirst ? disabledIcon : enabledIcon,
						background: innerBtn.withOpacity(isFirst ? 0.3 : 1),
					),
					const SizedBox(width: 16),
					_RoundIconButton(
						icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
						onTap: onNext,
						color: enabledIcon,
						background: innerBtn,
					),
				],
			),
		);
	}
}

class _RoundIconButton extends StatelessWidget {
	const _RoundIconButton({
		required this.icon,
		required this.onTap,
		required this.color,
		required this.background,
	});

	final IconData icon;
	final VoidCallback? onTap;
	final Color color;
	final Color background;

	@override
	Widget build(BuildContext context) {
		return InkWell(
			borderRadius: BorderRadius.circular(20),
			onTap: onTap,
			child: Container(
				width: 44,
				height: 44,
				decoration: BoxDecoration(
					color: background,
					borderRadius: BorderRadius.circular(10),
				),
				child: Icon(icon, color: color),
			),
		);
	}
}

class _OnboardingPageData {
	const _OnboardingPageData({
		required this.imagePath,
		required this.title,
		required this.description,
	});

	final String imagePath;
	final String title;
	final String description;
}