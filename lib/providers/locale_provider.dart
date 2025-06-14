import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> setLocale(BuildContext context, Locale locale) async {
  if (_locale != locale) {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    await context.setLocale(locale); // 👈 this tells EasyLocalization to switch
    notifyListeners();
  }
}


  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('locale') ?? 'en';
    _locale = Locale(localeCode);
    notifyListeners();
  }
}