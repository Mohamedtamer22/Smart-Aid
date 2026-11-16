import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider).completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    final slides = [
      _SlideData(
        icon: Icons.emergency,
        iconColor: AppTheme.emergencyRed,
        title: l.text('onboardingTitle1'),
        body: l.text('onboardingBody1'),
      ),
      _SlideData(
        icon: Icons.local_hospital,
        iconColor: AppTheme.oceanBlue,
        title: l.text('onboardingTitle2'),
        body: l.text('onboardingBody2'),
      ),
      _SlideData(
        icon: Icons.shield,
        iconColor: AppTheme.mintTeal,
        title: l.text('onboardingTitle3'),
        body: l.text('onboardingBody3'),
        notice: l.text('permissionsNotice'),
      ),
    ];

    final isLastPage = _currentIndex == slides.length - 1;
    final activeAccent = slides[_currentIndex].iconColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              activeAccent.withValues(alpha: 0.08),
              AppTheme.background,
              Colors.white,
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Language toggle, step counter & Skip button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(appLocaleProvider.notifier)
                            .select(
                              Locale(currentLocale == 'ar' ? 'en' : 'ar'),
                            );
                      },
                      icon: const Icon(Icons.language_rounded, size: 17),
                      label: Text(
                        currentLocale == 'ar' ? 'English' : 'العربية',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (!isLastPage)
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.navyBlue,
                        ),
                        child: Text(
                          l.text('onboardingSkip'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),

              // Carousel Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 164,
                                height: 164,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: slide.iconColor.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                              ),
                              Container(
                                width: 126,
                                height: 126,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.heroGradient(
                                    slide.iconColor,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: slide.iconColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 58,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                              height: 1.55,
                              fontSize: 15,
                            ),
                          ),
                          if (slide.notice != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.sky,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.blue.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    size: 20,
                                    color: AppTheme.blue,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      slide.notice!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.navy,
                                        height: 1.45,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation & Indicators
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? activeAccent
                                : AppTheme.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.navyBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (isLastPage) {
                            _finish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text(
                          isLastPage
                              ? l.text('onboardingGetStarted')
                              : l.text('onboardingNext'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.notice,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? notice;
}
