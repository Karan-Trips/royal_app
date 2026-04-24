import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';

enum MapStyle { standard, dark, satellite }

extension MapStyleExt on MapStyle {
  String get label => switch (this) {
    MapStyle.standard => 'Standard',
    MapStyle.dark => 'Dark',
    MapStyle.satellite => 'Satellite',
  };

  // Material icon (kept for any legacy usage)
  IconData get icon => switch (this) {
    MapStyle.standard => Icons.map_outlined,
    MapStyle.dark => Icons.nights_stay_outlined,
    MapStyle.satellite => Icons.satellite_alt_outlined,
  };

  // Font Awesome icon
  FaIconData get faIcon => switch (this) {
    MapStyle.standard => AppIcons.mapStandard,
    MapStyle.dark => AppIcons.mapDark,
    MapStyle.satellite => AppIcons.mapSatellite,
  };

  String get urlTemplate => switch (this) {
    MapStyle.standard => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    MapStyle.dark =>
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    MapStyle.satellite =>
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  List<String> get subdomains => switch (this) {
    MapStyle.dark => ['a', 'b', 'c', 'd'],
    _ => [],
  };
}
