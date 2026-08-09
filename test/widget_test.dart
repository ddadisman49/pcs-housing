import 'package:flutter_test/flutter_test.dart';
import 'package:pcs_housing/app.dart';

void main() {
  testWidgets('PCS Housing app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const PCSHousingApp());
    await tester.pumpAndSettle();

    expect(find.text('Plan your next PCS'), findsOneWidget);
    expect(find.text('Find Housing'), findsOneWidget);
    expect(find.text('BAH Calculator'), findsOneWidget);
    expect(find.text('AI PCS Assistant'), findsOneWidget);
    expect(find.text('Saved Homes'), findsOneWidget);
  });
}