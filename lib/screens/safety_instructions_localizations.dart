// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// class SafetyInstructionsLocalizations {
//   final Locale locale;

//   SafetyInstructionsLocalizations(this.locale);

//   static SafetyInstructionsLocalizations of(BuildContext context) {
//     return Localizations.of<SafetyInstructionsLocalizations>(
//         context, SafetyInstructionsLocalizations)!;
//   }

//   static const _localizedValues = {
//     'en': {
//       'safety_instructions_title': 'Safety Instructions',
//       'safety_instructions': [
//         'Stay away from low-lying areas, valleys, and waterways as they are most prone to flooding.',
//         'Do not cross closed or flooded roads or bridges, as the current may be strong and invisible.',
//         'Continuously follow weather forecasts and meteorological warnings.',
//         'Evacuate your home if ordered to do so and head to safe locations or designated shelters.',
//         'Avoid touching or approaching wet or fallen electrical wires to prevent electric shock.',
//         'Turn off electricity, gas, and water sources before leaving the home.',
//         'Avoid driving on flooded roads, as water may reach the engine, causing the vehicle to stall or be swept away by currents.',
//         'Keep emergency supplies such as water, dry food, a flashlight, extra batteries, and emergency medications.',
//         'Stay calm, avoid panic, and keep away from sources of danger.',
//       ],
//     },
//     'ar': {
//       'safety_instructions_title': 'تعليمات السلامة',
//       'safety_instructions': [
//         'الابتعاد عن المناطق المنخفضة والمنخفضات والمجاري المائية لأنها الأكثر عرضة للفيضان.',
//         'عدم عبور الطرق أو الجسور المغلقة أو المغمورة بالمياه لأن التيار قد يكون قويًا وغير مرئي.',
//         'تابع نشرات الطقس وتنبؤات الأرصاد الجوية باستمرار.',
//         'إخلاء المنزل إذا تم إصدار أوامر بذلك والتوجه إلى أماكن آمنة أو مراكز إيواء مخصصة.',
//         'عدم لمس أو الاقتراب من الأسلاك الكهربائية المبللة أو المتساقطة لتجنب الصعق الكهربائي.',
//         'أغلق مصادر الكهرباء والغاز والمياه قبل مغادرة المنزل.',
//         'تجنب استخدام السيارات في الطرق المغمورة بالمياه لأن المياه قد تصل إلى المحرك وتوقف السيارة أو تجرّها التيارات.',
//         'الاحتفاظ بأدوات الطوارئ مثل المياه، الطعام الجاف، المصباح اليدوي، بطاريات إضافية، وأدوية الطوارئ.',
//         'البقاء هادئًا وعدم الذعر، والابتعاد عن مصادر الخطر.',
//       ],
//     },
//   };

//   String get safetyInstructionsTitle {
//     return _localizedValues[locale.languageCode]!['safety_instructions_title']
//         as String;
//   }

//   List<String> get safetyInstructions {
//     return (_localizedValues[locale.languageCode]!['safety_instructions']
//             as List<dynamic>)
//         .cast<String>();
//   }

//   static const LocalizationsDelegate<SafetyInstructionsLocalizations> delegate =
//       _SafetyInstructionsLocalizationsDelegate();
// }

// class _SafetyInstructionsLocalizationsDelegate
//     extends LocalizationsDelegate<SafetyInstructionsLocalizations> {
//   const _SafetyInstructionsLocalizationsDelegate();

//   @override
//   bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

//   @override
//   Future<SafetyInstructionsLocalizations> load(Locale locale) {
//     return SynchronousFuture<SafetyInstructionsLocalizations>(
//         SafetyInstructionsLocalizations(locale));
//   }

//   @override
//   bool shouldReload(_SafetyInstructionsLocalizationsDelegate old) => false;
// }
