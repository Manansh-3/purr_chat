import 'package:chat_app/core/constants/strings.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Center button (Add Friend) is index 1

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // TOD: Navigate to other pages like Profile or Home if needed
    switch (index) {
      case 0:
        print("Go to Home Page");
        break;
      case 1:
        print("Go to Add Friend Page");
        break;
      case 2:
        Navigator.pushNamed(context, profile);

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''), // Empty for now
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'You seem alone',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home,
                  color: _selectedIndex == 0 ? Colors.blue : Colors.grey),
              onPressed: () => _onItemTapped(0),
            ),
            SizedBox(width: 40), // Space for center FAB
            IconButton(
              icon: Icon(Icons.person,
                  color: _selectedIndex == 2 ? Colors.blue : Colors.grey),
              onPressed: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(1),
        tooltip: 'Add Friend',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
