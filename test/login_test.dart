import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sae_mobile_2025/pages/login_page.dart';

void main() {
  testWidgets('Affichage initial de la page de connexion', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text("Connexion"), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text("Se connecter"), findsOneWidget);
    expect(find.text("Créer un compte"), findsOneWidget);
  });

  testWidgets('Saisie des identifiants', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.enterText(find.byType(TextField).first, 'tom2611.tb@gmail.com');
    await tester.enterText(find.byType(TextField).last, 'testeur');

    expect(find.text('tom2611.tb@gmail.com'), findsOneWidget);
    expect(find.text('testeur'), findsOneWidget);
  });

}
