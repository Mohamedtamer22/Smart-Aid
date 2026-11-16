import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLocaleProvider = AsyncNotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);

class AppLocaleController extends AsyncNotifier<Locale?> {
  static const _key = 'selected_locale';
  @override
  FutureOr<Locale?> build() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_key);
    // Defaults to Arabic ('ar') for all users unless explicitly changed
    return code == null ? const Locale('ar') : Locale(code);
  }

  Future<void> select(Locale? locale) async {
    state = AsyncData(locale);
    final preferences = await SharedPreferences.getInstance();
    if (locale == null) {
      await preferences.remove(_key);
    } else {
      await preferences.setString(_key, locale.languageCode);
    }
  }

  Future<void> toggle() async {
    final current = state.value?.languageCode ?? 'ar';
    final next = current == 'ar' ? const Locale('en') : const Locale('ar');
    await select(next);
  }
}
