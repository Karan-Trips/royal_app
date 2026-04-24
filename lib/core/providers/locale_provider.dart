import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() => const Locale('en');

  void setLocale(BuildContext context, Locale locale) {
    state = locale;
    context.setLocale(locale);
  }
}
