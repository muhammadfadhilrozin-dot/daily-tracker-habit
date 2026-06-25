import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/habit_model.dart';
import 'add_edit_habit_screen.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<HabitModel> _habits = [];
  Map<int, bool> _completionMap = {};

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

    setState(() {
      _habits = habits;
      _completionMap = map;
    });
  }

  Future<void> _toggleCompletion(int habitId, bool current) async {
    await _dbHelper.toggleHabitCompletion(
      habitId,
      _dbHelper.todayKey,
      !current,
    );
    _loadHabits();
  }

  Future<void> _deleteHabit(int id) async {
    await _dbHelper.deleteHabit(id);
    _loadHabits();
  }

  void _navigateToForm({HabitModel? habit}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditHabitScreen(habit: habit)),
    );
    _loadHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Saya')),
      body: _habits.isEmpty ? _buildEmptyState() : _buildHabitList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Habit Baru'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.self_improvement_rounded,
                size: 48,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada habit',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai bangun kebiasaan baikmu hari ini dengan menambahkan habit pertama.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitList() {
    final primary = Theme.of(context).colorScheme.primary;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        final isCompleted = _completionMap[habit.id] ?? false;

        return Dismissible(
          key: ValueKey(habit.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hapus habit?'),
                content: Text(
                  '"${habit.name}" akan dihapus beserta riwayatnya.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => _deleteHabit(habit.id!),
          child: GestureDetector(
            onTap: () => _navigateToForm(habit: habit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCompleted ? primary.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCompleted
                      ? primary.withOpacity(0.3)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(habit.icon, color: primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCompleted ? 'Selesai hari ini' : 'Belum selesai',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.green.shade600
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleCompletion(habit.id!, isCompleted),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? Colors.green : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? Colors.green
                              : Colors.grey.shade400,
                          width: 2,
                        ),
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
            ),
          ),
        );
      },
    );
  }
}
