import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'screens/habit_list_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'screens/add_edit_habit_screen.dart';

final themeService = ThemeService();
final habitRefreshNotifier = ValueNotifier<int>(
  0,
); // naik setiap ada perubahan habit
const String kUserName = 'Rozin';

class AppColors {
  static const background = Color(0xFFF0EFE7);
  static const black = Color(0xFF0D0D0D);
  static const white = Colors.white;
  static const primary = Color(0xFF5B6CF8); // biru ungu
  static const green = Color(0xFFB8F068); // lime green
  static const salmon = Color(0xFFFFCDB8);
  static const lavender = Color(0xFFD4D0F5);
  static const darkCard = Color(0xFF1A1A1A);

  // warna card habit bergilir
  static const List<Color> habitCards = [
    Color(0xFF5B6CF8), // biru
    Color(0xFFB8F068), // lime
    Color(0xFFFFCDB8), // salmon
    Color(0xFFD4D0F5), // lavender
  ];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await themeService.loadTheme();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.black,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppColors.black,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.black, width: 2),
          ),
          elevation: 4,
          shadowColor: AppColors.black,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.black.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) => MaterialApp(
        title: 'Daily Habit Tracker',
        debugShowCheckedModeBanner: false,
        themeMode: themeService.themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [DashboardScreen(), HabitListScreen()];

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(32, 10, 32, 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.black.withOpacity(0.08), width: 1),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ikon Dashboard
              _navIcon(index: 0, icon: Icons.home_rounded),

              // tombol + tengah
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditHabitScreen(),
                    ),
                  );
                  setState(() {});
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // ikon Habits
              _navIcon(index: 1, icon: Icons.task_alt_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon({required int index, required IconData icon}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                ],
              )
            : null,
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? AppColors.black : Colors.grey.shade500,
        ),
      ),
    );
  }
}
