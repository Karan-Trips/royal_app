import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;

  void toggle() => state =
      state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}
