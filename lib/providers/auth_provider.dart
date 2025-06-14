import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/weather_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isAdmin = false;
  String? _displayName;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _displayName = user?.displayName;
      _checkAdminStatus();
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAdmin => _isAdmin;
  String? get displayName => _displayName;

  Future<void> _checkAdminStatus() async {
    if (_user != null) {
      // Check if the user is the admin
      _isAdmin = _user!.email == 'admin@gmail.com';

      // Only update user document if not admin
      if (!_isAdmin) {
        await _firestore.collection('users').doc(_user!.uid).set({
          'isAdmin': _isAdmin,
          'email': _user!.email,
          'displayName': _user!.displayName,
        }, SetOptions(merge: true));
      }
    } else {
      _isAdmin = false;
    }
    notifyListeners();
  }

  Future<void> _updateCityCounter(String cityName) async {
    try {
      // Reference to the city document in cities_counter collection
      final cityRef = _firestore.collection('cities_counter').doc(cityName);

      // Use a transaction to safely increment the counter
      await _firestore.runTransaction((transaction) async {
        final cityDoc = await transaction.get(cityRef);

        if (cityDoc.exists) {
          // If the document exists, increment the counter
          transaction.update(cityRef, {
            'userCount': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
            'cityName': cityName, // Store the city name for easier querying
          });
        } else {
          // If the document doesn't exist, create it with count 1
          transaction.set(cityRef, {
            'userCount': 1,
            'lastUpdated': FieldValue.serverTimestamp(),
            'cityName': cityName, // Store the city name for easier querying
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Also update the user's document with their current city
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'currentCity': cityName,
          'lastCityUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating city counter: $e');
    }
  }

  Future<void> login(
      String email, String password, BuildContext context) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is admin
      final isAdmin = userCredential.user?.email == 'admin@gmail.com';

      // Only proceed with city updates and Firestore updates if not admin
      if (!isAdmin) {
        // Check if user is banned
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final isBanned = userData['isBanned'] ?? false;

          if (isBanned) {
            // Sign out the user if they are banned
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'user-banned',
              message: 'This account has been banned.',
            );
          }
        }

        // Get the user's city from WeatherProvider
        final weatherProvider =
            Provider.of<WeatherProvider>(context, listen: false);
        final cityName = weatherProvider.cityName;

        if (cityName != null) {
          // Update the city counter
          await _updateCityCounter(cityName);
        }

        // Update user's last login time
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
          'lastCity': cityName,
        });
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createSupportChat(String userId) async {
    final supportChatId = 'support_$userId';
    await _firestore.collection('GP3_chats').doc(supportChatId).set({
      'hasUnreadWarning': false,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastWarningTime': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      print("🔵 Starting Google Sign-In process...");

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("🔵 Google Sign-In result: ${googleUser?.email ?? 'null'}");

      if (googleUser == null) {
        print("❌ Google Sign-In was cancelled by user");
        return;
      }

      print("🔵 Getting Google Auth credentials...");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print("🔵 Got access token: ${googleAuth.accessToken != null}");
      print("🔵 Got ID token: ${googleAuth.idToken != null}");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("🔵 Signing in to Firebase with Google credential...");
      final userCredential = await _auth.signInWithCredential(credential);
      print("🔵 Firebase Sign-In successful: ${userCredential.user?.email}");

      // Get the user's city from WeatherProvider
      final weatherProvider =
          Provider.of<WeatherProvider>(context, listen: false);
      final cityName = weatherProvider.cityName;
      print("🔵 User's city: $cityName");

      if (cityName != null) {
        print("🔵 Updating city counter...");
        await _updateCityCounter(cityName);
      }

      print("🔵 Creating/updating user document in Firestore...");
      // Check if user document exists to preserve ban status
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      bool isBanned = false;
      if (userDoc.exists && userDoc.data() != null) {
        isBanned = userDoc.data()!['isBanned'] as bool? ?? false;
      }

      // Create or update user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user?.email,
        'displayName': userCredential.user?.displayName,
        'isAdmin': false,
        'isBanned': isBanned, // Preserve ban status
        'lastLogin': FieldValue.serverTimestamp(),
        'lastCity': cityName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ User document updated successfully");

      print("🔵 Creating support chat document...");
      // Create support chat document
      await _createSupportChat(userCredential.user!.uid);
      print("✅ Support chat document created successfully");

      notifyListeners();
      print("✅ Google Sign-In process completed successfully");
    } catch (e) {
      print("❌ Error during Google Sign-In: $e");
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with display name
      await userCredential.user?.updateDisplayName(name);
      _displayName = name;

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': name,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'isBanned': false,
      });

      // Create support chat document
      await _createSupportChat(userCredential.user!.uid);

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Check if user is signed in with Google
      if (_user?.providerData.any((info) => info.providerId == 'google.com') ??
          false) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      _isAdmin = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDisplayName(String newName) async {
    try {
      await _user?.updateDisplayName(newName);
      _displayName = newName;

      // Update Firestore document
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update({'displayName': newName});

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      // Reauthenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);

      // Update password
      await _user!.updatePassword(newPassword);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
