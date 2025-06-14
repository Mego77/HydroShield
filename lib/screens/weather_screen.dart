import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/providers/auth_provider.dart' as myAuth;
import 'package:weather_app/providers/vote_provider.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.black, Colors.indigo.shade900]
              : [Colors.lightBlue.shade100, Colors.blue.shade300],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Consumer<WeatherProvider>(
            builder: (context, weatherProvider, _) => Text(
              weatherProvider.cityName != null
                  ? '${'weather_app'.tr()} - ${weatherProvider.cityName}'
                  : 'weather_app'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
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
              onPressed: () =>
                  context.read<WeatherProvider>().refreshLocation(),
              icon: Icon(
                Icons.refresh,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimaryContainer,
              ),
              tooltip: 'refresh'.tr(),
            ),
          ],
        ),
        body: Consumer<WeatherProvider>(
          builder: (context, weatherProvider, _) {
            if (weatherProvider.isFetching) {
              return const Center(child: CircularProgressIndicator());
            }

            if (weatherProvider.weatherData == null) {
              return Center(child: Text('fetching_weather'.tr()));
            }

            return WeatherContent(weatherData: weatherProvider.weatherData!);
          },
        ),
      ),
    );
  }
}

class WeatherContent extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WeatherContent({super.key, required this.weatherData});

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

  Future<void> _submitVote(BuildContext context, bool floodHappened,
      Map<String, dynamic> weatherData) async {
    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    final success = await voteProvider.submitVote(floodHappened, weatherData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Thank you for your vote!'
              : 'Failed to submit vote. Please try again.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    final currentWeatherData = weatherProvider.getCurrentWeather();
    if (currentWeatherData == null) {
      return Center(child: Text('error'.tr()));
    }

    final currentTemp = currentWeatherData['main']['temp'];
    final currentSky = currentWeatherData['weather'][0]['main'];
    final currentPressure = currentWeatherData['main']['pressure'];
    final currentWindSpeed = currentWeatherData['wind']['speed'];
    final currentHumidity = currentWeatherData['main']['humidity'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Weather Card
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${currentTemp.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWeatherIcon(currentSky, context),
                        const SizedBox(height: 16),
                        Text(
                          context.tr(_mapWeatherCondition(currentSky)),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'hourly_forecast'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: 5,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final hourlyForecast = weatherData['list'][index + 1];
                final hourlySky = hourlyForecast['weather'][0]['main'];
                final hourlyTemp = hourlyForecast['main']['temp'];
                final time = DateTime.parse(hourlyForecast['dt_txt']);
                return HourlyForecastItem(
                  time: DateFormat.Hm(context.locale.languageCode).format(time),
                  temperature: '${hourlyTemp.toStringAsFixed(1)}°C',
                  condition: context.tr(_mapWeatherCondition(hourlySky)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'additional_information'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<double>(
            future: weatherProvider.getFloodPrediction(currentWeatherData),
            builder: (context, snapshot) {
             final floodPrediction =
             snapshot.data != null ? ((snapshot.data as double) * 100).toStringAsFixed(1) : '0.0';

              // print('📦 Snapshot Data:\n${jsonEncode(snapshot.data)}');

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfoItem(
                        icon: Icons.water_drop,
                        label: 'humidity'.tr(),
                        value: '${currentHumidity}%',
                      ),
                      AdditionalInfoItem(
                        icon: Icons.air,
                        label: 'wind_speed'.tr(),
                        value: '${currentWindSpeed} m/s',
                      ),
                      AdditionalInfoItem(
                        icon: Icons.water,
                        label: 'flood_prediction'.tr(),
                        value: '$floodPrediction%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Consumer<VoteProvider>(
                    builder: (context, voteProvider, _) {
                      if (voteProvider.isLoading) {
                        return const CircularProgressIndicator();
                      }

                      if (voteProvider.hasVotedToday) {
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: voteProvider.getTodayVoteStatus(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final data = snapshot.data!;
                            final floodVotes = data['floodVotes'] ?? 0;
                            final totalVotes = data['totalVotes'] ?? 0;
                            final percentage = totalVotes > 0
                                ? ((floodVotes / totalVotes) * 100)
                                    .toStringAsFixed(1)
                                : '0.0';

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Today\'s Flood Status',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$percentage% of voters reported flooding',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Total votes: $totalVotes',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Did you experience flooding today?',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _submitVote(
                                        context, true, currentWeatherData),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Yes'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _submitVote(
                                        context, false, currentWeatherData),
                                    icon: const Icon(Icons.close),
                                    label: const Text('No'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'five_day_forecast'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFiveDayForecast(weatherProvider, context),
        ],
      ),
    );
  }

  Icon _buildWeatherIcon(String currentSky, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const iconSize = 64.0;

    switch (_mapWeatherCondition(currentSky)) {
      case 'clear':
        return Icon(Icons.wb_sunny,
            size: iconSize,
            color: isDark ? Colors.amber.shade300 : Colors.orange.shade700);
      case 'clouds':
        return Icon(Icons.cloud,
            size: iconSize,
            color:
                isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600);
      case 'rain':
        return Icon(Icons.umbrella,
            size: iconSize,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700);
      case 'snow':
        return Icon(Icons.ac_unit,
            size: iconSize,
            color: isDark ? Colors.cyan.shade200 : Colors.cyan.shade600);
      case 'thunderstorm':
        return Icon(Icons.electric_bolt,
            size: iconSize,
            color: isDark ? Colors.yellow.shade300 : Colors.yellow.shade700);
      case 'mist':
      case 'fog':
        return Icon(Icons.foggy,
            size: iconSize,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600);
      default:
        return Icon(Icons.cloud,
            size: iconSize,
            color:
                isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600);
    }
  }

  Widget _buildFiveDayForecast(
      WeatherProvider weatherProvider, BuildContext context) {
    final dailyForecasts = weatherProvider.getDailyForecasts();

    return Column(
      children: dailyForecasts.map((forecast) {
        final date = forecast['display_date'] as DateTime;
        final temp = forecast['main']['temp'];
        final weather = forecast['weather'][0]['main'];

        return ListTile(
          leading: Text(DateFormat.E(context.locale.languageCode).format(date)),
          title:
              Text(DateFormat.yMMMd(context.locale.languageCode).format(date)),
          trailing: Text('${temp.toStringAsFixed(1)}°C'),
          subtitle: Text(context.tr(_mapWeatherCondition(weather))),
          dense: true,
        );
      }).toList(),
    );
  }
}
