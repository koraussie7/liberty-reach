import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/chat_list_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/loops_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const LibertyReachApp());
}

class LibertyReachApp extends StatelessWidget {
  const LibertyReachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liberty Reach',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MainScreen(),
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFFF02C56);
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF020617),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        surface: Color(0xFF0F172A),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFFF02C56).withValues(alpha: 0.2),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
        ),
      ),
      useMaterial3: true,
    );
  }

}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChatListScreen(),
    LoopsScreen(),
    LeaderboardScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFFF02C56).withValues(alpha: 0.2),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.chat, color: Color(0xFFF02C56)),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.local_fire_department, color: Color(0xFFF02C56)),
            label: 'Loops',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.emoji_events, color: Color(0xFFF02C56)),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.people, color: Color(0xFFF02C56)),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.settings, color: Color(0xFFF02C56)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
