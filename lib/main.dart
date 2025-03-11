import 'package:flutter/material.dart';
import 'package:sae_mobile_2025/restaurant.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oqtczbaqyiqszbugjxse.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xdGN6YmFxeWlxc3pidWdqeHNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3MDY3MjIsImV4cCI6MjA1NzI4MjcyMn0.hdzvml1Ongd-eBHcMf0KtFw0CyOoTZg0GNQoy2oAMTU',
  );

  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Restaurants',
      home: RestaurantsPage(),
    );
  }
}

