class Meal {
  final String date;
  final int breakfast;
  final int lunch;
  final int dinner;

  Meal({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  int get total => breakfast + lunch + dinner;

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }

  factory Meal.fromMap(Map<dynamic, dynamic> map) {
    return Meal(
      date: map['date'] ?? '',
      breakfast: map['breakfast'] ?? 0,
      lunch: map['lunch'] ?? 0,
      dinner: map['dinner'] ?? 0,
    );
  }
}