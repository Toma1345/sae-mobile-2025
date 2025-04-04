import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sae_mobile_2025/pages/restaurant.dart';

void main() {
  testWidgets("Affichage de la page Restaurants", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RestaurantsPage(),
      ),
    );

    expect(find.byType(RestaurantsPage), findsOneWidget);
    expect(find.text("Liste des restaurants"), findsOneWidget);
  });
}
