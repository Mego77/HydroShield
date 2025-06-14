import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/screens/city_chat_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch location when the screen loads
    Future.delayed(Duration.zero, () {
      Provider.of<WeatherProvider>(context, listen: false).refreshLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<WeatherProvider>(context);
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'community_chats'.tr(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: locationProvider.cityName == null
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          ChatButton(
                            title: 'current_city_chat'.tr(),
                            subtitle:
                                locationProvider.cityName ?? 'loading'.tr(),
                            icon: Icons.location_city,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CityChatScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ChatButton(
                            title: 'alexandria_chat'.tr(),
                            subtitle: 'connect_alexandria'.tr(),
                            icon: Icons.chat,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CityChatScreen(
                                    isAlexandriaChat: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ChatButton(
                            title: 'customer_support'.tr(),
                            subtitle: 'get_help'.tr(),
                            icon: Icons.support_agent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CityChatScreen(
                                    isSupportChat: true,
                                  ),
                                ),
                              );
                            },
                            showNotification: true,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool showNotification;

  const ChatButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.showNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.indigo.shade800, Colors.indigo.shade900]
                  : [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.amber.shade300 : Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    if (showNotification)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('GP3_chats')
                            .doc(
                                'support_${FirebaseAuth.instance.currentUser!.uid}')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.exists &&
                              snapshot.data!.get('hasUnreadWarning') == true) {
                            return Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.black : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
