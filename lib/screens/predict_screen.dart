import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/screens/weather_detail_screen.dart';
import 'dart:ui' as lol;

class PredictScreen extends StatelessWidget {
  const PredictScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<WeatherProvider>(
          builder: (context, provider, _) {
            return Text(
              'weather_forecast_alexandria'.tr(),
              style: TextStyle(
                color: isDark
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      theme.colorScheme.surface,
                      theme.colorScheme.primaryContainer
                    ]
                  : [
                      theme.colorScheme.surface,
                      theme.colorScheme.primaryContainer.withOpacity(0.7)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onPrimaryContainer,
            ),
            tooltip: 'refresh'.tr(),
            onPressed: () => context.read<WeatherProvider>().refreshLocation(),
          ),
        ],
        elevation: 4,
        shadowColor: theme.shadowColor.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, theme.colorScheme.primaryContainer]
                : [
                    theme.colorScheme.surface,
                    theme.colorScheme.primaryContainer
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Consumer<WeatherProvider>(
          builder: (context, provider, _) {
            if (provider.isFetching) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.weatherData == null) {
              return Center(
                child: Text(
                  'no_weather_data'.tr(),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              );
            }

            final current = provider.getCurrentWeather();
            final dailyForecasts = provider.getDailyForecasts();

            return Column(
              children: [
                if (current != null)
                  FutureBuilder<double>(
                    future: provider.getFloodPrediction(current),
                    builder: (context, snapshot) {
                      final floodRisk = snapshot.data ?? 0.0;
                      return _buildWeatherCard(
                        context,
                        date: DateTime.fromMillisecondsSinceEpoch(
                            current['dt'] * 1000),
                        temp: (current['main']['temp'] as num).toDouble(),
                        weather: current['weather'][0]['main'],
                        icon: _getWeatherIcon(current['weather'][0]['main']),
                        isCurrent: true,
                        floodRisk: floodRisk,
                        weatherData: current, // Pass full weather data
                      );
                    },
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dailyForecasts.length,
                    itemBuilder: (context, index) {
                      final forecast = dailyForecasts[index];
                      return FutureBuilder<double>(
                        future: provider.getFloodPrediction(forecast),
                        builder: (context, snapshot) {
                          final floodRisk = snapshot.data ?? 0.0;
                          return _buildWeatherCard(
                            context,
                            date: forecast['display_date'],
                            temp: (forecast['main']['temp'] as num).toDouble(),
                            weather: forecast['weather'][0]['main'],
                            icon:
                                _getWeatherIcon(forecast['weather'][0]['main']),
                            floodRisk: floodRisk,
                            weatherData: forecast, // Pass full weather data
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeatherCard(
    BuildContext context, {
    required DateTime date,
    required double temp,
    required String weather,
    required IconData icon,
    bool isCurrent = false,
    double floodRisk = 0.0,
    required Map<String, dynamic> weatherData, // Added parameter
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final floodColor = _getFloodColor(floodRisk, isDark);
    final isArabic = context.locale.languageCode == 'ar';

    final backgroundGradient = LinearGradient(
      colors: isDark
          ? [
              theme.colorScheme.surface.withOpacity(0.6),
              floodColor.withOpacity(0.25),
            ]
          : [
              theme.colorScheme.surface.withOpacity(0.3),
              floodColor.withOpacity(0.15),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final iconColor = _getWeatherIconColor(weather, isDark);

    // Format flood risk percentage as a plain string
    final formattedFloodRisk = (floodRisk * 100).toStringAsFixed(1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherDetailScreen(
              date: date,
              temp: temp,
              weather: weather,
              icon: icon,
              floodRisk: floodRisk,
              weatherData: weatherData, // Pass weather data to detail screen
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.transparent,
        shadowColor: theme.shadowColor.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: floodColor.withOpacity(0.5), width: 1.2),
            gradient: backgroundGradient,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCurrent
                        ? 'now'.tr()
                        : _isSameDay(date, DateTime.now())
                            ? 'today'.tr()
                            : DateFormat('EEEE', context.locale.languageCode)
                                .format(date),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  _buildFloodRiskIndicator(floodRisk, isDark, context),
                ],
              ),
              Text(
                DateFormat('MMM d', context.locale.languageCode).format(date),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: iconColor,
                  ),
                  Text(
                    '${temp.toStringAsFixed(1)}°C',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection:
                    isArabic ? lol.TextDirection.rtl : lol.TextDirection.ltr,
                child: Text(
                  context.tr(_mapWeatherCondition(weather)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: floodRisk,
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainer
                    : theme.colorScheme.surfaceContainerLowest,
                valueColor: AlwaysStoppedAnimation<Color>(floodColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection:
                    isArabic ? lol.TextDirection.rtl : lol.TextDirection.ltr,
                child: Text(
                  '${'flood_risk'.tr()} $formattedFloodRisk%',
                  style: TextStyle(
                    color: floodColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloodRiskIndicator(
      double risk, bool isDark, BuildContext context) {
    final theme = Theme.of(context);
    final color = _getFloodColor(risk, isDark);
    final isArabic = context.locale.languageCode == 'ar';
    final formattedRisk = (risk * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Directionality(
        textDirection: isArabic ? lol.TextDirection.rtl : lol.TextDirection.ltr,
        child: Text(
          '$formattedRisk%',
          style: TextStyle(
            color: isDark ? theme.colorScheme.onSurface : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getFloodColor(double risk, bool isDark) {
    if (risk < 0.3) {
      return isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (risk < 0.6) {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    } else {
      return isDark ? Colors.red.shade300 : Colors.red.shade700;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _mapWeatherCondition(String apiCondition) {
    switch (apiCondition.toLowerCase()) {
      case 'clear sky':
        return 'clear';
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
      case 'overcast clouds':
        return 'clouds';
      case 'shower rain':
      case 'light rain':
      case 'moderate rain':
        return 'rain';
      case 'snow':
      case 'light snow':
      case 'heavy snow':
        return 'snow';
      case 'thunderstorm':
      case 'thunderstorm with rain':
        return 'thunderstorm';
      case 'mist':
      case 'fog':
      case 'haze':
        return 'mist';
      default:
        return apiCondition.toLowerCase();
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (_mapWeatherCondition(condition)) {
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
      default:
        return Icons.cloud;
    }
  }

  Color _getWeatherIconColor(String condition, bool isDark) {
    switch (_mapWeatherCondition(condition)) {
      case 'clouds':
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      case 'rain':
        return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      case 'snow':
        return isDark ? Colors.cyan.shade200 : Colors.cyan.shade600;
      case 'thunderstorm':
        return isDark ? Colors.purple.shade300 : Colors.purple.shade700;
      case 'clear':
        return isDark ? Colors.yellow.shade300 : Colors.orange.shade700;
      default:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }
}
