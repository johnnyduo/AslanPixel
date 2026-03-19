import 'package:flutter/material.dart';
import 'package:aslan_pixel/features/home/view/home_page.dart';
import 'package:aslan_pixel/features/feed/view/feed_page.dart';
import 'package:aslan_pixel/features/finance/view/finance_page.dart';
import 'package:aslan_pixel/features/home/view/pixel_world_page.dart';
import 'package:aslan_pixel/features/profile/view/profile_page.dart';
import 'package:aslan_pixel/shared/widgets/pixel_icon.dart';

/// Main Tabs page — Phase 5C: Profile tab is live.
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key, this.tabIndex = 0});

  static const String routeName = '/home';

  final int tabIndex;

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.tabIndex;
  }

  static const _tabLabels = ['Home', 'Pixel', 'Portfolio', 'Social', 'Profile'];

  static const _tabPixelIcons = [
    PixelIcon.home,
    PixelIcon.world,
    PixelIcon.chart,
    PixelIcon.social,
    PixelIcon.profile,
  ];

  static final _pages = [
    const HomePage(),
    const PixelWorldPage(),
    const FinancePage(),
    const FeedPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF00F5A0);
    final unselectedColor = const Color(0xFFE8F4F8).withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF0A1628),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0A1628).withValues(alpha: 0.95),
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: List.generate(
            _tabLabels.length,
            (i) => BottomNavigationBarItem(
              icon: Opacity(
                opacity: _currentIndex == i ? 1.0 : 0.4,
                child: PixelIcon(
                  _tabPixelIcons[i],
                  size: 24,
                ),
              ),
              label: _tabLabels[i],
            ),
          ),
        ),
      ),
    );
  }
}
