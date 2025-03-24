import 'package:flutter/material.dart';
import 'package:sae_mobile_2025/pages/restaurant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sae_mobile_2025/pages/account_page.dart';
import 'package:sae_mobile_2025/pages/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();await initializeDateFormatting('fr_FR', null); // 🔹 Initialise la locale

  await Supabase.initialize(
    url: 'https://oqtczbaqyiqszbugjxse.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xdGN6YmFxeWlxc3pidWdqeHNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3MDY3MjIsImV4cCI6MjA1NzI4MjcyMn0.hdzvml1Ongd-eBHcMf0KtFw0CyOoTZg0GNQoy2oAMTU',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "IUTables'O",
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.green,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
          ),
        ),
      ),
      home: RestaurantsPage()
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}
