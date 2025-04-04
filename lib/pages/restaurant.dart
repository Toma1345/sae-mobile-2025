import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'details_page.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => RestaurantsPageState();
}

class RestaurantsPageState extends State<RestaurantsPage> {
  final _future = Supabase.instance.client
      .from('restaurants')
      .select('id, name, type, cuisine, opening_hours');
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allRestaurants = [];
  List<dynamic> _filteredRestaurants = [];
  String? _selectedType;
  String? _selectedStatus;
  bool _showFavoriteTypesOnly = false;
  bool _showFavoriteCuisinesOnly = false;
  bool _showFavoritesOnly = false;
  final _user = Supabase.instance.client.auth.currentUser;
  Set<String> _favoriteRestaurantIds = {};
  List<String> _preferredRestaurantTypes = [];
  List<String> _preferredCuisineTypes = [];
  bool _isLoadingPreferences = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRestaurants);
    _loadFavorites();
    _loadPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (_user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('favoris')
          .select('id_restaurant')
          .eq('id_user', _user!.id);

      if (response != null) {
        setState(() {
          _favoriteRestaurantIds = Set.from(
              response.map((fav) => fav['id_restaurant'].toString()));
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des favoris: $e');
    }
  }

  Future<void> _toggleFavorite(String restaurantId) async {
    if (_user == null) return;

    final isFavorite = _favoriteRestaurantIds.contains(restaurantId);

    try {
      if (isFavorite) {
        await Supabase.instance.client
            .from('favoris')
            .delete()
            .match({
          'id_user': _user!.id,
          'id_restaurant': restaurantId,
        });
      } else {
        await Supabase.instance.client
            .from('favoris')
            .insert({
          'id_user': _user!.id,
          'id_restaurant': restaurantId,
        });
      }

      setState(() {
        if (isFavorite) {
          _favoriteRestaurantIds.remove(restaurantId);
        } else {
          _favoriteRestaurantIds.add(restaurantId);
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des favoris: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoadingPreferences = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _preferredRestaurantTypes = prefs.getStringList('preferredRestaurantTypes') ?? [];
        _preferredCuisineTypes = prefs.getStringList('preferredCuisineTypes') ?? [];
        _isLoadingPreferences = false;
      });
      _filterRestaurants();
    } catch (e) {
      setState(() => _isLoadingPreferences = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement préférences: $e')),
        );
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedStatus = null;
      _showFavoriteTypesOnly = false;
      _showFavoriteCuisinesOnly = false;
      _showFavoritesOnly = false;
      _filteredRestaurants = List.from(_allRestaurants);
    });
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        final name = restaurant['name'].toString().toLowerCase();
        final type = restaurant['type'].toString();
        final cuisine = restaurant['cuisine']?.toString() ?? '';
        final isOpen = _checkIfOpen(restaurant['opening_hours']);
        final isFavorite = _favoriteRestaurantIds.contains(restaurant['id'].toString());

        // Filtres de base
        final nameMatch = name.contains(query);
        final typeMatch = _selectedType == null || _selectedType == 'Tous' || type == _selectedType;
        final statusMatch = _selectedStatus == null ||
            _selectedStatus == 'Tous' ||
            (_selectedStatus == 'Ouvert' && isOpen == 'Ouvert') ||
            (_selectedStatus == 'Fermé' && isOpen == 'Fermé') ||
            (_selectedStatus == 'Non renseigné' && isOpen == null);

        // Filtres favoris
        final typeFavoriteMatch = !_showFavoriteTypesOnly ||
            (_preferredRestaurantTypes.isNotEmpty &&
                _preferredRestaurantTypes.any((pref) => type.toLowerCase().contains(pref.toLowerCase())));

        final cuisineFavoriteMatch = !_showFavoriteCuisinesOnly ||
            (_preferredCuisineTypes.isNotEmpty &&
                _preferredCuisineTypes.any((pref) => cuisine.toLowerCase().contains(pref.toLowerCase())));

        final favoritesMatch = !_showFavoritesOnly || isFavorite;

        return nameMatch && typeMatch && statusMatch && typeFavoriteMatch && cuisineFavoriteMatch && favoritesMatch;
      }).toList();
    });
  }

  bool _matchesTypePreferences(Map<String, dynamic> restaurant) {
    final type = restaurant['type'].toString();
    return _preferredRestaurantTypes.isNotEmpty &&
        _preferredRestaurantTypes.any((pref) => type.toLowerCase().contains(pref.toLowerCase()));
  }

  bool _matchesCuisinePreferences(Map<String, dynamic> restaurant) {
    final cuisine = restaurant['cuisine']?.toString() ?? '';
    return _preferredCuisineTypes.isNotEmpty &&
        _preferredCuisineTypes.any((pref) => cuisine.toLowerCase().contains(pref.toLowerCase()));
  }

  List<String> _getRestaurantTypes() {
    final types = _allRestaurants.map((r) => r['type'].toString()).toSet().toList();
    types.insert(0, 'Tous');
    return types;
  }

  String _formatCuisine(String cuisine) {
    String cleaned = cuisine
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll("'", "");
    return cleaned.split(',').map((s) => s.trim()).join(', ');
  }

  bool _matchesUserPreferences(Map<String, dynamic> restaurant) {
    final type = restaurant['type'].toString();
    final cuisine = restaurant['cuisine']?.toString() ?? '';

    final matchesRestaurantType = _preferredRestaurantTypes.isNotEmpty &&
        _preferredRestaurantTypes.any((pref) => type.toLowerCase().contains(pref.toLowerCase()));

    final matchesCuisineType = _preferredCuisineTypes.isNotEmpty &&
        _preferredCuisineTypes.any((pref) => cuisine.toLowerCase().contains(pref.toLowerCase()));

    return matchesRestaurantType || matchesCuisineType;
  }

  String? _checkIfOpen(String? openingHours) {
    if (openingHours == null || openingHours.isEmpty) return null;

    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE', 'fr_FR').format(now);
    final currentTime = DateFormat('HH:mm').format(now);

    for (String period in openingHours.split('|')) {
      final parts = period.trim().split(' ');
      final days = parts[0];
      final timeRanges = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      if (_isDayMatching(dayOfWeek, days)) {
        if (timeRanges.isEmpty) return 'Ouvert';

        for (String range in timeRanges.split(',')) {
          final times = range.trim().split('-');
          if (times.length == 2) {
            if (_isWithinTimeRange(currentTime, times[0], times[1])) {
              return 'Ouvert';
            }
          }
        }
      }
    }
    return 'Fermé';
  }

  String _capitalizeFirstLetter(String s) => s[0].toUpperCase() + s.substring(1);

  bool _isDayMatching(String currentDay, String days) {
    final daysList = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];

    currentDay = _capitalizeFirstLetter(currentDay);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFC9A66B),
        title: const Text(
            'Restaurants',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
        ),
        actions: [
          if (_isLoadingPreferences)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2,),
              ),
            ),
        ],
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
                      filled: true,
                      fillColor: const Color(0xFFF1F1F1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF462009), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3498DB), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF462009), width: 2),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _resetFilters,
                      )
                          : null,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('Types préférés'),
                    selected: _showFavoriteTypesOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showFavoriteTypesOnly = selected;
                        _filterRestaurants();
                      });
                    },
                    selectedColor: Colors.green[100],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Cuisines préférées'),
                    selected: _showFavoriteCuisinesOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showFavoriteCuisinesOnly = selected;
                        _filterRestaurants();
                      });
                    },
                    selectedColor: Colors.blue[100],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Favoris'),
                    selected: _showFavoritesOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showFavoritesOnly = selected;
                        _filterRestaurants();
                      });
                    },
                    selectedColor: Colors.red[100],
                    avatar: _showFavoritesOnly
                        ? const Icon(Icons.favorite, size: 16, color: Colors.red)
                        : const Icon(Icons.favorite_border, size: 16),
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
                    final matchesType = _matchesTypePreferences(restaurant);
                    final isFavorite = _favoriteRestaurantIds.contains(restaurant['id'].toString());
                    final matchesCuisine = _matchesCuisinePreferences(restaurant);


                    Color? cardColor;
                    if (matchesType && matchesCuisine) {
                      cardColor = Colors.purple[50]; // Les deux préférences
                    } else if (matchesType) {
                      cardColor = Colors.green[50]; // Type seulement
                    } else if (matchesCuisine) {
                      cardColor = Colors.blue[50]; // Cuisine seulement
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: cardColor,
                      child: ListTile(
                        title: Text(restaurant['name']),
                        trailing: IconButton(
                          icon: Icon(
                            isFavorite? Icons.favorite_border : Icons.favorite,
                            color: isFavorite ? Colors.red : null,
                          ),
                          onPressed: () => _toggleFavorite(restaurant['id'].toString()),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsPage(restaurantId: restaurant['id']),
                            ),
                          );
                        },
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Row(
                              children: [
                                Text(restaurant['type'] ?? 'Type non spécifié'),
                                const SizedBox(width: 8),
                              ],
                            ),
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

  bool isDayMatching(String currentDay, String days) {
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

  bool isWithinTimeRange(String currentTime, String startTime, String endTime) {
    try {
      final now = DateFormat('HH:mm').parse(currentTime);
      final start = DateFormat('HH:mm').parse(startTime);
      final end = DateFormat('HH:mm').parse(endTime);
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

}