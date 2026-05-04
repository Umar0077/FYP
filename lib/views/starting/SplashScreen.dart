import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
	const SplashScreen({super.key});

	@override
	State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
	late AnimationController _logoController;
	late AnimationController _dotsController;
	late Animation<double> _logoScaleAnimation;
	late Animation<double> _logoFadeAnimation;
	late Animation<double> _logoRotationAnimation;
	@override
	void initState() {
		super.initState();
		
		// Initialize animation controllers
		_logoController = AnimationController(
			duration: const Duration(milliseconds: 1500),
			vsync: this,
		);
		
		_dotsController = AnimationController(
			duration: const Duration(milliseconds: 1200),
			vsync: this,
		);
		
		// Logo animations
		_logoScaleAnimation = Tween<double>(
			begin: 0.0,
			end: 1.0,
		).animate(CurvedAnimation(
			parent: _logoController,
			curve: Curves.elasticOut,
		));
		
		_logoFadeAnimation = Tween<double>(
			begin: 0.0,
			end: 1.0,
		).animate(CurvedAnimation(
			parent: _logoController,
			curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
		));
		
		_logoRotationAnimation = Tween<double>(
			begin: -0.1,
			end: 0.0,
		).animate(CurvedAnimation(
			parent: _logoController,
			curve: Curves.easeOutBack,
		));
		
		// Start logo animation immediately
		_logoController.forward();
		
		// Start dots animation with a slight delay
		Future.delayed(const Duration(milliseconds: 500), () {
			if (mounted) {
				_dotsController.repeat();
			}
		});
		
		Future<void>.delayed(const Duration(seconds: 2), () async {
			try {
				final AuthController authController = Get.find<AuthController>();
				final SharedPreferences prefs = await SharedPreferences.getInstance();
				final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
				if (!seenOnboarding) {
					if (!mounted) return;
					// debug
					// print('Splash: onboarding not seen, routing to /onboarding');
					Navigator.of(context).pushReplacementNamed('/onboarding');
					return;
				}

				// If onboarding was seen, check if a user is already persisted
				final User? immediateUser = FirebaseAuth.instance.currentUser;
				if (immediateUser != null) {
					final bool canAccess = await authController.canAccessWithCurrentSession();
					if (!mounted) return;
					if (!canAccess) {
						Navigator.of(context).pushReplacementNamed('/login');
						return;
					}
					final bool requiresConsent = await authController.requiresCameraConsent();
					if (!mounted) return;
					Navigator.of(context).pushReplacementNamed(requiresConsent ? '/camera-consent' : '/home');
					return;
				}

				// If not available immediately, listen once with a short timeout for auth state change
				try {
					final User? streamedUser = await FirebaseAuth.instance
							.authStateChanges()
							.timeout(const Duration(seconds: 3))
							.firstWhere((_) => true, orElse: () => null);
					if (!mounted) return;
					if (streamedUser != null) {
						final bool canAccess = await authController.canAccessWithCurrentSession();
						if (!mounted) return;
						if (!canAccess) {
							Navigator.of(context).pushReplacementNamed('/login');
							return;
						}
						final bool requiresConsent = await authController.requiresCameraConsent();
						if (!mounted) return;
						Navigator.of(context).pushReplacementNamed(requiresConsent ? '/camera-consent' : '/home');
					} else {
						Navigator.of(context).pushReplacementNamed('/login');
					}
				} catch (e) {
					// timeout or other error — treat as not logged in
					if (!mounted) return;
					Navigator.of(context).pushReplacementNamed('/login');
				}
			} catch (e) {
				// Fallback: go to onboarding if anything goes wrong
				if (!mounted) return;
				Navigator.of(context).pushReplacementNamed('/onboarding');
			}
		});
	}

	@override
	void dispose() {
		_logoController.dispose();
		_dotsController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF050A30) : Colors.white;

		return Scaffold(
			backgroundColor: backgroundColor,
			body: SafeArea(
				child: Stack(
					children: <Widget>[
						Center(
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									// Animated Logo
									AnimatedBuilder(
										animation: _logoController,
										builder: (context, child) {
											return Transform.scale(
												scale: _logoScaleAnimation.value,
												child: Transform.rotate(
													angle: _logoRotationAnimation.value,
													child: FadeTransition(
														opacity: _logoFadeAnimation,
														child: Image.asset(
															'assets/NovaPrepLogo.png',
															width: 160,
															height: 160,
															fit: BoxFit.contain,
														),
													),
												),
											);
										},
									),
									const SizedBox(height: 40),
									// Animated Loading Dots
									AnimatedBuilder(
										animation: _dotsController,
										builder: (context, child) {
											return Row(
												mainAxisAlignment: MainAxisAlignment.center,
												children: List.generate(3, (index) {
													final delay = index * 0.2;
													final animationValue = (_dotsController.value + delay) % 1.0;
													final scale = animationValue < 0.5 
														? 1.0 + (animationValue * 2 * 0.5)
														: 1.5 - ((animationValue - 0.5) * 2 * 0.5);
													
													return Container(
														margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
														child: Transform.scale(
															scale: scale,
															child: Container(
																width: 8,
																height: 8,
															decoration: BoxDecoration(
																color: const Color(0xFF6A5ACD).withOpacity(0.8), // Purple color
																shape: BoxShape.circle,
															),
															),
														),
													);
												}),
											);
										},
									),
								],
							),
						),
					],
				),
			),
		);
	}
}