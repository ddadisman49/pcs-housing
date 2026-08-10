import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcs_housing/features/auth/login_screen.dart';

void main() {
  testWidgets('PCS Housing login screen displays correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(
      find.text('New to PCS Housing? Create an account'),
      findsOneWidget,
    );
  });
}