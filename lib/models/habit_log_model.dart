class HabitLogModel {
  final int? id;
  final int habitId;
  final String date; // format yyyy-MM-dd
  final bool isCompleted;

  HabitLogModel({
    this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory HabitLogModel.fromMap(Map<String, dynamic> map) {
    return HabitLogModel(
      id: map['id'],
      habitId: map['habit_id'],
      date: map['date'],
      isCompleted: map['is_completed'] == 1,
    );
  }
}
