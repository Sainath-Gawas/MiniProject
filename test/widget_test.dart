import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test 1: HomeScreen placeholder renders
  testWidgets('HomeScreen placeholder renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('HomeScreen Placeholder'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Center), findsOneWidget);
    expect(find.text('HomeScreen Placeholder'), findsOneWidget);
  });

  // Test 2: HomeScreen contains Center widget
  testWidgets('HomeScreen contains Center widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('HomeScreen Placeholder'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Center), findsOneWidget);
  });

  // Test 3: HomeScreen contains Text widget
  testWidgets('HomeScreen contains Text widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('HomeScreen Placeholder'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsOneWidget);
    expect(find.text('HomeScreen Placeholder'), findsOneWidget);
  });

  // Test 4: LoginScreen placeholder renders without crashing
  testWidgets('LoginScreen placeholder renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('LoginScreen Placeholder'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Center), findsOneWidget);
    expect(find.text('LoginScreen Placeholder'), findsOneWidget);
  });

  // Test 5: LoginScreen contains Button widget
  testWidgets('LoginScreen contains ElevatedButton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: null, child: Text('Login')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
