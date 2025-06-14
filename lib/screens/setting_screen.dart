import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:weather_app/providers/theme_provider.dart';
import 'package:weather_app/providers/locale_provider.dart';
import 'package:weather_app/providers/auth_provider.dart' as myAuth;
import 'package:weather_app/screens/login_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdating = false;
  late TabController _tabController;
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Reduced length to 4
    _videoController = VideoPlayerController.asset('assets/videos/alertVideo.mp4')
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoInitialize: true,
            autoPlay: false,
            looping: false,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text(
                  'Error loading video: $errorMessage',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.redAccent
                        : Colors.red,
                  ),
                ),
              );
            },
            materialProgressColors: ChewieProgressColors(
              playedColor: Colors.blue,
              handleColor: Colors.blueAccent,
              backgroundColor: Colors.grey,
              bufferedColor: Colors.grey.withOpacity(0.5),
            ),
            placeholder: const Center(child: CircularProgressIndicator()),
            aspectRatio: _videoController.value.aspectRatio,
          );
        });
      }).catchError((error, stackTrace) {
        setState(() {
          _videoError = error.toString();
        });
        print('Video initialization error: $error\nStack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load video: $error')),
        );
      });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> instructions = List.generate(
      9,
      (index) => 'safety_instructions.${index + 1}'.tr(),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final authProvider = Provider.of<myAuth.AuthProvider>(context, listen: false);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

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
          title: Text(
            'settings'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: isDark ? Colors.tealAccent : Colors.blue,
            labelColor: isDark ? Colors.tealAccent : Colors.blue,
            unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
            tabs: [
              Tab(text: 'general_settings'.tr()),
              Tab(text: 'update_name'.tr()),
              Tab(text: 'update_password'.tr()),
              Tab(text: 'video'.tr()),
            ], // Removed Flood Status tab
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // General Settings Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'dark_mode'.tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Switch(
                                value: isDarkMode,
                                onChanged: (value) {
                                  themeProvider.toggleTheme(value);
                                },
                                activeColor: isDark ? Colors.tealAccent : Colors.blue,
                                activeTrackColor: isDark
                                    ? Colors.tealAccent.withOpacity(0.5)
                                    : Colors.blue.withOpacity(0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'language'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.tealAccent : Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: DropdownButton<Locale>(
                              value: localeProvider.locale,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: Locale('en'),
                                  child: Text('English'),
                                ),
                                DropdownMenuItem(
                                  value: Locale('ar'),
                                  child: Text('العربية'),
                                ),
                              ],
                              onChanged: (Locale? newLocale) async {
                                if (newLocale != null) {
                                  await localeProvider.setLocale(context, newLocale);
                                  if (mounted) {
                                    setState(() {});
                                  }
                                }
                              },
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              dropdownColor: isDark ? Colors.black87 : Colors.white,
                              underline: const SizedBox(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await authProvider.logout();
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('logged_out'.tr())),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('logout_failed'.tr())),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              label: Text(
                                'logout'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.redAccent : Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Name Update Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'update_name'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'enter_new_name'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.tealAccent.withOpacity(0.5)
                                      : Colors.blue.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.white,
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () async {
                                      if (_nameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('name_required'.tr())),
                                        );
                                        return;
                                      }
                                      setState(() => _isUpdating = true);
                                      try {
                                        await authProvider.updateDisplayName(
                                            _nameController.text.trim());
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('name_updated'.tr())),
                                        );
                                        _nameController.clear();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('update_failed'.tr())),
                                        );
                                      } finally {
                                        setState(() => _isUpdating = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.tealAccent : Colors.blue,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'update_name'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Password Update Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'update_password'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(
                              hintText: 'current_password'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.tealAccent.withOpacity(0.5)
                                      : Colors.blue.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.white,
                            ),
                            obscureText: true,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              hintText: 'new_password'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.tealAccent.withOpacity(0.5)
                                      : Colors.blue.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.white,
                            ),
                            obscureText: true,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: 'confirm_password'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.tealAccent.withOpacity(0.5)
                                      : Colors.blue.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.tealAccent : Colors.blue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.white,
                            ),
                            obscureText: true,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () async {
                                      if (_currentPasswordController.text.isEmpty ||
                                          _newPasswordController.text.isEmpty ||
                                          _confirmPasswordController.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('all_fields_required'.tr())),
                                        );
                                        return;
                                      }
                                      if (_newPasswordController.text !=
                                          _confirmPasswordController.text) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('passwords_dont_match'.tr())),
                                        );
                                        return;
                                      }
                                      setState(() => _isUpdating = true);
                                      try {
                                        await authProvider.updatePassword(
                                          _currentPasswordController.text,
                                          _newPasswordController.text,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('password_updated'.tr())),
                                        );
                                        _currentPasswordController.clear();
                                        _newPasswordController.clear();
                                        _confirmPasswordController.clear();
                                      } catch (e) {
                                        String errorMessage = 'update_failed'.tr();
                                        if (e.toString().contains('reauthenticate')) {
                                          errorMessage = 'incorrect_current_password'.tr();
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(errorMessage)),
                                        );
                                      } finally {
                                        setState(() => _isUpdating = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.tealAccent : Colors.blue,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'update_password'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Video Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'video'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _videoError != null
                              ? Text(
                                  'Error loading video: $_videoError',
                                  style: TextStyle(
                                    color: isDark ? Colors.redAccent : Colors.red,
                                  ),
                                )
                              : _videoController.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio: _videoController.value.aspectRatio,
                                      child: Chewie(
                                        controller: _chewieController,
                                      ),
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: _videoError != null ||
                                      !_videoController.value.isInitialized
                                  ? null
                                  : () {
                                      setState(() {
                                        if (_videoController.value.isPlaying) {
                                          _videoController.pause();
                                          _chewieController.pause();
                                        } else {
                                          _videoController.play();
                                          _chewieController.play();
                                        }
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.tealAccent : Colors.blue,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                _videoController.value.isPlaying
                                    ? 'pause'.tr()
                                    : 'play'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'safety_instructions_title'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(9, (index) {
                            final instruction = 'safety_instructions.${index + 1}'.tr();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}. ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      instruction,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ], // Removed FloodStatusTab
        ),
      ),
    );
  }
}