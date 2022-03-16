import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations);

  static List<String> languages() => ['en', 'cs'];

  String get languageCode => locale.languageCode;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.languageCode] ?? '';

  String getVariableText({
    String enText = '',
    String csText = '',
  }) =>
      [enText, csText][languageIndex] ?? '';
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      FFLocalizations.languages().contains(locale.languageCode);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // HomePage
  {
    't6g7ug7y': {
      'en': 'Hello World sad',
      'cs': '',
    },
    'dfo7byll': {
      'en': 'Hello World',
      'cs': '',
    },
    '6mk4humm': {
      'en': 'Page Title',
      'cs': '',
    },
    '5toz4v7d': {
      'en': 'Home',
      'cs': '',
    },
  },
  // Page2
  {
    'fdx9p6gq': {
      'en': 'Button',
      'cs': '',
    },
    'e7kn9yiu': {
      'en': 'Page Title',
      'cs': '',
    },
    'wgepykkm': {
      'en': 'Home',
      'cs': '',
    },
  },
  // Page3
  {
    'gcgrj7ak': {
      'en': 'Title',
      'cs': '',
    },
    'z18hjx2o': {
      'en': 'Subtitle',
      'cs': '',
    },
    'vugxphq0': {
      'en': 'Title',
      'cs': '',
    },
    'h9pccnrv': {
      'en': 'Subtitle',
      'cs': '',
    },
    '84souwlk': {
      'en': 'Page Title',
      'cs': '',
    },
    'r9cwxcgd': {
      'en': 'Home',
      'cs': '',
    },
  },
  // Page4
  {
    'f90eyngt': {
      'en': 'Home',
      'cs': '',
    },
  },
  // Page5
  {
    'vb4sff2c': {
      'en': 'Page Title',
      'cs': 'Titulek',
    },
    '2qz8zkf5': {
      'en': 'Home',
      'cs': 'Domu',
    },
  },
  // Page6
  {
    'gl0my9lq': {
      'en': 'Page Title',
      'cs': '',
    },
    '44u6gfx6': {
      'en': 'Home',
      'cs': '',
    },
  },
  // Page7
  {
    'gtufrjh5': {
      'en': 'Option 1',
      'cs': '',
    },
    'cllogn5z': {
      'en': 'Option 1',
      'cs': '',
    },
    's3avr3zp': {
      'en': 'Select Location',
      'cs': '',
    },
    'm11a5iqh': {
      'en': 'Page Title',
      'cs': '',
    },
    'p0k5pdok': {
      'en': 'Home',
      'cs': '',
    },
  },
  // Drawers
  {
    'ovbuppcl': {
      'en': 'Page Title',
      'cs': '',
    },
    'b1xgd2gj': {
      'en': 'Home',
      'cs': '',
    },
  },
  // DevicesPage
  {
    'cwpbaufx': {
      'en': 'Page Title',
      'cs': '',
    },
    '2s8tjp7r': {
      'en': 'Home',
      'cs': '',
    },
  },
].reduce((a, b) => a..addAll(b));
