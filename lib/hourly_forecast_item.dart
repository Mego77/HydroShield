import 'package:flutter/material.dart';

class HourlyForecastItem extends StatelessWidget {
  final String time;
  final String temperature;
  final String condition;
  final Color timeColor;
  final Color tempColor;
  final Color? backgroundColor;
  final double width;
  final double iconSize;
  final double timeFontSize;
  final double tempFontSize;

  const HourlyForecastItem({
    super.key,
    required this.time,
    required this.temperature,
    required this.condition,
    this.timeColor = Colors.grey,
    this.tempColor = Colors.blue,
    this.backgroundColor,
    this.width = 100,
    this.iconSize = 32,
    this.timeFontSize = 16,
    this.tempFontSize = 16,
  });

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.electric_bolt;
      case 'clear':
        return Icons.wb_sunny;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.cloud;
    }
  }

  Color _getWeatherIconColor(BuildContext context, String condition) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (condition.toLowerCase()) {
      case 'clear':
        return isDark ? Colors.amber.shade300 : Colors.orange.shade700;
      case 'clouds':
        return isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600;
      case 'rain':
        return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      case 'snow':
        return isDark ? Colors.cyan.shade200 : Colors.cyan.shade600;
      case 'thunderstorm':
        return isDark ? Colors.yellow.shade300 : Colors.yellow.shade700;
      case 'mist':
      case 'fog':
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      default:
        return isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: backgroundColor ?? Theme.of(context).cardColor,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: timeFontSize,
                fontWeight: FontWeight.bold,
                color: timeColor,
              ),
            ),
            Icon(
              _getWeatherIcon(condition),
              size: iconSize,
              color: _getWeatherIconColor(context, condition),
            ),
            Text(
              temperature,
              style: TextStyle(
                fontSize: tempFontSize,
                fontWeight: FontWeight.bold,
                color: tempColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
