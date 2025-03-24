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
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allRestaurants = [];
  List<dynamic> _filteredRestaurants = [];
  String? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRestaurants);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedStatus = null;
      _filteredRestaurants = List.from(_allRestaurants);
    });
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        final name = restaurant['name'].toString().toLowerCase();
        final type = restaurant['type'].toString();
        final isOpen = checkIfOpen(restaurant['opening_hours']);

        final nameMatch = name.contains(query);
        final typeMatch = _selectedType == null || _selectedType == 'Tous' || type == _selectedType;
        final statusMatch = _selectedStatus == null ||
            _selectedStatus == 'Tous' ||
            (_selectedStatus == 'Ouvert' && isOpen == 'Ouvert') ||
            (_selectedStatus == 'Fermé' && isOpen == 'Fermé') ||
            (_selectedStatus == 'Non renseigné' && isOpen == null);

        return nameMatch && typeMatch && statusMatch;
      }).toList();
    });
  }

  List<String> _getRestaurantTypes() {
    final types = _allRestaurants.map((r) => r['type'].toString()).toSet().toList();
    types.insert(0, 'Tous');
    return types;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un restaurant...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _resetFilters,
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: _future,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return DropdownButton<String>(
                          value: 'Tous',
                          items: [DropdownMenuItem(value: 'Tous', child: Text('Chargement...'))],
                          onChanged: null,
                        );
                      }

                      if (_allRestaurants.isEmpty) {
                        _allRestaurants = snapshot.data!;
                        _filteredRestaurants = _allRestaurants;
                      }

                      final types = _getRestaurantTypes();

                      return DropdownButton<String>(
                        value: _selectedType ?? 'Tous',
                        isExpanded: true,
                        items: types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                            _filterRestaurants();
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus ?? 'Tous',
                    isExpanded: true,
                    items: [
                      'Tous',
                      'Ouvert',
                      'Fermé',
                      'Non renseigné',
                    ].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _filterRestaurants();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_allRestaurants.isEmpty) {
                  _allRestaurants = snapshot.data!;
                  _filteredRestaurants = _allRestaurants;
                }

                return _filteredRestaurants.isEmpty
                    ? const Center(child: Text('Aucun restaurant trouvé'))
                    : ListView.builder(
                  itemCount: _filteredRestaurants.length,
                  itemBuilder: ((context, index) {
                    final restaurant = _filteredRestaurants[index];
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
                              color: isOpen == 'Ouvert'
                                  ? Colors.green
                                  : (isOpen == 'Fermé'
                                  ? Colors.red
                                  : Colors.grey),
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
          ),
        ],
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
      final days = parts[0];
      final timeRanges = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      if (isDayMatching(dayOfWeek, days)) {
        if (timeRanges.isEmpty) return 'Ouvert';

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