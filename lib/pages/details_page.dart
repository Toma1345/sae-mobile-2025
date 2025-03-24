import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsPage extends StatefulWidget {
  final int restaurantId;

  const DetailsPage({super.key, required this.restaurantId});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<Map<String, dynamic>?> _restaurantFuture;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _restaurantFuture = _fetchRestaurant();
  }

  Future<Map<String, dynamic>?> _fetchRestaurant() async {
    final response = await Supabase.instance.client
        .from('restaurants')
        .select()
        .eq('id', widget.restaurantId)
        .maybeSingle();
    return response;
  }

  // Fonction pour ouvrir les URLs
  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  // Fonction pour composer un numéro de téléphone
  Future<void> _callPhoneNumber(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 0.5);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 0.5);
  }

  Widget _buildOpeningHoursCard(String openingHours) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final hours = <String, String>{
      for (var day in days) day: 'Fermé'
    };

    final parts = openingHours.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    for (var part in parts) {
      final hourIndex = part.indexOf(RegExp(r'\s\d'));
      if (hourIndex == -1) continue;

      final dayPart = part.substring(0, hourIndex).trim();
      final timePart = part.substring(hourIndex).trim();

      if (dayPart.contains('-')) {
        final dayRange = dayPart.split('-');
        if (dayRange.length == 2) {
          final startIndex = days.indexWhere((d) => d.toLowerCase().startsWith(dayRange[0].trim().toLowerCase()));
          final endIndex = days.indexWhere((d) => d.toLowerCase().startsWith(dayRange[1].trim().toLowerCase()));

          if (startIndex != -1 && endIndex != -1) {
            for (var i = startIndex; i <= endIndex; i++) {
              hours[days[i]] = timePart;
            }
          }
        }
      } else {
        final dayIndex = days.indexWhere((d) => d.toLowerCase().startsWith(dayPart.toLowerCase()));
        if (dayIndex != -1) {
          hours[days[dayIndex]] = timePart;
        }
      }
    }

    return Card(
      elevation: 4.0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.brown.shade800),
                const SizedBox(width: 8),
                Text(
                  "Horaires d'ouverture",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...days.map((day) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ),
                  Text(
                    ': ${hours[day]}',
                    style: TextStyle(
                      color: hours[day] == 'Fermé'
                          ? Colors.grey.shade600
                          : Colors.brown.shade800,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, {bool isUrl = false, bool isPhone = false}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.brown.shade800),
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
                      color: Colors.brown.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  isUrl || isPhone
                      ? GestureDetector(
                    onTap: () => isPhone ? _callPhoneNumber(value) : _launchUrl(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isPhone ? Colors.green.shade800 : Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                      : Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _restaurantFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Text(
                "Détails - ${snapshot.data!['name']}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }
            return const Text(
              "Détails restaurant",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade800,
        elevation: 4.0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _restaurantFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text(
                "Restaurant introuvable",
                style: TextStyle(color: Colors.brown),
              ),
            );
          }

          final restaurant = snapshot.data!;
          final restaurantLocation = LatLng(
            restaurant['latitude'] ?? 48.8566,
            restaurant['longitude'] ?? 2.3522,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (restaurant['type'] != null) ...[
                  _buildInfoCard(Icons.category, "Type", restaurant['type']),
                  const SizedBox(height: 16),
                ],
                if (restaurant['phone'] != null) ...[
                  _buildInfoCard(Icons.phone, "Contact", restaurant['phone'], isPhone: true),
                  const SizedBox(height: 16),
                ],
                if (restaurant['website'] != null) ...[
                  _buildInfoCard(Icons.language, "Site Internet", restaurant['website'], isUrl: true),
                  const SizedBox(height: 16),
                ],
                if (restaurant['opening_hours'] != null) ...[
                  _buildOpeningHoursCard(restaurant['opening_hours']),
                  const SizedBox(height: 16),
                ],
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
                    child: Stack(
                      children: [
                        FlutterMap(
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
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Column(
                            children: [
                              FloatingActionButton(
                                heroTag: 'zoomIn',
                                mini: true,
                                backgroundColor: Colors.white,
                                onPressed: _zoomIn,
                                child: Icon(Icons.add, color: Colors.brown.shade800),
                              ),
                              const SizedBox(height: 10),
                              FloatingActionButton(
                                heroTag: 'zoomOut',
                                mini: true,
                                backgroundColor: Colors.white,
                                onPressed: _zoomOut,
                                child: Icon(Icons.remove, color: Colors.brown.shade800),
                              ),
                            ],
                          ),
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
}