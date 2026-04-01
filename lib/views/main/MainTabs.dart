import 'package:flutter/material.dart';
import 'HomeScreen.dart';
import 'ResourcesScreen.dart';
import 'RecentScreen.dart';
import 'ProfileScreen.dart';

class MainTabs extends StatefulWidget {
	const MainTabs({super.key, this.initialIndex = 0});

	final int initialIndex;

	@override
	State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
	late int _index = widget.initialIndex;

	final List<Widget> _pages = const <Widget>[
		HomeScreen(),
		ResourcesScreen(),
		RecentScreen(),
		ProfileScreen(),
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: _pages[_index],
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: _index,
				onTap: (int i) => setState(() => _index = i),
				type: BottomNavigationBarType.fixed,
				backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B0F4E) : Colors.white,
				selectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0A0F2E),
				unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF8A93B2),
				showSelectedLabels: false,
				showUnselectedLabels: false,
				items: const <BottomNavigationBarItem>[
					BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
					BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Resources'),
					BottomNavigationBarItem(icon: Icon(Icons.access_time_rounded), label: 'Recent'),
					BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
				],
			),
		);
	}
}