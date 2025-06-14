import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:weather_app/text_field_element.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reset_password_email_sent'.tr())),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reset_password_failed'.tr())),
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
      appBar: AppBar(
        title: Text('reset_password'.tr()),
        backgroundColor: isDarkMode ? Colors.black : Colors.blue.shade700,
        foregroundColor: isDarkMode ? Colors.white : Colors.white,
      ),
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
                            Icons.lock_reset,
                            size: 80,
                            color: isDarkMode
                                ? Colors.amber.shade300
                                : Colors.blue.shade700,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'reset_password'.tr(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'reset_password_description'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFieldElement(
                            icon: Icons.email,
                            label: 'email'.tr(),
                            controller: _emailController,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
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
                                    'send_reset_link'.tr(),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
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
