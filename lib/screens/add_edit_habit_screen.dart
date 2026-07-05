import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/habit_model.dart';
import '../services/notification_service.dart';
import '../utils/habit_icons.dart';
import '../main.dart';

class AddEditHabitScreen extends StatefulWidget {
  final HabitModel? habit;
  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late int _selectedIconCode;
  late int _targetPerWeek;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
    _selectedIconCode =
        widget.habit?.iconCode ?? habitIconOptions.first.codePoint;
    _targetPerWeek = widget.habit?.targetPerWeek ?? 7;
    if (widget.habit?.hasReminder == true) {
      _reminderTime = TimeOfDay(
        hour: widget.habit!.reminderHour!,
        minute: widget.habit!.reminderMinute!,
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    int? habitId = widget.habit?.id;

    if (widget.habit == null) {
      habitId = await _dbHelper.insertHabit(
        HabitModel(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          iconCode: _selectedIconCode,
          createdAt: DateTime.now(),
          targetPerWeek: _targetPerWeek,
          reminderHour: _reminderTime?.hour,
          reminderMinute: _reminderTime?.minute,
        ),
      );
    } else {
      await _dbHelper.updateHabit(
        HabitModel(
          id: widget.habit!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          iconCode: _selectedIconCode,
          createdAt: widget.habit!.createdAt,
          targetPerWeek: _targetPerWeek,
          reminderHour: _reminderTime?.hour,
          reminderMinute: _reminderTime?.minute,
        ),
      );
    }

    if (habitId != null) {
      if (_reminderTime != null) {
        await NotificationService().scheduleHabitReminder(
          habitId: habitId,
          habitName: _nameController.text.trim(),
          hour: _reminderTime!.hour,
          minute: _reminderTime!.minute,
        );
      } else {
        await NotificationService().cancelHabitReminder(habitId);
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Tambah Habit' : 'Ubah Habit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _label('Nama Habit'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Misal: Membaca Buku',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 18),
              _label('Deskripsi (opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  hintText: 'Misal: Baca minimal 20 halaman',
                ),
              ),
              const SizedBox(height: 24),
              _label('Pilih Ikon'),
              const SizedBox(height: 12),
              _buildIconPicker(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _label('Target per Minggu')),
                  _badge(
                    _targetPerWeek == 7
                        ? 'Setiap hari'
                        : '$_targetPerWeek hari/minggu',
                    AppColors.primary,
                    Colors.white,
                  ),
                ],
              ),
              Slider(
                value: _targetPerWeek.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_targetPerWeek',
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _targetPerWeek = v.round()),
              ),
              const SizedBox(height: 18),
              _label('Pengingat Harian'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _reminderTime ?? const TimeOfDay(hour: 7, minute: 0),
                  );
                  if (picked != null) setState(() => _reminderTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.black.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _reminderTime == null
                              ? 'Tanpa pengingat'
                              : 'Diingatkan jam ${_reminderTime!.format(context)}',
                        ),
                      ),
                      if (_reminderTime != null)
                        GestureDetector(
                          onTap: () => setState(() => _reminderTime = null),
                          child: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
  );

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: habitIconOptions.map((icon) {
        final isSelected = icon.codePoint == _selectedIconCode;
        return GestureDetector(
          onTap: () => setState(() => _selectedIconCode = icon.codePoint),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.black : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.black, width: 2),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.black,
            ),
          ),
        );
      }).toList(),
    );
  }
}
