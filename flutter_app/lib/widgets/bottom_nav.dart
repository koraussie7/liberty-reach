import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/loops_direct_screen.dart';
import '../screens/liberty_market_screen.dart';
import '../screens/chat_list_screen.dart';
import '../widgets/animated_drawer.dart';

/// Core navigation: bottom items + Animated Drawer for secondary features
class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  // ── Core bottom nav items ─────────────────────────────────────
  static const List<_BottomNavItem> _navItems = [
    _BottomNavItem(Icons.home_rounded, '홈', HomeScreen.new),
    _BottomNavItem(Icons.play_circle_filled, 'Loops', LoopsDirectScreen.new),
    _BottomNavItem(Icons.store_rounded, 'Market', LibertyMarketScreen.new),
    _BottomNavItem(Icons.chat_rounded, '채팅', ChatListScreen.new),
    _BottomNavItem(Icons.groups_rounded, '단톡방', ChatListScreen.new),
  ];

  // Screens for IndexedStack
  List<Widget> get _navScreens =>
      _navItems.where((item) => item.screen != null).map((item) => item.screen!()).toList();

  /// Handle drawer item selection by pushing named routes
  void _onDrawerItemSelected(int drawerIndex, String? routeName) {
    Navigator.of(context).pop();
    if (routeName != null) {
      Navigator.of(context).pushNamed(routeName);
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openVoiceChat() {
    Navigator.of(context).pushNamed('/hyperspace/chat');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.78,
        elevation: 0,
        child: DADADrawer(
          currentIndex: _currentIndex,
          onItemSelected: _onDrawerItemSelected,
        ),
      ),
      body: IndexedStack(
        index: _currentIndex < _navScreens.length ? _currentIndex : 0,
        children: _navScreens,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom nav bar
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom > 0 ? 4 : 0,
                ),
                child: Row(
                  children: [
                    // Hamburger menu button
                    _buildMenuButton(inactiveColor),
                    // Core nav items
                    for (int i = 0; i < _navItems.length; i++)
                      Expanded(
                        child: _navItemWidget(i, activeColor, inactiveColor),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Floating voice button (center, above the nav bar)
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _openVoiceChat,
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        activeColor,
                        activeColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, color: Colors.white, size: 22),
                      SizedBox(height: 1),
                      Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(Color inactiveColor) {
    return GestureDetector(
      onTap: _openDrawer,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Icon(Icons.menu_rounded, color: inactiveColor, size: 24),
        ),
      ),
    );
  }

  Widget _navItemWidget(int index, Color activeColor, Color inactiveColor) {
    if (index >= _navItems.length) return const SizedBox.shrink();
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (item.routeName != null) {
          Navigator.of(context).pushNamed(item.routeName!);
          return;
        }
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isActive ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final Widget Function()? screen;
  final String? routeName;

  const _BottomNavItem(this.icon, this.label, this.screen, {this.routeName});
}
