import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FloodStatusTab extends StatelessWidget {
  const FloodStatusTab({super.key});

  LinearGradient _getCardGradient(int index) {
    final colors = [
      [Colors.blue.shade300, Colors.blue.shade600],
      [Colors.teal.shade300, Colors.teal.shade600],
      [Colors.purple.shade300, Colors.purple.shade600],
      [Colors.green.shade300, Colors.green.shade600],
    ];
    return LinearGradient(
      colors: colors[index % colors.length],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Future<double> getFloodPrediction(Map<String, dynamic> predictionData) async {
    try {
      final response = await http.post(
        Uri.parse('https://naguibabdeljawad77.pythonanywhere.com/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Year': DateTime.now().year,
          'Month': DateTime.now().month,
          'Max_Temp': predictionData['Max_Temp'] ?? 0.0,
          'Min_Temp': predictionData['Min_Temp'] ?? 0.0,
          'Rainfall': predictionData['Rainfall'] ?? 0.0,
          'Relative_Humidity': predictionData['Relative_Humidity'] ?? 0.0,
          'Wind_Speed': predictionData['Wind_Speed'] ?? 0.0,
          'Cloud_Coverage': predictionData['Cloud_Coverage'] ?? 0.0,
          'Bright_Sunshine': predictionData['Bright_Sunshine'] ?? 0.0,
          'ALT': predictionData['ALT'] ?? 250.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['flood_prediction'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Flood prediction error: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'flood_history'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.blue.shade900,
          ),
        ),
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: isDark ? Colors.grey.shade900 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'flood_status'.tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blue.shade900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('today_flood_status')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Error loading flood data: ${snapshot.error}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.redAccent
                                  : Colors.red.shade700,
                              fontSize: 16,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            'no_flood_data'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              thickness: 1.5,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final date = data['date']?.toString() ?? 'N/A';
                            final floodVotes =
                                data['floodVotes']?.toString() ?? 'N/A';
                            final totalVotes =
                                data['totalVotes']?.toString() ?? 'N/A';
                            final predictionData = data['predictionData']
                                    as Map<String, dynamic>? ??
                                {};
                            final weatherData =
                                data['weatherData'] as Map<String, dynamic>? ??
                                    {};
                            final createdAt = (data['createdAt'] as Timestamp?)
                                    ?.toDate()
                                    .toString() ??
                                'N/A';
                            final lastUpdated =
                                (data['lastUpdated'] as Timestamp?)
                                        ?.toDate()
                                        .toString() ??
                                    'N/A';
                            final location =
                                data['location'] as Map<String, dynamic>? ?? {};
                            final city =
                                location['city']?.toString() ?? 'Alexandria';
                            final country =
                                location['country']?.toString() ?? 'Egypt';

                            return Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: _getCardGradient(index),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            date,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Icon(
                                            Icons.flood_rounded,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Created: $createdAt',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      Text(
                                        'Updated: $lastUpdated',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Flood Votes: $floodVotes / $totalVotes',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Location',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'City: $city',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                            Text(
                                              'Country: $country',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ExpansionTile(
                                        title: const Text(
                                          'Prediction Data',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white,
                                        childrenPadding:
                                            const EdgeInsets.all(12),
                                        backgroundColor:
                                            Colors.white.withOpacity(0.1),
                                        children: [
                                          FutureBuilder<double>(
                                            future: getFloodPrediction(
                                                predictionData),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                );
                                              }
                                              if (snapshot.hasError) {
                                                return Text(
                                                  'Error: ${snapshot.error}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                  ),
                                                );
                                              }
                                              return Text(
                                                'Flood Prediction: ${(snapshot.data != null ? (snapshot.data!.toDouble() * 100).toStringAsFixed(2) : 'N/A')}%',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              );
                                            },
                                          ),
                                          Text(
                                            'Altitude: ${predictionData['ALT']?.toString() ?? 'N/A'} m',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Bright Sunshine: ${predictionData['Bright_Sunshine']?.toString() ?? 'N/A'} hours',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Cloud Coverage: ${predictionData['Cloud_Coverage']?.toString() ?? 'N/A'}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Max Temp: ${predictionData['Max_Temp']?.toString() ?? 'N/A'}°C',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Min Temp: ${predictionData['Min_Temp']?.toString() ?? 'N/A'}°C',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Rainfall: ${predictionData['Rainfall']?.toString() ?? 'N/A'} mm',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Relative Humidity: ${predictionData['Relative_Humidity']?.toString() ?? 'N/A'}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Wind Speed: ${predictionData['Wind_Speed']?.toString() ?? 'N/A'} m/s',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ExpansionTile(
                                        title: const Text(
                                          'Weather Data',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        iconColor: Colors.white,
                                        collapsedIconColor: Colors.white,
                                        childrenPadding:
                                            const EdgeInsets.all(12),
                                        backgroundColor:
                                            Colors.white.withOpacity(0.1),
                                        children: [
                                          Text(
                                            'Current Temp: ${weatherData['current_temp']?.toString() ?? 'N/A'}°C',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Pressure: ${weatherData['pressure']?.toString() ?? 'N/A'} hPa',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Visibility: ${(weatherData['visibility'] != null ? weatherData['visibility'] / 1000 : 'N/A')} km',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Weather Condition: ${weatherData['weather_condition']?.toString() ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Weather Description: ${weatherData['weather_description']?.toString() ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            'Wind Direction: ${weatherData['wind_direction']?.toString() ?? 'N/A'}°',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
