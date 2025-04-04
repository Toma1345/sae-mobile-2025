import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'details_page.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _recommendedRestaurants = [];
  bool _isLoading = true;
  List<String> _preferredRestaurantTypes = [];
  List<String> _preferredCuisineTypes = [];
  final MapController _mapController = MapController();
  LatLng _mapCenter = LatLng(47.916672, 1.9); // La Source par défaut --> à rendre dynamique
  double _mapZoom = 12.0;
  LatLng? _userPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition().then((_) => _loadRecommendedRestaurants());
    });
  }


  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activez la localisation pour une meilleure expérience')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Les permissions de localisation sont nécessaires')),
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
          _mapCenter = _userPosition!; // Centre immédiatement sur la position
          _mapZoom = 14.0; // Zoom plus rapproché
        });
        _mapController.move(_userPosition!, _mapZoom); // Animation fluide
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Localisation non disponible: $e')),
        );
      }
    }
  }

  void _centerMapOnUser() {
    if (_userPosition != null) {
      // Vérification plus robuste de la disponibilité du contrôleur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController.camera.rotation != 0) {
          _mapController.rotate(0);
        }
        _mapController.move(_userPosition!, _mapZoom);
      });
    }
  }

  Future<void> _loadRecommendedRestaurants() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _preferredRestaurantTypes = prefs.getStringList('preferredRestaurantTypes') ?? [];
      _preferredCuisineTypes = prefs.getStringList('preferredCuisineTypes') ?? [];

      final response = await supabase
          .from('restaurants')
          .select('id, name, type, cuisine, opening_hours, latitude, longitude');

      final now = DateTime.now();
      final dayOfWeek = DateFormat('EEEE', 'fr_FR').format(now);
      final currentTime = DateFormat('HH:mm').format(now);

      final allRestaurants = (response as List).cast<Map<String, dynamic>>()
          .where((restaurant) => _isRestaurantOpen(
        restaurant['opening_hours'],
        dayOfWeek,
        currentTime,
      ))
          .toList();

      // Calcul des scores pour chaque restaurant
      for (var restaurant in allRestaurants) {
        restaurant['score'] = _calculateCompatibilityScore(restaurant);
      }

      // Tri par score décroissant
      allRestaurants.sort((a, b) => b['score'].compareTo(a['score']));

      setState(() {
        _recommendedRestaurants = allRestaurants.take(7).toList();
        _updateMapCenter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  void _updateMapCenter() {
    if (_recommendedRestaurants.isNotEmpty) {
      double totalLat = 0;
      double totalLng = 0;
      int count = 0;

      for (final restaurant in _recommendedRestaurants) {
        if (restaurant['latitude'] != null && restaurant['longitude'] != null) {
          totalLat += restaurant['latitude'];
          totalLng += restaurant['longitude'];
          count++;
        }
      }

      if (count > 0) {
        setState(() {
          _mapCenter = LatLng(totalLat / count, totalLng / count);
        });
      }
    }
  }

  Widget _buildMap() {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _mapZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.sae_mobile_2025',
              ),
              // Marqueur utilisateur
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              // Marqueurs restaurants
              MarkerLayer(
                markers: _recommendedRestaurants
                    .where((r) => r['latitude'] != null && r['longitude'] != null)
                    .map((restaurant) {
                  final pos = LatLng(restaurant['latitude'], restaurant['longitude']);
                  return Marker(
                    point: pos,
                    width: 100,
                    height: 60,
                    child: Column(
                      children: [
                        const Icon(Icons.location_pin, color: Colors.red, size: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            restaurant['name'] ?? 'Nom inconnu',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // Bouton de recentrage
        if (_userPosition != null)
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton.small(
              onPressed: () {
                _mapController.move(_userPosition!, _mapZoom);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }

  bool _isRestaurantOpen(String? openingHours, String dayOfWeek, String currentTime) {
    if (openingHours == null || openingHours.isEmpty) return false;

    for (String period in openingHours.split('|')) {
      final parts = period.trim().split(' ');
      if (parts.isEmpty) continue;

      final days = parts[0];
      final timeRanges = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      if (_isDayMatching(dayOfWeek, days)) {
        if (timeRanges.isEmpty) return true;

        for (String range in timeRanges.split(',')) {
          final times = range.trim().split('-');
          if (times.length == 2) {
            if (_isWithinTimeRange(currentTime, times[0], times[1])) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  bool _isDayMatching(String currentDay, String days) {
    final daysList = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];

    currentDay = currentDay[0].toUpperCase() + currentDay.substring(1);

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

  bool _isWithinTimeRange(String currentTime, String startTime, String endTime) {
    try {
      final now = DateFormat('HH:mm').parse(currentTime);
      final start = DateFormat('HH:mm').parse(startTime);
      final end = DateFormat('HH:mm').parse(endTime);
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  double _calculateDistance(LatLng pos1, LatLng pos2) {
    const Distance distance = Distance();
    return distance(pos1, pos2) / 1000; // Retourne la distance en kilomètres
  }

  int _calculateCompatibilityScore(Map<String, dynamic> restaurant) {
    if (restaurant['latitude'] == null || restaurant['longitude'] == null) {
      return 0;
    }

    final type = restaurant['type']?.toString().toLowerCase() ?? '';
    final cuisine = restaurant['cuisine']?.toString().toLowerCase() ?? '';
    final restaurantPos = LatLng(restaurant['latitude'], restaurant['longitude']);

    // Score basé sur les préférences
    bool matchesType = _preferredRestaurantTypes.any(
            (pref) => type.contains(pref.toLowerCase()));

    bool matchesCuisine = _preferredCuisineTypes.any(
            (pref) => cuisine.contains(pref.toLowerCase()));

    int preferenceScore = 0;
    if (matchesType && matchesCuisine) preferenceScore = 3;
    else if (matchesCuisine) preferenceScore = 2;
    else if (matchesType) preferenceScore = 1;

    // Score basé sur la distance (si position utilisateur disponible)
    int distanceScore = 0;
    if (_userPosition != null) {
      double distance = _calculateDistance(_userPosition!, restaurantPos);

      if (distance < 1) distanceScore = 3;    // < 1km = score max
      else if (distance < 3) distanceScore = 2;  // < 3km
      else if (distance < 5) distanceScore = 1;  // < 5km
    }

    // Combinaison des scores (vous pouvez ajuster les poids)
    return (preferenceScore * 2) + distanceScore; // Préférence compte double
  }

  Color? _getCardColor(Map<String, dynamic> restaurant) {
    final score = _calculateCompatibilityScore(restaurant);
    return switch (score) {
      3 => Colors.purple[50],
      2 => Colors.blue[50],
      1 => Colors.green[50],
      _ => null,
    };
  }

  String _formatCuisine(String cuisine) {
    String cleaned = cuisine
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll("'", "");
    return cleaned.split(',').map((s) => s.trim()).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Restaurants ouverts qui pourraient vous plaire:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _buildMap(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_recommendedRestaurants.isEmpty)
            const Text('Aucun restaurant ouvert trouvé')
          else
            Column(
              children: _recommendedRestaurants.map((restaurant) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: _getCardColor(restaurant),
                  child: ListTile(
                    title: Text(restaurant['name'] ?? 'Nom inconnu'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(restaurant['type'] ?? 'Type non spécifié'),
                            const SizedBox(width: 8),
                            Text(
                              restaurant['cuisine'] != null
                                  ? _formatCuisine(restaurant['cuisine'])
                                  : '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Ouvert maintenant',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(restaurantId: restaurant['id']),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}