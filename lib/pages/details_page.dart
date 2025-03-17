import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DetailsPage extends StatefulWidget {
  final int restaurantId; // ID du restaurant à afficher

  const DetailsPage({super.key, required this.restaurantId});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _future = Supabase.instance.client
        .from('restaurants')
        .select()
        .eq('id', widget.restaurantId)
        .limit(1);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Détails du restaurant")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("Restaurant introuvable"));
          }

          final restaurant = snapshot.data!.first;

          final double latitude = restaurant['latitude'] ?? 48.8566;
          final double longitude = restaurant['longitude'] ?? 2.3522;
          final LatLng restaurantLocation = LatLng(latitude, longitude);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Google Map en carré
                Container(
                  width: double.infinity, // Largeur max
                  height: 300, // Hauteur fixe pour le carré
                  decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: restaurantLocation,
                      zoom: 14.0,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(restaurant['name']),
                        position: restaurantLocation,
                        infoWindow: InfoWindow(title: restaurant['name']),
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Infos du restaurant
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurant['type'] != null) ...[
                      Text("Type : ${restaurant['type']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['phone'] != null) ...[
                      Text("Contact : ${restaurant['phone']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['website'] != null) ...[
                      Text("Site Internet : ${restaurant['website']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['opening_hours'] != null) ...[
                      Text("Heure d'ouverture : ${restaurant['opening_hours']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['cuisine'] != null) ...[
                      Text("Type de Cuisine : ${restaurant['cuisine']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['vegetarian'] != null) ...[
                      Text("Végétarien : ${restaurant['vegetarian']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['vegan'] != null) ...[
                      Text("Vegan : ${restaurant['vegan']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['delivery'] != null) ...[
                      Text("Livraison : ${restaurant['delivery']}"),
                      const SizedBox(height: 8),
                    ],
                    if (restaurant['takeaway'] != null) ...[
                      Text("Drive : ${restaurant['takeaway']}"),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
