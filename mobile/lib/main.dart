import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  runApp(const ProviderScope(child: SmartAidApp()));
}

class SmartAidApp extends ConsumerWidget {
  const SmartAidApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Smart Aid',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.build(),
    locale: ref
        .watch(appLocaleProvider)
        .when(
          data: (locale) => locale ?? const Locale('ar'),
          loading: () => const Locale('ar'),
          error: (_, _) => const Locale('ar'),
        ),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    onGenerateTitle: (context) => AppLocalizations.of(context).text('appName'),
    home: const SplashPage(),
  );
}
