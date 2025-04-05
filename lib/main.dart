import 'package:flutter/material.dart';
import 'package:sae_mobile_2025/pages/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sae_mobile_2025/pages/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();await initializeDateFormatting('fr_FR', null); // Initialise la locale

  await SharedPreferences.getInstance();


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
      theme: ThemeData(
        fontFamily: 'Franklin Gothic Medium',
        scaffoldBackgroundColor: Color(0xFFEDE7E0),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: FutureBuilder(
          future: _checkAuthState(),
          builder: (context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text("Erreur de connexion"),
                ),
              );
            }
            return snapshot.data == true ? const HomePage() : const LoginPage();
          },
      ),
    );
  }

  Future<bool> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2));
    return supabase.auth.currentSession != null;
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
