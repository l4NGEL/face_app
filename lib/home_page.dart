import 'package:flutter/material.dart';
import 'pages/page_home.dart';
import 'pages/page_recognize.dart';
import 'pages/page_add_user.dart';
import 'pages/users_page.dart'; // yeni sayfa

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1);
  int _selectedIndex = 1;
  int _lastTappedIndex = -1;
  DateTime? _lastTapTime;

  final List<Widget> _pages = const [
    PageAddUser(),     // index 0
    PageHome(),        // index 1 ← Ana Sayfa
    PageRecognize(),   // index 2
  ];

  void _onItemTapped(int index) {
    DateTime now = DateTime.now();

    if (_selectedIndex == index &&
        _lastTappedIndex == index &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UsersPage()),
        );
      }
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }

    _lastTappedIndex = index;
    _lastTapTime = now;
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Kayıt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face),
            label: 'Tanıma',
          ),
        ],
      ),
    );
  }
}
