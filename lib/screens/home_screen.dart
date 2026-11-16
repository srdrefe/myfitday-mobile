import 'workout_content.dart';

import 'package:flutter/material.dart';

import 'calorie_content.dart';

import 'home_content.dart';
import 'ai_chat_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Alt menüden seçilen sekmeye göre değişecek içerikler
  late final List<Widget> _widgetOptions = <Widget>[
    HomeContent(onTabSelected: _onItemTapped),
    const CalorieContent(),
    const WorkoutContent(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'MyFitDay AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor:
            Colors.transparent, // Kaydırma yaparken rengin bozulmasını engeller
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // Yapay Zeka Sohbet Butonu (BottomSheet'i açar)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AiChatSheet(),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),

      // Alt Menü (Bottom Navigation Bar)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Kalori',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Antrenman',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
