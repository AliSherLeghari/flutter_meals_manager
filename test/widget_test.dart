import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_meal_manager/main.dart';

void main() {
  testWidgets('Meals Manager loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MealsManagerApp());

    expect(find.text('Add Meals of the Day'), findsOneWidget);
  });
}