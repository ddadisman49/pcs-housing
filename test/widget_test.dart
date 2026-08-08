import 'package:flutter_test/flutter_test.dart';
import 'package:pcs_housing/app.dart';

void main() {
  testWidgets('PCS Housing app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const PCSHousingApp());

    expect(find.text('Welcome to PCS Housing'), findsOneWidget);
  });
}