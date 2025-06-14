import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class VoteProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasVotedToday = false;
  bool _isLoading = false;

  bool get hasVotedToday => _hasVotedToday;
  bool get isLoading => _isLoading;

  VoteProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User logged out, reset the state
        _resetState();
      } else {
        // User logged in, check vote status
        _checkVoteStatus();
      }
    });
  }

  void _resetState() {
    _hasVotedToday = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkVoteStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      _resetState();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Check for votes by both userId and email
      final voteQuery = await _firestore
          .collection('flood_votes')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .where(Filter.or(
            Filter('userId', isEqualTo: user.uid),
            Filter('userEmail', isEqualTo: user.email),
          ))
          .get();

      _hasVotedToday = voteQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking vote status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitVote(
      bool floodHappened, Map<String, dynamic> weatherData) async {
    final user = _auth.currentUser;
    if (user == null || _hasVotedToday) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final dateString = startOfDay.toIso8601String().split('T')[0];

      // Add user's vote with additional data
      await _firestore.collection('flood_votes').add({
        'userId': user.uid,
        'userEmail': user.email,
        'floodHappened': floodHappened,
        'timestamp': FieldValue.serverTimestamp(),
        'date': dateString,
        'location': {
          'lat': weatherData['coord']?['lat'],
          'lon': weatherData['coord']?['lon'],
        },
      });

      // Update today's flood status with both prediction model data and additional weather data
      final dateAgain = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayDocRef = _firestore.collection('today_flood_status').doc(dateAgain);

      await _firestore.runTransaction((transaction) async {
        final todayDoc = await transaction.get(todayDocRef);

        // Primary data for prediction model
        final predictionData = {
          'Year': today.year,
          'Month': today.month,
          'Max_Temp': weatherData['main']['temp_max'],
          'Min_Temp': weatherData['main']['temp_min'],
          'Rainfall': weatherData['rain']?['3h'] ?? 0.0,
          'Relative_Humidity': weatherData['main']['humidity'],
          'Wind_Speed': weatherData['wind']['speed'],
          'Cloud_Coverage': weatherData['clouds']['all'],
          'Bright_Sunshine': weatherData['main']['feels_like'],
          'ALT': 250.0,
        };

        // Additional weather data for reference and analysis
        final additionalData = {
          'current_temp': weatherData['main']['temp'],
          'pressure': weatherData['main']['pressure'],
          'visibility': weatherData['visibility'],
          'wind_direction': weatherData['wind']['deg'],
          'weather_condition': weatherData['weather'][0]['main'],
          'weather_description': weatherData['weather'][0]['description'],
          'sunrise': weatherData['sys']['sunrise'],
          'sunset': weatherData['sys']['sunset'],
          'timezone': weatherData['timezone'],
        };

        if (todayDoc.exists) {
          transaction.update(todayDocRef, {
            'floodVotes': FieldValue.increment(floodHappened ? 1 : 0),
            'totalVotes': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
            'predictionData': predictionData, // Primary data for model
            'weatherData': additionalData, // Additional data for reference
          });
        } else {
          transaction.set(todayDocRef, {
            'date': dateString,
            'floodVotes': floodHappened ? 1 : 0,
            'totalVotes': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'predictionData': predictionData, // Primary data for model
            'weatherData': additionalData, // Additional data for reference
            'location': {
              'lat': weatherData['coord']?['lat'],
              'lon': weatherData['coord']?['lon'],
              'city': weatherData['name'],
              'country': weatherData['sys']['country'],
            },
          });
        }
      });

      _hasVotedToday = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting vote: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getTodayVoteStatus() async {
    try {
      final dateAgain = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final doc = await _firestore
          .collection('today_flood_status')
          .doc(dateAgain)
          .get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting vote status: $e');
      return null;
    }
  }
}
