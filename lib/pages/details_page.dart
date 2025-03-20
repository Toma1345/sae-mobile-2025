import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart'; // Pour OpenStreetMap
import 'package:latlong2/latlong.dart'; // Pour gérer les coordonnées

class DetailsPage extends StatefulWidget {
  final int restaurantId;

  const DetailsPage({super.key, required this.restaurantId});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _future = Supabase.instance.client
        .from('restaurants')
        .select()
        .eq('id', widget.restaurantId)
        .limit(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Détails du restaurant",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade800, // Marron foncé pour la barre
        elevation: 4.0,
      ),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant['name'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800, // Couleur du texte en marron foncé
                  ),
                ),
                const SizedBox(height: 16),
                if (restaurant['type'] != null) ...[
                  _buildInfoCard(Icons.category, "Type", restaurant['type']),
                  const SizedBox(height: 16),
                ],
                if (restaurant['phone'] != null) ...[
                  _buildInfoCard(Icons.phone, "Contact", restaurant['phone']),
                  const SizedBox(height: 16),
                ],
                if (restaurant['website'] != null) ...[
                  _buildInfoCard(Icons.language, "Site Internet", restaurant['website']),
                  const SizedBox(height: 16),
                ],
                if (restaurant['opening_hours'] != null) ...[
                  restaurant['opening_hours'] is String
                      ? _buildInfoCard(Icons.access_time, "Horaires", restaurant['opening_hours'])
                      : _buildOpeningHoursTable(restaurant['opening_hours']),
                  const SizedBox(height: 16),
                ],
                // Déplacement de la carte en dessous
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: restaurantLocation,
                        initialZoom: 14.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40.0,
                              height: 40.0,
                              point: restaurantLocation,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.brown.shade100, // Marron clair pour les cartes
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.brown.shade800), // Icon en marron foncé
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800, // Couleur marron foncé
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode ajoutée pour afficher les horaires d'ouverture
  Widget _buildOpeningHoursTable(Map<String, dynamic> openingHours) {
    List<Widget> rows = [];

    openingHours.forEach((day, hours) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800, // Couleur marron foncé
              ),
            ),
            Text(
              hours,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Horaires d'ouverture",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800, // Couleur marron foncé
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}
