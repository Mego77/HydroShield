import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Learn(),
    );
  }
}

class Learn extends StatelessWidget {
  const Learn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  ' K',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
               Icon( Icons.sunny,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'hello',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
