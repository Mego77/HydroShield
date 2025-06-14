import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/master_page.dart';
import 'package:weather_app/screens/signup_screen.dart';
import 'package:weather_app/text_field_element.dart';
import 'package:weather_app/providers/auth_provider.dart' as myAuth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:weather_app/screens/admin_support_screen.dart';
import 'package:weather_app/screens/reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<myAuth.AuthProvider>(context, listen: false).login(
        _emailController.text.trim(),
        _passwordController.text,
        context,
      );

      if (!mounted) return;

      // Check if user is admin and show admin screen
      if (Provider.of<myAuth.AuthProvider>(context, listen: false).isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminSupportScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MasterPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('login_failed'.tr())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      print("🔵 Login Screen: Starting Google Sign-In...");
      await Provider.of<myAuth.AuthProvider>(context, listen: false)
          .signInWithGoogle(context);
      print("🔵 Login Screen: Google Sign-In successful");

      if (!mounted) return;

      print("🔵 Login Screen: Navigating to MasterPage...");
      // Google sign-in users are not admins, so always go to MasterPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MasterPage()),
      );
      print("✅ Login Screen: Navigation complete");
    } catch (e) {
      print("❌ Login Screen: Google Sign-In failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('google_signin_failed'.tr())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.login,
                            size: 80,
                            color: isDarkMode
                                ? Colors.amber.shade300
                                : Colors.blue.shade700,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'weather_app'.tr(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFieldElement(
                            icon: Icons.email,
                            label: 'email'.tr(),
                            controller: _emailController,
                          ),
                          const SizedBox(height: 20),
                          TextFieldElement(
                            icon: Icons.password,
                            label: 'password'.tr(),
                            controller: _passwordController,
                            scure: true,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ResetPasswordScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'forgot_password'.tr(),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.amber.shade300
                                      : Colors.blue.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Colors.amber.shade300
                                  : Colors.blue.shade700,
                              foregroundColor:
                                  isDarkMode ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 48),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                                    'login'.tr(),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'or'.tr(),
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            icon: Image.asset(
                              'assets/images/google_logo.png',
                              height: 24,
                            ),
                            label: Text('sign_in_with_google'.tr()),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account?',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SignupScreen()),
                                  );
                                },
                                child: Text(
                                  'create_account'.tr(),
                                  style: TextStyle(
                                    color: isDarkMode
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
      ),
    );
  }
}
