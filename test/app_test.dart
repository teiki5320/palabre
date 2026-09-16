import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('l application demarre', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Président'))));
    expect(find.text('Président'), findsOneWidget);
  });
}
