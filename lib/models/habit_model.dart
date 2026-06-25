import 'package:flutter/material.dart';

class HabitModel {
  final int? id;
  final String name;
  final int? iconCode;
  final DateTime createdAt;

  HabitModel({
    this.id,
    required this.name,
    this.iconCode,
    required this.createdAt,
  });

  /// Ikon habit, fallback ke ikon default kalau belum pernah dipilih
  /// (misal habit lama sebelum fitur ikon ditambahkan).
  IconData get icon => iconCode != null
      ? IconData(iconCode!, fontFamily: 'MaterialIcons')
      : Icons.task_alt_rounded;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'],
      name: map['name'],
      iconCode: map['icon_code'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
