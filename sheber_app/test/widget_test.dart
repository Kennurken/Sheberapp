import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheber_app/main.dart';
import 'package:sheber_app/providers/app_state.dart';
import 'package:sheber_app/screens/main_shell.dart';

void main() {
  testWidgets('App builds and shows main shell', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(SheberApp(appState: appState));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
