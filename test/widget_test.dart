//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_notes_app/main.dart';

void main() {
  testWidgets('Secure Notes App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const SecureNotesApp());
    
    // Verify the app shows the authentication screen
    expect(find.text('Secure Notes'), findsOneWidget);
  });
}