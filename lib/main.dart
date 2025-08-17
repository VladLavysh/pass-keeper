import 'package:flutter/material.dart';
import 'package:pass_keeper/screens/home_screen.dart';
import 'package:pass_keeper/screens/password_screen.dart';
import 'package:pass_keeper/screens/lock_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pass Keeper',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
      ),
      initialRoute: '/lock',
      routes: {
        '/': (context) => HomeScreen(),
        '/lock': (context) => const LockScreen(),
        '/add': (context) => PasswordScreen(),
        '/edit': (context) => PasswordScreen(),
      },
    );
  }
}
