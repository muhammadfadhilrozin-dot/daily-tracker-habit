import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/habit_model.dart';
import '../main.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<HabitModel> _habits = [];
  Map<int, bool> _completionMap = {};
  Map<int, int> _streakMap = {};
  Map<int, int> _weeklyMap = {};

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await _dbHelper.getHabits();
    final logs = await _dbHelper.getLogsForDate(_dbHelper.todayKey);
    final map = <int, bool>{};
    for (final log in logs) {
      map[log.habitId] = log.isCompleted;
    }
    final streaks = <int, int>{};
    final weekly = <int, int>{};
    for (final h in habits) {
      streaks[h.id!] = await _dbHelper.getStreak(h.id!);
      weekly[h.id!] = await _dbHelper.getCompletionsThisWeek(h.id!);
    }
    setState(() {
      _habits = habits;
      _completionMap = map;
      _streakMap = streaks;
      _weeklyMap = weekly;
    });
  }

  Future<void> _toggleCompletion(int habitId, bool current) async {
    await _dbHelper.toggleHabitCompletion(
      habitId,
      _dbHelper.todayKey,
      !current,
    );
    habitRefreshNotifier.value++; // beritahu Dashboard untuk reload
    _loadHabits();
  }

  Future<void> _deleteHabit(HabitModel habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        title: const Text(
          'Hapus habit?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('"${habit.name}" akan dihapus beserta riwayatnya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _dbHelper.deleteHabit(habit.id!);
      _loadHabits();
    }
  }

  int get _completedToday => _completionMap.values.where((v) => v).length;

  // Warna accent progress bar tiap card
  static const List<Color> _progressColors = [
    Color(0xFF3345E8),
    Color(0xFF7AB830),
    Color(0xFFCC7A5A),
    Color(0xFF8A85D0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadHabits,
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        themeService.toggleTheme(!themeService.isDarkMode),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.salmon,
                        border: Border.all(color: AppColors.black, width: 2),
                      ),
                      child: Icon(
                        themeService.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Habit Saya',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    // Tombol lonceng: tampilkan info reminder yang aktif
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _habits.where((h) => h.hasReminder).isEmpty
                              ? 'Belum ada reminder yang diatur'
                              : 'Reminder aktif: ${_habits.where((h) => h.hasReminder).map((h) => "${h.name} (${h.reminderLabel})").join(", ")}',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.black.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.notifications_outlined, size: 20),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsBanner(),
                  const SizedBox(height: 20),
                  _buildDayStrip(),
                  const SizedBox(height: 24),
                  _buildHabitGrid(),
                  const SizedBox(height: 24),
                  _buildWeeklyProgress(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Banner ──────────────────────────────────────────────
  Widget _buildStatsBanner() {
    final total = _habits.length;
    final done = _completedToday;
    final pct = total == 0 ? 0 : (done / total * 100).round();

    String title;
    if (total == 0)
      title = 'Belum ada habit!';
    else if (pct == 100)
      title = '🎉 Semua Selesai!';
    else if (pct >= 50)
      title = 'Hampir Selesai!';
    else
      title = 'Ayo Semangat!';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATISTIK HARI INI',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$done/$total Tugas',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Day Strip ─────────────────────────────────────────────────
  Widget _buildDayStrip() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return SizedBox(
      height: 72,
      child: FutureBuilder<List<bool>>(
        future: _loadDayCompletions(monday),
        builder: (context, snap) {
          final completions = snap.data ?? List.filled(7, false);
          return ListView.separated(
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
              final isDone =
                  completions[i]; // centang hanya kalau benar-benar ada yang selesai

              return Container(
                width: 58,
                decoration: BoxDecoration(
                  color: isToday ? AppColors.black : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday
                        ? AppColors.black
                        : AppColors.black.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: isToday
                      ? const [
                          BoxShadow(
                            color: AppColors.black,
                            offset: Offset(2, 2),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Teks hari & tanggal (muncul kalau hari ini atau belum ada centang)
                    if (!isDone || isToday)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isToday ? Colors.white : AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    // Centang hijau — hanya hari lewat yang benar-benar ada habit selesai
                    if (isDone && isPast)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.black,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.black,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Cek tiap hari dalam seminggu ini: apakah ada minimal 1 habit yang selesai?
  Future<List<bool>> _loadDayCompletions(DateTime monday) async {
    final result = <bool>[];
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final logs = await _dbHelper.getLogsForDate(key);
      result.add(logs.any((l) => l.isCompleted));
    }
    return result;
  }

  // ─── Habit Grid ────────────────────────────────────────────────
  Widget _buildHabitGrid() {
    // Pasang "Tambah Baru" card di akhir grid
    final itemCount = _habits.length + 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Card "Tambah Baru" di akhir
        if (index == _habits.length) return _buildAddCard();

        final habit = _habits[index];
        final isCompleted = _completionMap[habit.id] ?? false;
        final streak = _streakMap[habit.id] ?? 0;
        final weekly = _weeklyMap[habit.id] ?? 0;
        final isFlexible = habit.targetPerWeek < 7;
        final bg = AppColors.habitCards[index % AppColors.habitCards.length];
        final progressColor = _progressColors[index % _progressColors.length];
        final progressVal = isFlexible
            ? weekly / habit.targetPerWeek
            : (streak > 0 ? (streak % 7) / 7.0 : 0.0);

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HabitDetailScreen(habit: habit),
              ),
            );
            _loadHabits();
          },
          onLongPress: () => _deleteHabit(habit),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris atas: ikon + centang
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ikon habit
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 1.5),
                      ),
                      child: Icon(habit.icon, size: 22, color: AppColors.black),
                    ),
                    // Toggle centang
                    GestureDetector(
                      onTap: () => _toggleCompletion(habit.id!, isCompleted),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.green
                              : Colors.transparent,
                          border: Border.all(
                            color: AppColors.black,
                            width: 2,
                            style: isCompleted
                                ? BorderStyle.solid
                                : BorderStyle.solid,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 17,
                                color: AppColors.black,
                              )
                            : CustomPaint(painter: _DashedCirclePainter()),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Streak
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      isFlexible
                          ? '$weekly/${habit.targetPerWeek} Hari'
                          : '$streak Hari',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Nama habit
                Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressVal.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.black.withOpacity(0.15),
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Card "Tambah Baru" dengan border dashed
  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        );
        _loadHabits();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.black, width: 2),
                  ),
                  child: const Icon(Icons.add_rounded, size: 26),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tambah Baru',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Progres Mingguan ──────────────────────────────────────────
  Widget _buildWeeklyProgress() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const dayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    // Hitung persentase per hari berdasarkan log semua habit
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                'Progres Mingguan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                'Lihat Semua',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: FutureBuilder<List<double>>(
              future: _loadWeeklyData(monday),
              builder: (context, snap) {
                final data = snap.data ?? List.filled(7, 0.0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final date = monday.add(Duration(days: i));
                    final isToday =
                        date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day;
                    final val = data[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 28,
                              height: val > 0 ? (val * 60).clamp(6.0, 60.0) : 4,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.primary
                                    : val > 0
                                    ? AppColors.green
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(6),
                                border: val > 0
                                    ? Border.all(
                                        color: AppColors.black,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<double>> _loadWeeklyData(DateTime monday) async {
    if (_habits.isEmpty) return List.filled(7, 0.0);
    final result = <double>[];
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final logs = await _dbHelper.getLogsForDate(key);
      final done = logs.where((l) => l.isCompleted).length;
      result.add(done / _habits.length);
    }
    return result;
  }
}

// ─── Custom Painters ───────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.black.withOpacity(0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final radius = Radius.circular(22);
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double len = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, len), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.black.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashCount = 10;
    const angle = 3.14159 * 2 / dashCount;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    for (int i = 0; i < dashCount; i++) {
      final start = i * angle;
      final end = start + angle * 0.55;
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawArc(rect, start, end - start, false, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
