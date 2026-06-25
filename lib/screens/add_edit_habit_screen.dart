import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/habit_model.dart';
import '../utils/habit_icons.dart';

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
  late int _selectedIconCode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _selectedIconCode =
        widget.habit?.iconCode ?? habitIconOptions.first.codePoint;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.habit == null) {
      final habit = HabitModel(
        name: _nameController.text.trim(),
        iconCode: _selectedIconCode,
        createdAt: DateTime.now(),
      );
      await _dbHelper.insertHabit(habit);
    } else {
      final habit = HabitModel(
        id: widget.habit!.id,
        name: _nameController.text.trim(),
        iconCode: _selectedIconCode,
        createdAt: widget.habit!.createdAt,
      );
      await _dbHelper.updateHabit(habit);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Habit',
                  hintText: 'Contoh: Minum air, Olahraga, Membaca buku',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Pilih Ikon',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: habitIconOptions.map((icon) {
                  final isSelected = icon.codePoint == _selectedIconCode;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIconCode = icon.codePoint),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? primary : primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : primary,
                      ),
                    ),
                  );
                }).toList(),
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
}
