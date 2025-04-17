import 'package:flutter/material.dart';
import 'profile.dart';
import 'map_screen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Start on Map Page

  final List<Widget> _pages = [
    Placeholder(),         // Home
    Placeholder(),         // Camera
    MapScreen(),           // Map
    StylishProfilePage(),  // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1E2D3D),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.white60,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),  // Map icon
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),  // Profile
        ],
      ),
    );
  }
}
