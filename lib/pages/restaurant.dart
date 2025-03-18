import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => RestaurantsPageState();
}

class RestaurantsPageState extends State<RestaurantsPage> {
  final _future = Supabase.instance.client
      .from('restaurants')
      .select('id, name, type, opening_hours');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final restaurants = snapshot.data!;
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: ((context, index) {
              final restaurant = restaurants[index];
              final isOpen = checkIfOpen(restaurant['opening_hours']);
              return ListTile(
                title: Text(restaurant['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant['type']),
                    Text(
                      isOpen ?? 'Non renseigné',
                      style: TextStyle(
                        color: isOpen == 'Ouvert' ? Colors.green : (isOpen == 'Fermé' ? Colors.red : Colors.grey),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  String? checkIfOpen(String? openingHours) {
    if (openingHours == null || openingHours.isEmpty) return null;

    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE', 'fr_FR').format(now);
    final currentTime = DateFormat('HH:mm').format(now);

    for (String period in openingHours.split('|')) {
      final parts = period.trim().split(' ');
      final days = parts[0]; // Ex: "Mardi-Samedi" ou "Dimanche"
      final timeRanges = parts.length > 1 ? parts.sublist(1).join(' ') : '';


      if (isDayMatching(dayOfWeek, days)) {
        if (timeRanges.isEmpty) return 'Ouvert'; // Ouvert 24h

        for (String range in timeRanges.split(',')) {
          final times = range.trim().split('-');
          if (times.length == 2) {

            if (isWithinTimeRange(currentTime, times[0], times[1])) {
              return 'Ouvert';
            }
          }
        }
      }
    }
    return 'Fermé';
  }

  String capitalizeFirstLetter(String s) => s[0].toUpperCase() + s.substring(1);

  bool isDayMatching(String currentDay, String days) {
    final daysList = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];

    currentDay = capitalizeFirstLetter(currentDay);

    if (days.contains('-')) {
      final range = days.split('-');
      if (range.length == 2) {
        final startIdx = daysList.indexOf(range[0]);
        final endIdx = daysList.indexOf(range[1]);
        final currentIdx = daysList.indexOf(currentDay);

        if (startIdx != -1 && endIdx != -1 && currentIdx != -1) {
          return startIdx <= currentIdx && currentIdx <= endIdx;
        }
      }
    }
    return days.split(',').contains(currentDay);
  }

  bool isWithinTimeRange(String currentTime, String startTime, String endTime) {
    final now = DateFormat('HH:mm').parse(currentTime);
    final start = DateFormat('HH:mm').parse(startTime);
    final end = DateFormat('HH:mm').parse(endTime);

    return now.isAfter(start) && now.isBefore(end);
  }


}