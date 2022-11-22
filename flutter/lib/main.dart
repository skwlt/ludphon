import 'dart:async';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/screens/file_screen.dart';

String? path;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        path = '/start';
      } else {
        print('User is signed in!');
        path = '/home';
      }
    });
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    print(path);
  }
  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,

      initialRoute: path,
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
