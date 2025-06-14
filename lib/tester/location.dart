import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String cityName = "Fetching...";
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Function to get user's current location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        cityName = "Location services are disabled.";
      });
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          cityName = "Location permission denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        cityName = "Location permission permanently denied.";
      });
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });

    // Convert to city name
    _getCityName(position.latitude, position.longitude);
  }

  /// Function to get city name from latitude and longitude
  Future<void> _getCityName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        setState(() {
          cityName = placemarks.first.locality ?? "Unknown";
        });
      }
    } catch (e) {
      setState(() {
        cityName = "Failed to get city";
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("City Finder")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("City: $cityName", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text("Latitude: ${latitude ?? "Loading..."}"),
            Text("Longitude: ${longitude ?? "Loading..."}"),
          ],
        ),
      ),
    );
  }
}
