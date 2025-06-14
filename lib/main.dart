import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:weather_app/firebase_options.dart';
import 'package:weather_app/providers/locale_provider.dart';
import 'package:weather_app/providers/theme_provider.dart';
import 'package:weather_app/providers/vote_provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/providers/auth_provider.dart' as myAuth;

import 'package:weather_app/screens/login_screen.dart';
import 'package:weather_app/master_page.dart';
import 'package:weather_app/screens/admin_support_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  await themeProvider.loadTheme();
  await localeProvider.loadLocale();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<WeatherProvider>(create: (_) => WeatherProvider()),
          ChangeNotifierProvider<myAuth.AuthProvider>(create: (_) => myAuth.AuthProvider()),
          ChangeNotifierProvider<VoteProvider>(create: (_) => VoteProvider()),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            cardColor: const Color(0xFF1E1E2E),
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: Colors.tealAccent,
            iconTheme: const IconThemeData(color: Colors.tealAccent),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white70),
              titleMedium: TextStyle(color: Colors.white),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.white,
            ),
          ),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: Provider.of<LocaleProvider>(context).locale,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<myAuth.AuthProvider>(context);

    if (authProvider.user != null) {
      return authProvider.isAdmin
          ? const AdminSupportScreen()
          : const MasterPage();
    } else {
      return const LoginScreen();
    }
  }
}
