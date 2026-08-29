import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'meal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('meals');

  runApp(const MealsManagerApp());
}

class MealsManagerApp extends StatelessWidget {
  const MealsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meals Manager',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        fontFamily: 'Arial',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final screens = [
      AddMealsScreen(
        selectedDate: selectedDate,
        onDateChanged: (date) {
          setState(() {
            selectedDate = date;
          });
        },
      ),
      DailySummaryScreen(
        selectedDate: selectedDate,
        onDateChanged: (date) {
          setState(() {
            selectedDate = date;
          });
        },
      ),
      CalendarScreen(
        selectedDate: selectedDate,
        onDateChanged: (date) {
          setState(() {
            selectedDate = date;
          });
        },
      ),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Add Meals',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
String formatDate(DateTime date) {
  return '${date.day} ${monthName(date.month)} ${date.year}';
}

String storageDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month - 1];
}

class AddMealsScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const AddMealsScreen({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<AddMealsScreen> createState() => _AddMealsScreenState();
}

class _AddMealsScreenState extends State<AddMealsScreen> {
  final breakfastController = TextEditingController();
  final lunchController = TextEditingController();
  final dinnerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMeal();
  }

  @override
  void didUpdateWidget(covariant AddMealsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedDate != widget.selectedDate) {
      loadMeal();
    }
  }

bool get hasExistingMeal {
  final box = Hive.box('meals');

  return box.get(
        storageDate(widget.selectedDate),
      ) !=
      null;
}
  void loadMeal() {
    final box = Hive.box('meals');
    final data = box.get(storageDate(widget.selectedDate));

    if (data != null) {
      final meal = Meal.fromMap(data);

      breakfastController.text = meal.breakfast.toString();
      lunchController.text = meal.lunch.toString();
      dinnerController.text = meal.dinner.toString();
    } else {
      breakfastController.text = '';
      lunchController.text = '';
      dinnerController.text = '';
    }
  }

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      widget.onDateChanged(date);
    }
  }

  int getNumber(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 0;
  }

  Future<void> saveMeal() async {
  final breakfast = getNumber(breakfastController);
  final lunch = getNumber(lunchController);
  final dinner = getNumber(dinnerController);

  if (breakfast == 0 &&
      lunch == 0 &&
      dinner == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please enter at least one meal quantity.',
        ),
      ),
    );

    return;
  }

  if (hasExistingMeal) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Entry already exists. Use Update instead.',
        ),
      ),
    );

    return;
  }

  final meal = Meal(
    date: storageDate(widget.selectedDate),
    breakfast: breakfast,
    lunch: lunch,
    dinner: dinner,
  );

  final box = Hive.box('meals');

  await box.put(
    storageDate(widget.selectedDate),
    meal.toMap(),
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Meals saved successfully'),
    ),
  );

  setState(() {});
}

Future<void> updateMeal() async {
  if (!hasExistingMeal) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No existing entry to update.',
        ),
      ),
    );

    return;
  }

  final breakfast = getNumber(breakfastController);
  final lunch = getNumber(lunchController);
  final dinner = getNumber(dinnerController);

  if (breakfast == 0 &&
      lunch == 0 &&
      dinner == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please enter at least one meal quantity.',
        ),
      ),
    );

    return;
  }

  final updatedMeal = Meal(
    date: storageDate(widget.selectedDate),
    breakfast: breakfast,
    lunch: lunch,
    dinner: dinner,
  );

  final box = Hive.box('meals');

  await box.put(
    storageDate(widget.selectedDate),
    updatedMeal.toMap(),
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Meals updated successfully'),
    ),
  );

  setState(() {});
}
  Future<void> deleteMeal() async {
  final box = Hive.box('meals');

  final key = storageDate(widget.selectedDate);

  // Check whether a record actually exists.
  final existingMeal = box.get(key);

  if (existingMeal == null) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No meal record found for this date.'),
      ),
    );

    return;
  }

  // Delete the existing record.
  await box.delete(key);

  breakfastController.clear();
  lunchController.clear();
  dinnerController.clear();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Meals deleted successfully'),
    ),
  );

  setState(() {});
}

  @override
  void dispose() {
    breakfastController.dispose();
    lunchController.dispose();
    dinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Meals of the Day',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateSelector(
                  widget.selectedDate,
                  selectDate,
                ),

                const SizedBox(height: 20),

                mealInputCard(
                  title: 'Breakfast',
                  icon: Icons.free_breakfast,
                  controller: breakfastController,
                ),

                const SizedBox(height: 16),

                mealInputCard(
                  title: 'Lunch',
                  icon: Icons.lunch_dining,
                  controller: lunchController,
                ),

                const SizedBox(height: 16),

                mealInputCard(
                  title: 'Dinner',
                  icon: Icons.dinner_dining,
                  controller: dinnerController,
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: actionButton(
                        label: 'Save',
                        icon: Icons.save,
                        color: Colors.green,
                        onPressed: saveMeal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: actionButton(
                        label: 'Update',
                        icon: Icons.edit,
                        color: Colors.blue,
                        onPressed: updateMeal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: actionButton(
                        label: 'Delete',
                        icon: Icons.delete,
                        color: Colors.red,
                        onPressed: deleteMeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget dateSelector(
  DateTime date,
  VoidCallback onTap,
) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
           color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatDate(date),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    ),
  );
}

Widget mealInputCard({
  required String title,
  required IconData icon,
  required TextEditingController controller,
}) {
  return Card(
    elevation: 3,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 34,
              color: Colors.blue,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Number of Persons',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
Widget actionButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}
class DailySummaryScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const DailySummaryScreen({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  Meal? get meal {
    final box = Hive.box('meals');
    final data = box.get(storageDate(widget.selectedDate));

    if (data == null) return null;

    return Meal.fromMap(data);
  }

  Future<void> selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      widget.onDateChanged(date);
      setState(() {});
    }
  }

 Future<void> deleteMealType(String type) async {
  final currentMeal = meal;

  if (currentMeal == null) return;

  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
          'Are you sure you want to delete $type?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true) return;

  int breakfast = currentMeal.breakfast;
  int lunch = currentMeal.lunch;
  int dinner = currentMeal.dinner;

  if (type == 'Breakfast') {
    breakfast = 0;
  } else if (type == 'Lunch') {
    lunch = 0;
  } else if (type == 'Dinner') {
    dinner = 0;
  }

  if (breakfast == 0 &&
      lunch == 0 &&
      dinner == 0) {
    await Hive.box('meals').delete(
      storageDate(widget.selectedDate),
    );
  } else {
    final updatedMeal = Meal(
      date: currentMeal.date,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
    );

    await Hive.box('meals').put(
      storageDate(widget.selectedDate),
      updatedMeal.toMap(),
    );
  }

  setState(() {});
}

  void editMeal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMealsScreen(
          selectedDate: widget.selectedDate,
          onDateChanged: widget.onDateChanged,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  Widget summaryCard({
    required String title,
    required IconData icon,
    required int persons,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: Colors.blue,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Total Number of Persons',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    persons.toString(),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: editMeal,
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => deleteMealType(title),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMeal = meal;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Summary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: editMeal,
        icon: const Icon(Icons.add),
        label: const Text('Add New Entry'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateSelector(
                  widget.selectedDate,
                  selectDate,
                ),

                const SizedBox(height: 20),

                summaryCard(
                  title: 'Breakfast',
                  icon: Icons.free_breakfast,
                  persons: currentMeal?.breakfast ?? 0,
                ),

                const SizedBox(height: 16),

                summaryCard(
                  title: 'Lunch',
                  icon: Icons.lunch_dining,
                  persons: currentMeal?.lunch ?? 0,
                ),

                const SizedBox(height: 16),

                summaryCard(
                  title: 'Dinner',
                  icon: Icons.dinner_dining,
                  persons: currentMeal?.dinner ?? 0,
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const CalendarScreen({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime displayedMonth;

  String viewMode = 'Month';

  @override
  void initState() {
    super.initState();

    displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  int getDaysInMonth(DateTime date) {
    return DateTime(
      date.year,
      date.month + 1,
      0,
    ).day;
  }

  int getStartingWeekday(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      1,
    ).weekday;
  }

  int getTotalForDate(DateTime date) {
    final box = Hive.box('meals');
    final data = box.get(storageDate(date));

    if (data == null) return 0;

    final meal = Meal.fromMap(data);

    return meal.total;
  }

  void previousMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + 1,
      );
    });
  }

  void selectDay(DateTime date) {
    widget.onDateChanged(date);
    setState(() {});
  }

  Widget calendarDay({
    required DateTime date,
    required bool isSelected,
    required bool isCurrentMonth,
  }) {
    final total = getTotalForDate(date);

    return InkWell(
      onTap: () => selectDay(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                        ? Colors.black87
                        : Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            if (total > 0)
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget monthCalendar() {
    final daysInMonth = getDaysInMonth(displayedMonth);

    final firstWeekday = getStartingWeekday(displayedMonth);

    final previousMonthDays = firstWeekday - 1;

    final totalCells =
        ((previousMonthDays + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final dayNumber =
            index - previousMonthDays + 1;

        DateTime date;

        if (dayNumber < 1) {
          date = DateTime(
            displayedMonth.year,
            displayedMonth.month,
            dayNumber,
          );
        } else if (dayNumber > daysInMonth) {
          date = DateTime(
            displayedMonth.year,
            displayedMonth.month,
            dayNumber,
          );
        } else {
          date = DateTime(
            displayedMonth.year,
            displayedMonth.month,
            dayNumber,
          );
        }

        final isCurrentMonth =
            date.month == displayedMonth.month;

        final isSelected =
            date.year == widget.selectedDate.year &&
            date.month == widget.selectedDate.month &&
            date.day == widget.selectedDate.day;

        return calendarDay(
          date: date,
          isSelected: isSelected,
          isCurrentMonth: isCurrentMonth,
        );
      },
    );
  }

Widget weekCalendar() {
  final selected = widget.selectedDate;

  // DateTime.weekday:
  // Monday = 1
  // Sunday = 7

  final monday = selected.subtract(
    Duration(days: selected.weekday - 1),
  );

  final weekDays = List.generate(
    7,
    (index) => monday.add(
      Duration(days: index),
    ),
  );

  return Column(
    children: [
      Row(
        children: weekDays.map((date) {
          final isSelected =
              date.year == widget.selectedDate.year &&
              date.month == widget.selectedDate.month &&
              date.day == widget.selectedDate.day;

          final total = getTotalForDate(date);

          return Expanded(
            child: InkWell(
              onTap: () => selectDay(date),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      weekdayName(date.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.green.shade50,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),

      const SizedBox(height: 15),

      Text(
        '${formatDate(weekDays.first)} - '
        '${formatDate(weekDays.last)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    ],
  );
}
String weekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return weekdays[weekday - 1];
}



  @override
  Widget build(BuildContext context) {
    final selectedTotal =
        getTotalForDate(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar View',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Column(
              children: [
                // Week / Month filter
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Week',
                      label: Text('Week View'),
                    ),
                    ButtonSegment(
                      value: 'Month',
                      label: Text('Month View'),
                    ),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      viewMode = selection.first;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Month navigation
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: previousMonth,
                      icon: const Icon(
                        Icons.chevron_left,
                        size: 32,
                      ),
                    ),

                    Text(
                      '${monthName(displayedMonth.month)} '
                      '${displayedMonth.year}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      onPressed: nextMonth,
                      icon: const Icon(
                        Icons.chevron_right,
                        size: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Weekday names
                Row(
                  children: const [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ].map(
                    (day) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),

                const SizedBox(height: 8),

               if (viewMode == 'Month')
  monthCalendar()
else
  weekCalendar(),

                const SizedBox(height: 20),

                // Selected date summary
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups,
                          size: 42,
                          color: Colors.green,
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Date',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                formatDate(
                                  widget.selectedDate,
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          children: [
                            const Text(
                              'Total Persons',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$selectedTotal',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}