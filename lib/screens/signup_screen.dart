import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:weather_app/screens/login_screen.dart';
import 'package:weather_app/text_field_element.dart';
import 'package:weather_app/utils/validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> initializeUserChat(String userId) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('GP3_chats').doc('support_$userId').set({
        'createdAt': Timestamp.fromDate(now),
        'hasUnreadWarning': false,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastWarningTime': null,
        'participants': [userId],
        'type': 'support',
      });
      developer.log('Chat document initialized for user: $userId');
    } catch (e) {
      developer.log('Error initializing chat document: $e', error: e);
    }
  }

  Future<void> handleSignUp(BuildContext context) async {
    if (nameController.text.isEmpty) {
      showSnackBar(context, "Name should not be empty");
      return;
    }

    if (!Validators.isValidEmail(emailController.text)) {
      showSnackBar(context, "Please enter a valid email");
      return;
    }

    if (!Validators.isValidPassword(passwordController.text)) {
      showSnackBar(context,
          "Password must be at least 8 characters, include uppercase, lowercase, digit, and special character.");
      return;
    }

    if (confirmPasswordController.text != passwordController.text) {
      showSnackBar(context, "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Update the user's display name
      await userCredential.user!.updateDisplayName(nameController.text.trim());

      // Initialize chat document for the new user
      await initializeUserChat(userCredential.user!.uid);

      if (mounted) {
        showSnackBar(context, "Signup successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showSnackBar(context, "Signup failed: ${e.message}");
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, "An unexpected error occurred.");
      }
      print('error happen here $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, Colors.indigo.shade900]
                : [Colors.lightBlue.shade100, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 80,
                          color: isDark
                              ? Colors.amber.shade300
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Create Account',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFieldElement(
                          icon: Icons.person,
                          label: 'Enter your name',
                          controller: nameController,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 20),
                        TextFieldElement(
                          icon: Icons.email,
                          label: 'Enter your email',
                          controller: emailController,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 20),
                        TextFieldElement(
                          icon: Icons.password,
                          label: 'Enter your password',
                          controller: passwordController,
                          scure: true,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 20),
                        TextFieldElement(
                          icon: Icons.password,
                          label: 'Repeat your password',
                          controller: confirmPasswordController,
                          scure: true,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : () => handleSignUp(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.amber.shade300
                                  : Colors.blue.shade700,
                              foregroundColor:
                                  isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 48),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                LoginScreen()),
                                      );
                                    },
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.amber.shade300
                                      : Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
