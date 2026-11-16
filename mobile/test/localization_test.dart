import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/core/localization/app_localizations.dart';

void main() {
  test('Arabic and English emergency actions are localized', () {
    expect(const AppLocalizations(Locale('en')).text('sendSos'), 'SEND SOS');
    expect(
      const AppLocalizations(Locale('ar')).text('sendSos'),
      'إرسال استغاثة',
    );
  });
}
