import 'package:flutter/material.dart';

class HabitModel {
  final int? id;
  final String name;
  final String
  description; // deskripsi singkat habit, misal "Baca minimal 20 halaman"
  final int? iconCode;
  final DateTime createdAt;
  final int targetPerWeek;
  final int? reminderHour;
  final int? reminderMinute;

  HabitModel({
    this.id,
    required this.name,
    this.description = '',
    this.iconCode,
    required this.createdAt,
    this.targetPerWeek = 7,
    this.reminderHour,
    this.reminderMinute,
  });

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  String get reminderLabel {
    if (!hasReminder) return '';
    final h = reminderHour!.toString().padLeft(2, '0');
    final m = reminderMinute!.toString().padLeft(2, '0');
    return '$h:$m';
  }

  IconData get icon => iconCode != null
      ? IconData(iconCode!, fontFamily: 'MaterialIcons')
      : Icons.task_alt_rounded;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_code': iconCode,
      'created_at': createdAt.toIso8601String(),
      'target_per_week': targetPerWeek,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      iconCode: map['icon_code'],
      createdAt: DateTime.parse(map['created_at']),
      targetPerWeek: map['target_per_week'] ?? 7,
      reminderHour: map['reminder_hour'],
      reminderMinute: map['reminder_minute'],
    );
  }
}
