import 'package:flutter/material.dart';

class AdditionalInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color labelColor;
  final Color valueColor;
  final double iconSize;
  final double labelSize;
  final double valueSize;

  const AdditionalInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = Colors.blueAccent,
    this.labelColor = Colors.grey,
    this.valueColor = Colors.black87,
    this.iconSize = 32,
    this.labelSize = 14,
    this.valueSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: labelSize,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
