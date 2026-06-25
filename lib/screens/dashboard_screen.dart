import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../services/quote_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DBHelper _dbHelper = DBHelper();
  final QuoteService _quoteService = QuoteService();

  List<HabitModel> _habits = [];
  List<HabitLogModel> _todayLogs = [];
  QuoteModel? _quote;
  bool _loadingQuote = true;

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
  }

  int get _completedToday => _todayLogs.where((l) => l.isCompleted).length;

  double get _percentage {
    if (_habits.isEmpty) return 0;
    return (_completedToday / _habits.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuoteCard(scheme),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Habit Aktif',
                    value: '${_habits.length}',
                    color: const Color(0xFF5B5FEF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Selesai Hari Ini',
                    value: '$_completedToday',
                    color: const Color(0xFF22A06B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPercentageCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withOpacity(0.95),
            scheme.primary.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: _loadingQuote
          ? const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : _quote == null
          ? Row(
              children: const [
                Icon(Icons.wifi_off_rounded, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  'Kutipan tidak tersedia',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white70,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  _quote!.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '— ${_quote!.author}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageCard() {
    const color = Color(0xFFE8902E);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pencapaian Harian',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
              const Spacer(),
              Text(
                '${_percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _percentage / 100),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: color.withOpacity(0.15),
                  color: color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
