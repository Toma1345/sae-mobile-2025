import 'package:flutter/material.dart';
import 'package:sae_mobile_2025/pages/account_page.dart';
import 'package:sae_mobile_2025/pages/accueil_page.dart';
import 'package:sae_mobile_2025/pages/restaurant.dart';
import 'package:sae_mobile_2025/header_widget.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static List<Widget> pages = <Widget>[
    AccueilPage(),
    RestaurantsPage(),
    AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderWidget(),
          Expanded(
            child: pages[_selectedIndex],
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Color(0xFF462009),
      selectedItemColor: Color(0xFFC9A66B),
      unselectedItemColor: Color(0xFFEDE7E0),
      items: const <BottomNavigationBarItem> [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: "Accueil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_rounded),
          label: "Restaurants",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_rounded),
          label: "Profil",
        ),
      ],
    ),


    );
  }
}