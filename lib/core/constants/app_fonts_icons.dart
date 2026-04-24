import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Typography ─────────────────────────────────────────────────────────────────
// Rajdhani  → headings, numbers, HUD values  (sporty, condensed)
// Inter     → body, labels, descriptions     (clean, readable)

class AppFonts {
  AppFonts._();

  // ── Heading styles ─────────────────────────────────────────────────────────
  static TextStyle heading({
    double size = 28,
    FontWeight weight = FontWeight.bold,
    Color color = Colors.white,
    double letterSpacing = 2,
  }) => GoogleFonts.rajdhani(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  // ── HUD / numeric display ──────────────────────────────────────────────────
  static TextStyle hud({
    double size = 38,
    FontWeight weight = FontWeight.w700,
    Color color = const Color(0xFFFF6B00),
    double height = 1,
  }) => GoogleFonts.rajdhani(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  // ── Body / label ───────────────────────────────────────────────────────────
  static TextStyle body({
    double size = 13,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double letterSpacing = 0,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  // ── Caption / micro label ──────────────────────────────────────────────────
  static TextStyle caption({
    double size = 10,
    Color? color,
    double letterSpacing = 0.5,
  }) => GoogleFonts.inter(
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
  );

  // ── Section header (all-caps) ──────────────────────────────────────────────
  static TextStyle sectionHeader({
    double size = 11,
    Color color = const Color(0xFFFF6B00),
  }) => GoogleFonts.rajdhani(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 2,
  );

  // ── Button label ───────────────────────────────────────────────────────────
  static TextStyle button({double size = 15, Color color = Colors.white}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );
}

// ── Icon aliases ───────────────────────────────────────────────────────────────
// Centralised so swapping an icon only needs one edit.

class AppIcons {
  AppIcons._();

  // Navigation / UI
  static const settings = FontAwesomeIcons.gear;
  static const back = FontAwesomeIcons.arrowLeft;
  static const close = FontAwesomeIcons.xmark;
  static const check = FontAwesomeIcons.check;
  static const info = FontAwesomeIcons.circleInfo;
  static const warning = FontAwesomeIcons.triangleExclamation;
  static const delete = FontAwesomeIcons.trash;
  static const add = FontAwesomeIcons.plus;
  static const history = FontAwesomeIcons.clockRotateLeft;

  // Bike / ride
  static const motorcycle = FontAwesomeIcons.motorcycle;
  static const ignition = FontAwesomeIcons.powerOff;
  static const speedometer = FontAwesomeIcons.gaugeHigh;
  static const route = FontAwesomeIcons.route;
  static const flag = FontAwesomeIcons.flagCheckered;
  static const compass = FontAwesomeIcons.compass;
  static const navigation = FontAwesomeIcons.locationArrow;

  // Fuel / wallet
  static const fuel = FontAwesomeIcons.gasPump;
  static const wallet = FontAwesomeIcons.wallet;
  static const rupee = FontAwesomeIcons.indianRupeeSign;
  static const costPerKm = FontAwesomeIcons.road;

  // Stats
  static const distance = FontAwesomeIcons.ruler;
  static const timer = FontAwesomeIcons.stopwatch;
  static const avgSpeed = FontAwesomeIcons.chartLine;
  static const maxSpeed = FontAwesomeIcons.boltLightning;
  static const chart = FontAwesomeIcons.chartBar;
  static const trendUp = FontAwesomeIcons.arrowTrendUp;

  // Weather / environment
  static const thermometer = FontAwesomeIcons.temperatureHalf;
  static const heatWarning = FontAwesomeIcons.sun;

  // Map
  static const mapStandard = FontAwesomeIcons.map;
  static const mapDark = FontAwesomeIcons.moon;
  static const mapSatellite = FontAwesomeIcons.satellite;
  static const locate = FontAwesomeIcons.locationCrosshairs;
  static const locating = FontAwesomeIcons.spinner;

  // Auth / gate
  static const fingerprint = FontAwesomeIcons.fingerprint;
  static const locationOff = FontAwesomeIcons.locationCrosshairs;
  static const lock = FontAwesomeIcons.lock;

  // Theme / language
  static const darkMode = FontAwesomeIcons.moon;
  static const lightMode = FontAwesomeIcons.sun;
  static const language = FontAwesomeIcons.language;

  // Connectivity
  static const offline = FontAwesomeIcons.wifi;
  static const online = FontAwesomeIcons.wifi;

  // Play / stop
  static const play = FontAwesomeIcons.play;
  static const stop = FontAwesomeIcons.stop;
}
