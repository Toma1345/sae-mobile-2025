import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'details_page.dart'; // Assure-toi d'importer la page de détails

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => RestaurantsPageState();
}

class RestaurantsPageState extends State<RestaurantsPage> {
  final _future = Supabase.instance.client
      .from('restaurants')
      .select();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des Restaurants")),
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
              return ListTile(
                title: Text(restaurant['name']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsPage(restaurantId: restaurant['id']),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}
