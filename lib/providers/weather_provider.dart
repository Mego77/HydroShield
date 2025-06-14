import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/secrets.dart';

class WeatherProvider with ChangeNotifier {
  // Constants
  static const _alexandriaLat = 31.2001;
  static const _alexandriaLng = 29.9187;
  static const _alexandriaName = 'Alexandria';

  // State variables
  bool _isFetching = false;
  Map<String, dynamic>? _weatherData;
  String? _cityName;
  String? _currentAddress;
  Position? _currentPosition;

  // Getters
  bool get isFetching => _isFetching;
  Map<String, dynamic>? get weatherData => _weatherData;
  String? get cityName => _cityName;
  String? get currentAddress => _currentAddress;
  Position? get currentPosition => _currentPosition;

  WeatherProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchLocation();
  }

  Future<void> _trackCityInFirestore(String cityName) async {
    try {
      final cityRef =
          FirebaseFirestore.instance.collection('cities').doc(cityName);
      final doc = await cityRef.get();

      final cityData = {
        'name': cityName,
        'lastSearched': FieldValue.serverTimestamp(),
        'searchCount': FieldValue.increment(1),
        'coordinates': {'lat': _alexandriaLat, 'lng': _alexandriaLng}
      };

      if (doc.exists) {
        await cityRef.update(cityData);
      } else {
        await cityRef.set({
          ...cityData,
          'createdAt': FieldValue.serverTimestamp(),
          'searchCount': 1, // Initial value for new documents
        });
      }
    } catch (e) {
      debugPrint('Firestore city tracking error: $e');
      // Consider adding error reporting here
    }
  }

  Future<void> _trackUserCitySearch(String cityName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentWeather = getCurrentWeather();
      if (currentWeather == null) return;

      await FirebaseFirestore.instance.collection('user_cities').doc().set({
        'userId': user.uid,
        'cityName': cityName,
        'coordinates': {'lat': _alexandriaLat, 'lng': _alexandriaLng},
        'searchedAt': FieldValue.serverTimestamp(),
        'weatherData': {
          'temp': currentWeather['main']?['temp'],
          'conditions': currentWeather['weather']?[0]?['main'],
        },
      });
    } catch (e) {
      debugPrint('Error tracking user city search: $e');
    }
  }

  Future<double> getFloodPrediction(Map<String, dynamic> weatherData) async {
    try {
      final response = await http.post(
        Uri.parse('https://naguibabdeljawad77.pythonanywhere.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Year': DateTime.now().year,
          'Month': DateTime.now().month,
          'Max_Temp': weatherData['main']['temp_max'],
          'Min_Temp': weatherData['main']['temp_min'],
          'Rainfall': weatherData['rain']?['3h'] ?? 0.0,
          'Relative_Humidity': weatherData['main']['humidity'],
          'Wind_Speed': weatherData['wind']['speed'],
          'Cloud_Coverage': weatherData['clouds']['all'],
          'Bright_Sunshine': weatherData['main']['feels_like'],
          'ALT': 250.0
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['flood_prediction'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Flood prediction error: $e');
      return 0.0;
    }
  }

  Future<bool> _handleLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      return permission != LocationPermission.deniedForever;
    } catch (e) {
      debugPrint('Location permission error: $e');
      return false;
    }
  }

  Future<void> _getCurrentPosition() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      await _getAddressFromLatLng(position);
    } catch (e) {
      debugPrint('Position error: $e');
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        _currentAddress =
            place.locality ?? place.subAdministrativeArea ?? _alexandriaName;
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      _currentAddress = _alexandriaName;
    }
  }

  Future<void> _fetchLocation() async {
    if (_isFetching) return;

    _isFetching = true;
    notifyListeners();

    try {
      await _getCurrentPosition();
      await _fetchAlexandriaWeather();

      _cityName = _currentAddress ?? _alexandriaName;
    } catch (e) {
      debugPrint('Location fetch error: $e');
      _cityName = _alexandriaName;
      await _fetchAlexandriaWeather();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  String _formattedDate() {
  final now = DateTime.now();
  return '${now.day}-${now.month}-${now.year}';
}

  Future<void> _fetchAlexandriaWeather() async {
  final String docId = _formattedDate();
  final docRef = FirebaseFirestore.instance
      .collection('weather_daily')
      .doc(docId);

  final docSnapshot = await docRef.get();

  if (docSnapshot.exists) {
    _weatherData = docSnapshot.data();
    
  } else {
    try {
      final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?'
        'lat=$_alexandriaLat&lon=$_alexandriaLng&'
        'appid=$openWeatherAPIKey&units=metric',
      ));

      if (response.statusCode != 200) {
        throw Exception('Failed to load weather data');
      }

      final data = jsonDecode(response.body);
      if (data['cod'] != '200') {
        throw Exception('API error: ${data['message']}');
      }

      _weatherData = data;

      await docRef.set(data);

    } catch (e) {
      debugPrint('Weather fetch error: $e');
      rethrow;
    }
  }
}

  Future<void> refreshLocation() async {
    await _fetchLocation();
  }

  Map<String, dynamic>? getCurrentWeather() {
    if (_weatherData == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final forecasts = _weatherData!['list'] as List;

    return forecasts.reduce((a, b) {
      return (a['dt'] - now).abs() < (b['dt'] - now).abs() ? a : b;
    });
  }

  List<Map<String, dynamic>> getDailyForecasts() {
    if (_weatherData == null) return [];

    final forecasts = _weatherData!['list'] as List;
    final dailyForecasts = <Map<String, dynamic>>[];
    final processedDays = <DateTime>{};

    for (final forecast in forecasts) {
      final forecastTime =
          DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      final forecastDay =
          DateTime(forecastTime.year, forecastTime.month, forecastTime.day);

      if (!processedDays.contains(forecastDay) &&
          forecastTime.hour >= 11 &&
          forecastTime.hour <= 14) {
        dailyForecasts.add({
          ...forecast,
          'display_date': forecastDay,
        });
        processedDays.add(forecastDay);

        if (dailyForecasts.length >= 5) break;
      }
    }

    return dailyForecasts;
  }
}
