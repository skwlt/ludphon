import 'package:flutter/material.dart';
import 'package:project/screens/start.dart';
import 'package:project/screens/login_screen.dart';
import 'package:project/screens/registration_screen.dart';
import 'package:project/screens/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'preserving_state.dart';
import 'package:project/home.dart';
import 'package:project/preserving_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/start',
      routes: {
        '/start': (context) => StartScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => RegistrationScreen(),
        '/chat': (context) => ChatScreen(),
        '/home': (context) => PreservingBottomNavState(),
      },
    );
  }
}
