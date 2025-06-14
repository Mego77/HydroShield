import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_app/screens/community_screen.dart';
import 'package:weather_app/screens/flood_status_tab.dart';
import 'package:weather_app/screens/predict_screen.dart';
import 'package:weather_app/screens/setting_screen.dart';
import 'package:weather_app/screens/weather_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class MasterPage extends StatefulWidget {
  const MasterPage({super.key});

  @override
  State<MasterPage> createState() => _MasterPageState();
}

class _MasterPageState extends State<MasterPage> {
  List<Widget> screens = [
    const WeatherScreen(),
    const PredictScreen(),
    const CommunityScreen(),
    const FloodStatusTab(), // Add FloodStatusTab to the screens list
    const SettingScreen(),
  ];
  int selectedScreen = 0;

  @override
  void initState() {
    super.initState();
    setupFCM();
  }

  Future<void> setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("🔐 FCM Token: $token");

      if (token != null) {
        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Store token with device ID
          await FirebaseFirestore.instance
              .collection('users_tokens')
              .doc(token)
              .set({
            'fcmToken': token,
            'userId': user.uid,
            'deviceInfo': {
              'platform': Theme.of(context).platform.toString(),
              'timestamp': FieldValue.serverTimestamp(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Handle token refresh
      messaging.onTokenRefresh.listen((String token) async {
        print("🔄 FCM Token Refreshed: $token");
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users_tokens')
              .doc(token)
              .set({
            'fcmToken': token,
            'userId': user.uid,
            'deviceInfo': {
              'platform': Theme.of(context).platform.toString(),
              'timestamp': FieldValue.serverTimestamp(),
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Handle incoming messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          print("📩 Notification Received: ${message.notification!.title}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.notification!.title ?? 'Notification'),
            ),
          );
        }
      });
    } else {
      print("❌ Notification permission not granted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedScreen],
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.amber,
        unselectedItemColor: Colors.blue,
        currentIndex: selectedScreen,
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attractions_rounded),
            label: 'Predict',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flood_rounded), // Icon for Flood Status
            label: 'Flood Status', // Label for Flood Status
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
        onTap: (value) {
          setState(() {
            selectedScreen = value;
          });
        },
      ),
    );
  }
}