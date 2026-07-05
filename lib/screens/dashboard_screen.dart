import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../services/quote_service.dart';
import '../services/weather_service.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DBHelper _dbHelper = DBHelper();
  final QuoteService _quoteService = QuoteService();
  final WeatherService _weatherService = WeatherService();

  List<HabitModel> _habits = [];
  List<HabitLogModel> _todayLogs = [];
  QuoteModel? _quote;
  WeatherModel? _weather;
  bool _loadingQuote = true;
  bool _loadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final habits = await _dbHelper.getHabits();
    final logs = await _dbHelper.getLogsForDate(_dbHelper.todayKey);
    setState(() {
      _habits = habits;
      _todayLogs = logs;
    });

    try {
      final quote = await _quoteService.getRandomQuote();
      setState(() {
        _quote = quote;
        _loadingQuote = false;
      });
    } catch (_) {
      setState(() => _loadingQuote = false);
    }

    try {
      final weather = await _weatherService.getCurrentWeather();
      setState(() {
        _weather = weather;
        _loadingWeather = false;
      });
    } catch (_) {
      setState(() => _loadingWeather = false);
    }
  }

  int get _completedToday => _todayLogs.where((l) => l.isCompleted).length;

  double get _percentage {
    if (_habits.isEmpty) return 0;
    return (_completedToday / _habits.length) * 100;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  // Warna bergilir untuk card habit di list dashboard
  static const List<Color> _habitCardColors = [
    Color(0xFFFFCDB8), // salmon
    Color(0xFFD4D0F5), // lavender
    Color(0xFFC5F26A), // hijau
    Color(0xFFFFE8A0), // kuning
    Color(0xFFB8E3D4), // teal muda
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_greeting, $kUserName! 👋',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.black.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      themeService.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 20,
                    ),
                    onPressed: () =>
                        themeService.toggleTheme(!themeService.isDarkMode),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroBanner(),
                  const SizedBox(height: 20),
                  _buildDayStrip(),
                  const SizedBox(height: 20),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildStatRow(),
                  const SizedBox(height: 16),
                  _buildWeatherQuoteCard(),
                  const SizedBox(height: 24),
                  _buildHabitListSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Siap untuk hari ini?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _habits.isEmpty
                      ? 'Belum ada habit. Tambahkan sekarang!'
                      : 'Kamu punya ${_habits.length} habit yang perlu diselesaikan hari ini!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF3CB371),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.black, width: 2),
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const dayLabels = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = monday.add(Duration(days: i));
          final isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isPast = date.isBefore(
            DateTime(today.year, today.month, today.day),
          );

          Color bgColor;
          Color textColor;
          BorderSide borderSide;

          if (isToday) {
            bgColor = AppColors.black;
            textColor = Colors.white;
            borderSide = BorderSide.none;
          } else if (isPast) {
            bgColor = Colors.white;
            textColor = AppColors.black;
            borderSide = BorderSide(
              color: AppColors.black.withOpacity(0.3),
              width: 1.5,
            );
          } else {
            bgColor = Colors.white;
            textColor = Colors.grey;
            borderSide = BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1.5,
            );
          }

          return Container(
            width: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.fromBorderSide(borderSide),
              boxShadow: isToday
                  ? const [
                      BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayLabels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres Harian',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                '${_percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.black.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _percentage / 100),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _percentage == 0
                ? 'Ayo mulai selesaikan habit hari ini!'
                : _percentage >= 100
                ? '🎉 Semua habit selesai! Luar biasa!'
                : 'Sedikit lagi sampai target! Kamu hebat!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.bolt_rounded,
            label: 'Habit Aktif',
            value: '${_habits.length}'.padLeft(2, '0'),
            bg: AppColors.salmon,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Selesai',
            value: '$_completedToday'.padLeft(2, '0'),
            bg: AppColors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.black, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_weather != null)
                  Text(
                    '${_weather!.temperature.toStringAsFixed(0)}°C di ${_weather!.cityName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )
                else if (_loadingWeather)
                  const Text(
                    'Memuat cuaca...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 6),
                if (!_loadingQuote && _quote != null)
                  Text(
                    '"${_quote!.content}"',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  const Text(
                    'Memuat kutipan...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitListSection() {
    if (_habits.isEmpty) return const SizedBox.shrink();

    final todayMap = <int, bool>{};
    for (final log in _todayLogs) {
      todayMap[log.habitId] = log.isCompleted;
    }

    // Tampilkan max 5 habit di dashboard
    final preview = _habits.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Habit Hari Ini',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Lihat Semua (${_habits.length})',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...preview.asMap().entries.map((entry) {
          final i = entry.key;
          final habit = entry.value;
          final isCompleted = todayMap[habit.id] ?? false;
          final bg = _habitCardColors[i % _habitCardColors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.black, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.black, width: 1.5),
                  ),
                  child: Icon(habit.icon, size: 22, color: AppColors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.black,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (habit.description.isNotEmpty)
                        Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await _dbHelper.toggleHabitCompletion(
                      habit.id!,
                      _dbHelper.todayKey,
                      !isCompleted,
                    );
                    _loadData();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? AppColors.black : Colors.white,
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
