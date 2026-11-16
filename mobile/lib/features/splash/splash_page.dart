import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../admin/admin_dashboard_page.dart';
import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import '../ems/ems_dashboard_page.dart';
import '../healthcare/organization_portal_page.dart';
import '../home/home_page.dart';
import '../onboarding/onboarding_controller.dart';
import '../onboarding/onboarding_page.dart';
import '../volunteer/volunteer_dashboard_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final onboardingAsync = ref.watch(isOnboardingCompletedProvider);
    final sessionAsync = ref.watch(sessionControllerProvider);

    if (!onboardingAsync.isLoading && !sessionAsync.isLoading) {
      final onboardingDone = onboardingAsync.value ?? false;
      if (!onboardingDone) {
        return const OnboardingPage();
      }

      return sessionAsync.when(
        loading: () => _buildSplashScaffold(l),
        error: (_, _) => const LoginPage(showError: true),
        data: (session) {
          if (session == null) {
            return const LoginPage();
          }
          if (session.roles.contains('ADMIN')) {
            return AdminDashboardPage(session: session);
          }
          if (session.roles.contains('EMS')) {
            return EmsDashboardPage(session: session);
          }
          if (session.roles.contains('VOLUNTEER')) {
            return VolunteerDashboardPage(session: session);
          }
          if (session.roles.contains('HOSPITAL') ||
              session.roles.contains('PHARMACIST') ||
              session.roles.contains('BLOOD_BANK_STAFF') ||
              session.roles.contains('LAB_STAFF') ||
              session.roles.contains('DOCTOR')) {
            return OrganizationPortalPage(session: session);
          }
          return HomePage(session: session);
        },
      );
    }

    return _buildSplashScaffold(l);
  }

  Widget _buildSplashScaffold(AppLocalizations l) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.blue.withValues(alpha: 0.22),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.mintTeal.withValues(alpha: 0.16),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: const AppLogo(size: 108),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'V2.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.text('appName'),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Text(
                            l.text('tagline'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 44),
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
