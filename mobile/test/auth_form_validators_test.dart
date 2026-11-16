import 'package:flutter_test/flutter_test.dart';
import 'package:smartaid_mobile/features/auth/login_page.dart';

void main() {
  group('AuthFormValidators', () {
    test('requires a syntactically valid email address', () {
      expect(
        AuthFormValidators.email(
          'not-an-email',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        'invalid',
      );
      expect(
        AuthFormValidators.email(
          'person@smartaid.local',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        isNull,
      );
    });

    test('requires a twelve-character registration password and match', () {
      expect(
        AuthFormValidators.password(
          'short',
          requiredMessage: 'required',
          shortMessage: 'short',
          requireLength: true,
        ),
        'short',
      );
      expect(
        AuthFormValidators.confirmPassword(
          'different',
          password: 'long-enough-password',
          requiredMessage: 'required',
          mismatchMessage: 'mismatch',
        ),
        'mismatch',
      );
    });
  });
}
