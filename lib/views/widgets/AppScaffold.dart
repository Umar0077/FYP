import 'package:flutter/material.dart';
import 'dart:ui';

class AppScaffold extends StatelessWidget {
	const AppScaffold({
		super.key,
		required this.body,
		this.appBarTitle,
		this.onBack,
		this.showBottomNav = false,
		this.showAppBar = true,
		this.backgroundColor,
		this.resizeToAvoidBottomInset,
		this.actions,
	});

	final Widget body;
	final String? appBarTitle;
	final VoidCallback? onBack;
	final bool showBottomNav;
	final bool showAppBar;
	final Color? backgroundColor;
	final bool? resizeToAvoidBottomInset;
	final List<Widget>? actions;

	@override
	Widget build(BuildContext context) {
		final int currentIndex = _inferIndexFromRoute(ModalRoute.of(context)?.settings.name ?? '');
		return Scaffold(
			backgroundColor: backgroundColor,
			resizeToAvoidBottomInset: resizeToAvoidBottomInset,
			appBar: showAppBar
					? AppBar(
							leading: Navigator.of(context).canPop()
									? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack ?? () => Navigator.of(context).pop())
									: null,
							title: appBarTitle != null ? Text(appBarTitle!) : null,
							actions: actions,
							centerTitle: true,
						)
					: null,
			body: body,
			bottomNavigationBar: showBottomNav
					? _StylishBottomNavBar(
							currentIndex: currentIndex,
							onTap: (int i) {
								final String route = switch (i) {
									0 => '/home',
									1 => '/resources_tab',
									2 => '/recent_tab',
									3 => '/profile_tab',
									_ => '/home',
								};
								if (ModalRoute.of(context)?.settings.name != route) {
									Navigator.of(context).pushReplacementNamed(route);
								}
							},
						)
					: null,
		);
	}

	int _inferIndexFromRoute(String name) {
		if (name.contains('resources')) return 1;
		if (name.contains('recent')) return 2;
		if (name.contains('profile')) return 3;
		return 0;
	}
}


class _StylishBottomNavBar extends StatefulWidget {
	const _StylishBottomNavBar({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

	final int currentIndex;
	final ValueChanged<int> onTap;

	@override
	State<_StylishBottomNavBar> createState() => _StylishBottomNavBarState();
}

class _StylishBottomNavBarState extends State<_StylishBottomNavBar> with SingleTickerProviderStateMixin {
	late final AnimationController _controller;
	late int _selected;

	@override
	void initState() {
		super.initState();
		_selected = widget.currentIndex;
		_controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
	}

	@override
	void didUpdateWidget(covariant _StylishBottomNavBar oldWidget) {
		super.didUpdateWidget(oldWidget);
		if (widget.currentIndex != _selected) {
			_selected = widget.currentIndex;
			_controller.forward(from: 0);
		}
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final glassBg = isDark ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.55);
		final accent = isDark ? const Color(0xFF3A45C3) : const Color(0xFF2D3DF0);
		final glassBorder = isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.08);
		return Container(
			height: 78,
			padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 12),
			decoration: BoxDecoration(
				borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
				border: Border.all(color: glassBorder, width: 1.2),
			),
			child: ClipRRect(
				borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
				child: BackdropFilter(
					filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
					child: Container(
						decoration: BoxDecoration(
							color: glassBg,
							borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
							boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.08), blurRadius: 18, offset: const Offset(0, -6))],
						),
						child: Stack(
							children: [
								Positioned.fill(
									child: CustomPaint(
										painter: _NavBackgroundPainter(color: Colors.transparent),
									),
								),
								Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: List.generate(4, (i) {
										final icons = [Icons.home_rounded, Icons.grid_view_rounded, Icons.access_time_rounded, Icons.person_outline];
										final labels = ['Home', 'Categories', 'Sessions', 'Profile'];
										final bool active = i == _selected;
										return Expanded(
											child: GestureDetector(
												onTap: () {
													widget.onTap(i);
													setState(() => _selected = i);
													_controller.forward(from: 0);
												},
												child: AnimatedBuilder(
													animation: _controller,
													builder: (context, child) {
														final t = Curves.easeOut.transform(_controller.value);
														final scale = active ? 1.08 - (0.08 * (1 - t)) : 1.0 + (0.03 * t);
														return Transform.scale(
															scale: active ? scale : 1.0,
															child: child,
														);
													},
													child: Column(
														mainAxisSize: MainAxisSize.min,
														children: [
															Container(
																width: active ? 48 : 44,
																height: active ? 48 : 44,
																decoration: BoxDecoration(
																	shape: BoxShape.circle,
																	gradient: active
																			? RadialGradient(colors: [accent.withOpacity(0.22), accent.withOpacity(0.04)])
																			: null,
																	boxShadow: active
																			? [BoxShadow(color: accent.withOpacity(0.18), blurRadius: 12, spreadRadius: 2)]
																			: [],
																),
																child: Icon(
																	icons[i],
																	size: active ? 26 : 22,
																	color: active ? accent : (isDark ? Colors.white70 : const Color(0xFF8A93B2)),
																),
															),
															const SizedBox(height: 6),
															Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? accent : (isDark ? Colors.white54 : const Color(0xFF8A93B2))), textAlign: TextAlign.center),
														],
													),
												),
											),
										);
									}),
								),
							],
						),
					),
				),
			),
		);
	}
}

class _NavBackgroundPainter extends CustomPainter {
	_NavBackgroundPainter({required this.color});
	final Color color;

	@override
	void paint(Canvas canvas, Size size) {
		final paint = Paint()..color = color;
		final path = Path();
		// create a gentle curved top edge
		path.moveTo(0, 18);
		path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 6);
		path.quadraticBezierTo(size.width * 0.75, 12, size.width, 6);
		path.lineTo(size.width, size.height);
		path.lineTo(0, size.height);
		path.close();
		canvas.drawShadow(path, Colors.black, 6, true);
		canvas.drawPath(path, paint);
	}

	@override
	bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}