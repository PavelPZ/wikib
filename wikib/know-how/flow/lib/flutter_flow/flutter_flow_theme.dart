// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';
SharedPreferences _prefs;

abstract class FlutterFlowTheme {
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? DarkModeTheme()
          : LightModeTheme();

  Color primaryColor;
  Color secondaryColor;
  Color tertiaryColor;
  Color alternate;
  Color primaryBackground;
  Color secondaryBackground;
  Color primaryText;
  Color secondaryText;

  Color richBlackFOGRA39;
  Color blue;
  Color turquoise;
  Color cultured;
  Color cerise;
  Color charcoal;
  Color persianGreen;
  Color maizeCrayola;
  Color sandyBrown;
  Color burntSienna;
  Color red;
  Color darkOrange;
  Color cyberYellow;
  Color chartreuseTraditional;
  Color springBud;
  Color mediumSpringGreen;
  Color electricBlue;
  Color azure;
  Color hanPurple;
  Color electricPurple;
  Color customColor1;
  Color customColor2;
  Color customColor3;

  TextStyle get title1 => GoogleFonts.getFont(
        'Poppins',
        color: primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      );
  TextStyle get title2 => GoogleFonts.getFont(
        'Poppins',
        color: secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      );
  TextStyle get title3 => GoogleFonts.getFont(
        'Poppins',
        color: primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      );
  TextStyle get subtitle1 => GoogleFonts.getFont(
        'Poppins',
        color: primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );
  TextStyle get subtitle2 => GoogleFonts.getFont(
        'Poppins',
        color: secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      );
  TextStyle get bodyText1 => GoogleFonts.getFont(
        'Poppins',
        color: primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      );
  TextStyle get bodyText2 => GoogleFonts.getFont(
        'Poppins',
        color: secondaryText,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      );
}

class LightModeTheme extends FlutterFlowTheme {
  Color primaryColor = const Color(0xFF4B39EF);
  Color secondaryColor = const Color(0xFF39D2C0);
  Color tertiaryColor = const Color(0xFFEE8B60);
  Color alternate = const Color(0xFFFF5963);
  Color primaryBackground = const Color(0xFFFFFFFF);
  Color secondaryBackground = const Color(0xFFF1F4F8);
  Color primaryText = const Color(0xFF091249);
  Color secondaryText = const Color(0xFF57636C);

  Color richBlackFOGRA39 = Color(0xFF070707);
  Color blue = Color(0xFF3A28DE);
  Color turquoise = Color(0xFF34D1BF);
  Color cultured = Color(0xFFEFEFEF);
  Color cerise = Color(0xFFD1345B);
  Color charcoal = Color(0xFF264653);
  Color persianGreen = Color(0xFF2A9D8F);
  Color maizeCrayola = Color(0xFFE9C46A);
  Color sandyBrown = Color(0xFFF4A261);
  Color burntSienna = Color(0xFFE76F51);
  Color red = Color(0xFFFF0000);
  Color darkOrange = Color(0xFFFF8700);
  Color cyberYellow = Color(0xFFFFD300);
  Color chartreuseTraditional = Color(0xFFDEFF0A);
  Color springBud = Color(0xFFA1FF0A);
  Color mediumSpringGreen = Color(0xFF0AFF99);
  Color electricBlue = Color(0xFF0AEFFF);
  Color azure = Color(0xFF147DF5);
  Color hanPurple = Color(0xFF580AFF);
  Color electricPurple = Color(0xFFBE0AFF);
  Color customColor1 = Color(0xFF7A7516);
  Color customColor2 = Color(0xFF863A6F);
  Color customColor3 = Color(0xFF7DC4FA);
}

class DarkModeTheme extends FlutterFlowTheme {
  Color primaryColor = const Color(0xFF4B39EF);
  Color secondaryColor = const Color(0xFF39D2C0);
  Color tertiaryColor = const Color(0xFFEE8B60);
  Color alternate = const Color(0xFFFF5963);
  Color primaryBackground = const Color(0xFF091249);
  Color secondaryBackground = const Color(0xFF1D2429);
  Color primaryText = const Color(0xFFFFFFFF);
  Color secondaryText = const Color(0xFF95A1AC);

  Color richBlackFOGRA39 = Color(0xFF070707);
  Color blue = Color(0xFF3A28DE);
  Color turquoise = Color(0xFF34D1BF);
  Color cultured = Color(0xFFEFEFEF);
  Color cerise = Color(0xFFD1345B);
  Color charcoal = Color(0xFF264653);
  Color persianGreen = Color(0xFF2A9D8F);
  Color maizeCrayola = Color(0xFFE9C46A);
  Color sandyBrown = Color(0xFFF4A261);
  Color burntSienna = Color(0xFFE76F51);
  Color red = Color(0xFFFF0000);
  Color darkOrange = Color(0xFFFF8700);
  Color cyberYellow = Color(0xFFFFD300);
  Color chartreuseTraditional = Color(0xFFDEFF0A);
  Color springBud = Color(0xFFA1FF0A);
  Color mediumSpringGreen = Color(0xFF0AFF99);
  Color electricBlue = Color(0xFF0AEFFF);
  Color azure = Color(0xFF147DF5);
  Color hanPurple = Color(0xFF580AFF);
  Color electricPurple = Color(0xFFBE0AFF);
  Color customColor1 = Color(0xFF7A7516);
  Color customColor2 = Color(0xFF863A6F);
  Color customColor3 = Color(0xFF7DC4FA);
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    String fontFamily,
    Color color,
    double fontSize,
    FontWeight fontWeight,
    FontStyle fontStyle,
    bool useGoogleFonts = true,
    double lineHeight,
  }) =>
      useGoogleFonts
          ? GoogleFonts.getFont(
              fontFamily,
              color: color ?? this.color,
              fontSize: fontSize ?? this.fontSize,
              fontWeight: fontWeight ?? this.fontWeight,
              fontStyle: fontStyle ?? this.fontStyle,
              height: lineHeight,
            )
          : copyWith(
              fontFamily: fontFamily,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              height: lineHeight,
            );
}
