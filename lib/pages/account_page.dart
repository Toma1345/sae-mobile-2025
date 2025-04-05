import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sae_mobile_2025/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _user = Supabase.instance.client.auth.currentUser;
  late SharedPreferences _prefs;

  List<String> _restaurantTypes = [];
  List<String> _cuisineTypes = [];
  List<String> _selectedRestaurantTypes = [];
  List<String> _selectedCuisineTypes = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      final restaurantTypes = await _fetchAllUniqueRestaurantTypes();
      final cuisines = await _fetchAllUniqueCuisines();

      setState(() {
        _restaurantTypes = restaurantTypes;
        _cuisineTypes = cuisines;
        _selectedRestaurantTypes = _prefs.getStringList('preferredRestaurantTypes') ?? [];
        _selectedCuisineTypes = _prefs.getStringList('preferredCuisineTypes') ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAllUniqueRestaurantTypes() async {
    final response = await Supabase.instance.client
        .from('restaurants')
        .select('type')
        .neq('type', '')
        .not('type', 'is', null);

    return _extractUniqueValues(response, 'type');
  }

  Future<List<String>> _fetchAllUniqueCuisines() async {
    final response = await Supabase.instance.client
        .from('restaurants')
        .select('cuisine')
        .neq('cuisine', '')
        .not('cuisine', 'is', null);

    final allCuisines = <String>[];

    for (final item in response) {
      final cuisineValue = item['cuisine']?.toString().trim();
      if (cuisineValue != null && cuisineValue.isNotEmpty) {
        // Nettoyage des caractères indésirables
        String cleanedValue = cuisineValue
            .replaceAll("'", "")  // Enlève les apostrophes
            .replaceAll("[", "")  // Enlève les crochets ouverts
            .replaceAll("]", "")  // Enlève les crochets fermés
            .trim();

        // Gestion des valeurs séparées par des virgules
        if (cleanedValue.contains(',')) {
          final splitCuisines = cleanedValue.split(',')
              .map((c) => c.trim())
              .where((c) => c.isNotEmpty);
          allCuisines.addAll(splitCuisines);
        } else {
          allCuisines.add(cleanedValue);
        }
      }
    }

    // Standardisation des valeurs (ex: 'Pizza'' devient 'Pizza')
    final standardizedCuisines = allCuisines.map((cuisine) {
      // Mise en forme du texte (première lettre en majuscule)
      if (cuisine.isNotEmpty) {
        return cuisine[0].toUpperCase() + cuisine.substring(1).toLowerCase();
      }
      return cuisine;
    }).toList();

    // Élimination des doublons et tri
    final uniqueCuisines = standardizedCuisines.toSet().toList();
    uniqueCuisines.sort((a, b) => a.compareTo(b));

    return uniqueCuisines;
  }

  List<String> _extractUniqueValues(List<dynamic> response, String columnName) {
    final values = response
        .map((item) => item[columnName]?.toString().trim())
        .where((value) => value != null && value.isNotEmpty)
        .toSet()
        .toList()
        .cast<String>();

    values.sort();
    return values;
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      await _prefs.setStringList('preferredRestaurantTypes', _selectedRestaurantTypes);
      await _prefs.setStringList('preferredCuisineTypes', _selectedCuisineTypes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préférences enregistrées avec succès!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleRestaurantType(String type) {
    setState(() {
      if (_selectedRestaurantTypes.contains(type)) {
        _selectedRestaurantTypes.remove(type);
      } else if (_selectedRestaurantTypes.length < 2) {
        _selectedRestaurantTypes.add(type);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 2 types de restaurants sélectionnables')),
        );
      }
    });
  }

  void _toggleCuisineType(String type) {
    setState(() {
      if (_selectedCuisineTypes.contains(type)) {
        _selectedCuisineTypes.remove(type);
      } else if (_selectedCuisineTypes.length < 3) {
        _selectedCuisineTypes.add(type);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 3 types de cuisines sélectionnables')),
        );
      }
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFC9A66B),
        title: const Text(
          "Mon compte",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bienvenue, ${_user?.email ?? 'Utilisateur'}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Section Types de restaurants
            _buildPreferenceSection(
              title: "Types de restaurants favoris (max 2)",
              selected: _selectedRestaurantTypes,
              allOptions: _restaurantTypes,
              onToggle: _toggleRestaurantType,
              selectedColor: Colors.green[50]!,
            ),
            const SizedBox(height: 24),
            // Section Types de cuisines
            _buildPreferenceSection(
              title: "Types de cuisines favorites (max 3)",
              selected: _selectedCuisineTypes,
              allOptions: _cuisineTypes,
              onToggle: _toggleCuisineType,
              selectedColor: Colors.blue[50]!,
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Color(0xFF7E1A21),
                  foregroundColor: Color(0xFFEDE7E0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Enregistrer les préférences'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _signOut,
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF7E1A21), textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  "Se déconnecter",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSection({
    required String title,
    required List<String> selected,
    required List<String> allOptions,
    required Function(String) onToggle,
    required Color selectedColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: selected.map((type) => Chip(
                    label: Text(type),
                    backgroundColor: selectedColor,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onToggle(type),
                  )).toList(),
                ),
              ),

            const Divider(),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allOptions.map((type) => FilterChip(
                label: Text(type),
                selected: selected.contains(type),
                onSelected: (_) => onToggle(type),
                selectedColor: selectedColor,
                showCheckmark: false,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}