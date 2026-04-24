import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Typography ─────────────────────────────────────────────────────────────────
// All sizes use .sp — scales automatically across every screen via ScreenUtil.
// Design baseline: 390×844 (iPhone 14).
// Rajdhani → headings, numbers, HUD values
// Inter    → body, labels, captions

class AppFonts {
  AppFonts._();

  static TextStyle heading({
    double size = 28,
    FontWeight weight = FontWeight.bold,
    Color color = Colors.white,
    double letterSpacing = 2,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle hud({
    double size = 38,
    FontWeight weight = FontWeight.w700,
    Color color = const Color(0xFFFF6B00),
    double height = 1,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle body({
    double size = 13,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle caption({
    double size = 10,
    Color? color,
    double letterSpacing = 0.5,
  }) =>
      GoogleFonts.inter(
        fontSize: size.sp,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle sectionHeader({
    double size = 11,
    Color color = const Color(0xFFFF6B00),
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size.sp,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 2,
      );

  static TextStyle button({
    double size = 15,
    Color color = Colors.white,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size.sp,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );
}

// ── Icon aliases ───────────────────────────────────────────────────────────────

class AppIcons {
  AppIcons._();

  // Navigation / UI
  static const settings   = FontAwesomeIcons.gear;
  static const back       = FontAwesomeIcons.arrowLeft;
  static const close      = FontAwesomeIcons.xmark;
  static const check      = FontAwesomeIcons.check;
  static const info       = FontAwesomeIcons.circleInfo;
  static const warning    = FontAwesomeIcons.triangleExclamation;
  static const delete     = FontAwesomeIcons.trash;
  static const add        = FontAwesomeIcons.plus;
  static const history    = FontAwesomeIcons.clockRotateLeft;

  // Bike / ride
  static const motorcycle = FontAwesomeIcons.motorcycle;
  static const ignition   = FontAwesomeIcons.powerOff;
  static const speedometer = FontAwesomeIcons.gaugeHigh;
  static const route      = FontAwesomeIcons.route;
  static const flag       = FontAwesomeIcons.flagCheckered;
  static const compass    = FontAwesomeIcons.compass;
  static const navigation = FontAwesomeIcons.locationArrow;

  // Fuel / wallet
  static const fuel       = FontAwesomeIcons.gasPump;
  static const wallet     = FontAwesomeIcons.wallet;
  static const rupee      = FontAwesomeIcons.indianRupeeSign;
  static const costPerKm  = FontAwesomeIcons.road;

  // Stats
  static const distance   = FontAwesomeIcons.ruler;
  static const timer      = FontAwesomeIcons.stopwatch;
  static const avgSpeed   = FontAwesomeIcons.chartLine;
  static const maxSpeed   = FontAwesomeIcons.boltLightning;
  static const chart      = FontAwesomeIcons.chartBar;
  static const trendUp    = FontAwesomeIcons.arrowTrendUp;

  // Weather / environment
  static const thermometer = FontAwesomeIcons.temperatureHalf;
  static const heatWarning = FontAwesomeIcons.sun;

  // Map
  static const mapStandard = FontAwesomeIcons.map;
  static const mapDark     = FontAwesomeIcons.moon;
  static const mapSatellite = FontAwesomeIcons.satellite;
  static const locate      = FontAwesomeIcons.locationCrosshairs;
  static const locating    = FontAwesomeIcons.spinner;

  // Auth / gate
  static const fingerprint = FontAwesomeIcons.fingerprint;
  static const locationOff = FontAwesomeIcons.locationCrosshairs;
  static const lock        = FontAwesomeIcons.lock;

  // Theme / language
  static const darkMode    = FontAwesomeIcons.moon;
  static const lightMode   = FontAwesomeIcons.sun;
  static const language    = FontAwesomeIcons.language;

  // Connectivity
  static const offline     = FontAwesomeIcons.wifi;
  static const online      = FontAwesomeIcons.wifi;

  // Play / stop
  static const play        = FontAwesomeIcons.play;
  static const stop        = FontAwesomeIcons.stop;
}
