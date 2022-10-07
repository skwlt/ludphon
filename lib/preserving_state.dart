import 'package:flutter/material.dart';
import 'package:project/home.dart';
import 'package:project/screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreservingBottomNavState extends StatefulWidget {
  const PreservingBottomNavState({Key? key}) : super(key: key);

  @override
  _PreservingBottomNavStateState createState() => _PreservingBottomNavStateState();
}

class _PreservingBottomNavStateState extends State<PreservingBottomNavState> {
  int _selectedIndex = 2;
  final _auth = FirebaseAuth.instance;

  static const List<Widget> _pages = <Widget>[
    Center(
      child: Icon(
        Icons.call,
        size: 150,
      ),
    ),
    Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: TextField(
          style: TextStyle(fontSize: 50),
          decoration: InputDecoration(labelText: 'Find contact', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ),
    // const Home(),
    ChatScreen(),
    Center(
      child: Icon(
        Icons.call,
        size: 150,
      ),
    ),
    Home()
    // Center(
    //   child: Icon(
    //     Icons.call,
    //     size: 150,
    //   ),
    // ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _auth.signOut();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LUDPHON'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 20,
        selectedIconTheme: IconThemeData(color: Colors.red, size: 40),
        selectedItemColor: Colors.redAccent,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedIconTheme: IconThemeData(color: Colors.black26, size: 30),
        unselectedItemColor: Colors.black26,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'logout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.import_export),
            label: 'import',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'mic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.import_export),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dock),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
