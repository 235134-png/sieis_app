import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sieis_frontend/main.dart';

void main() {
  testWidgets('SIEIS opens on login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SieisApp());

    expect(find.text('Welcome to SIEIS'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('Can toggle to Sign Up screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SieisApp());

    final signUpLink = find.text('Sign Up');
    expect(signUpLink, findsOneWidget);

    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
  });
}
