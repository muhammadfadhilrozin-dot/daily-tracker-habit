import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/habit_model.dart';
import '../services/notification_service.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final HabitModel habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final DBHelper _dbHelper = DBHelper();

  late HabitModel _habit;
  int _streak = 0;
  int _weeklyDone = 0;
  Map<String, bool> _completionMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final streak = await _dbHelper.getStreak(_habit.id!);
    final weekly = await _dbHelper.getCompletionsThisWeek(_habit.id!);
    final map = await _dbHelper.getCompletionMapForHabit(_habit.id!);
    setState(() {
      _streak = streak;
      _weeklyDone = weekly;
      _completionMap = map;
      _loading = false;
    });
  }

  Future<void> _editHabit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditHabitScreen(habit: _habit)),
    );
    if (updated == true && mounted) {
      // Beri tahu halaman list untuk refresh juga
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteHabit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus habit?'),
        content: Text(
          '"${_habit.name}" akan dihapus beserta seluruh riwayatnya. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteHabit(_habit.id!);
      await NotificationService().cancelHabitReminder(_habit.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _buildLast35Days() {
    final today = DateTime.now();
    return List.generate(35, (i) => today.subtract(Duration(days: 34 - i)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final days = _buildLast35Days();

    return Scaffold(
      appBar: AppBar(
        title: Text(_habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _editHabit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: _deleteHabit,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStreakCard(primary),
                  const SizedBox(height: 28),
                  const Text(
                    '35 Hari Terakhir',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kotak terisi = habit ini selesai pada tanggal tersebut',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 14),
                  _buildHeatmap(days, primary),
                  const SizedBox(height: 24),
                  _buildLegend(primary),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakCard(Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF728AED), const Color(0xFF3039C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_habit.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_streak hari beruntun',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _streak == 0
                      ? 'Selesaikan hari ini untuk mulai streak baru'
                      : 'Pertahankan terus, jangan sampai putus!',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                if (_habit.targetPerWeek < 7) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Minggu ini: $_weeklyDone/${_habit.targetPerWeek}x target',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(List<DateTime> days, Color primary) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((date) {
        final key = DateFormat('yyyy-MM-dd').format(date);
        final isCompleted = _completionMap[key] ?? false;
        final isToday = _isSameDay(date, DateTime.now());

        return Tooltip(
          message: DateFormat('d MMM yyyy', 'id_ID').format(date),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isCompleted ? primary : primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: isToday ? Border.all(color: primary, width: 2) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(Color primary) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        const Text('Selesai', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 16),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        const Text('Belum/lewat', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
