import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log('Starting Google Sign-In process...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('Google Sign-In was cancelled by user');
        return null;
      }

      developer.log('Google Sign-In successful, getting auth details...');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      developer.log('Creating credential with Google auth details...');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('Signing in to Firebase with Google credential...');

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      developer.log(
        'Firebase Sign-In successful! User ID: ${userCredential.user?.uid}',
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase Auth Error: ${e.code} - ${e.message}', error: e);
      rethrow;
    } catch (e) {
      developer.log('Unexpected error during sign-in: $e', error: e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      developer.log('Successfully signed out');
    } catch (e) {
      developer.log('Error signing out: $e', error: e);
      rethrow;
    }
  }
}
 