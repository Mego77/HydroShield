import 'package:flutter/material.dart';

class TextFieldElement extends StatefulWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool scure;
  final String? Function(String?)? validator;
  final bool enabled;

  const TextFieldElement({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.scure = false,
    this.validator,
    this.enabled = true,
  });

  @override
  State<TextFieldElement> createState() => _TextFieldElementState();
}

class _TextFieldElementState extends State<TextFieldElement> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.scure ? _obscureText : false,
      validator: widget.validator,
      enabled: widget.enabled,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(
          widget.icon,
          color: isDarkMode ? Colors.amber.shade300 : Colors.blue.shade700,
        ),
        suffixIcon: widget.scure
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color:
                      isDarkMode ? Colors.amber.shade300 : Colors.blue.shade700,
                ),
                onPressed: widget.enabled
                    ? () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      }
                    : null,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white30 : Colors.black26,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white30 : Colors.black26,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.amber.shade300 : Colors.blue.shade700,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.black26 : Colors.white,
      ),
    );
  }
}
