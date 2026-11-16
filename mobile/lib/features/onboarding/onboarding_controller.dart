import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _onboardingKey = 'onboarding_completed_v1';

final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingKey) ?? false;
});

final onboardingControllerProvider = Provider<OnboardingController>(
  (ref) => OnboardingController(ref),
);

class OnboardingController {
  OnboardingController(this._ref);
  final Ref _ref;

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _ref.invalidate(isOnboardingCompletedProvider);
  }
}
