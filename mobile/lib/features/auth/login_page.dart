import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/server_config_dialog.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

/// The single high-end entry point for authenticated Smart Aid workspaces.
///
/// Features a modern, clinical healthcare aesthetic, one-tap demo role fills,
/// fluid input animations, bilingual support (English/Arabic), and strict
/// server-side RBAC alignment.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.showError = false});

  final bool showError;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _organization = TextEditingController();
  final _registrationNumber = TextEditingController();

  bool _registering = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _selectedDemoRole;
  RegistrationType _accountType = RegistrationType.citizen;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (_registering) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _password.removeListener(_onPasswordChanged);
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _organization.dispose();
    _registrationNumber.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final text = _password.text;
    if (text.isEmpty) return 0;
    if (text.length < 8) return 1;
    if (text.length < 12) return 2;
    return 3;
  }

  void _fillDemo(String role, String email) {
    setState(() {
      _selectedDemoRole = role;
      _email.text = email;
      _password.text = 'SmartAidDemo2026!';
      if (_registering) {
        _registering = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider);
    final submitting = session.isLoading;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final error = session.hasError
        ? _errorMessage(l, session.error)
        : widget.showError
        ? l.text('sessionExpired')
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F2FD), AppTheme.background, Color(0xFFFFFFFF)],
            stops: [0.0, 0.36, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Utility Bar with Version Badge, Server IP & Language Toggle
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.navyBlue.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.navyBlue.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'V2.0',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.navyBlue,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Server Settings Button
                          IconButton(
                            tooltip: currentLocale == 'ar'
                                ? 'إعدادات السيرفر'
                                : 'Server Settings',
                            onPressed: () => showServerConfigDialog(
                              context,
                              isArabic: currentLocale == 'ar',
                              onSaved: () => setState(() {}),
                            ),
                            icon: const Icon(Icons.dns_rounded, size: 18),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.navyBlue,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(36, 36),
                              side: const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          // Language switcher button
                          TextButton.icon(
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
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.navyBlue,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: const BorderSide(color: AppTheme.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Brand Hero Icon & Header
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.blue.withValues(alpha: 0.16),
                                blurRadius: 26,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const AppLogo(
                            size: 80,
                            showGlow: false,
                            borderRadius: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // App Title & Tagline
                      Center(
                        child: Text(
                          'Smart Aid',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navyBlue,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.text('smartAidTagline'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Demo Persona Quick-Fill Chips
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.deepNavy.withValues(alpha: 0.045),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppTheme.sky,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    size: 16,
                                    color: AppTheme.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.text('quickDemoFill'),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.navyBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _demoChip(
                                  label: l.text('demoCitizen'),
                                  role: 'CITIZEN',
                                  email: 'demo.user@smartaid.local',
                                  icon: Icons.person_rounded,
                                  color: AppTheme.blue,
                                ),
                                _demoChip(
                                  label: l.text('demoVolunteer'),
                                  role: 'VOLUNTEER',
                                  email: 'demo.volunteer@smartaid.local',
                                  icon: Icons.volunteer_activism_rounded,
                                  color: AppTheme.success,
                                ),
                                _demoChip(
                                  label: l.text('demoEms'),
                                  role: 'EMS',
                                  email: 'demo.ems@smartaid.local',
                                  icon: Icons.emergency_rounded,
                                  color: AppTheme.emergencyRed,
                                ),
                                _demoChip(
                                  label: l.text('demoAdmin'),
                                  role: 'ADMIN',
                                  email: 'demo.admin@smartaid.local',
                                  icon: Icons.admin_panel_settings_rounded,
                                  color: AppTheme.navy,
                                ),
                                _demoChip(
                                  label: currentLocale == 'ar'
                                      ? 'مستشفى'
                                      : 'Hospital',
                                  role: 'HOSPITAL',
                                  email: 'demo.hospital@smartaid.local',
                                  icon: Icons.local_hospital_rounded,
                                  color: const Color(0xFF0284C7),
                                ),
                                _demoChip(
                                  label: currentLocale == 'ar'
                                      ? 'صيدلي'
                                      : 'Pharmacist',
                                  role: 'PHARMACIST',
                                  email: 'demo.pharmacist@smartaid.local',
                                  icon: Icons.local_pharmacy_rounded,
                                  color: const Color(0xFF059669),
                                ),
                                _demoChip(
                                  label: currentLocale == 'ar'
                                      ? 'بنك دم'
                                      : 'Blood Bank',
                                  role: 'BLOOD_BANK_STAFF',
                                  email: 'demo.bloodbank@smartaid.local',
                                  icon: Icons.bloodtype_rounded,
                                  color: const Color(0xFFB91C1C),
                                ),
                                _demoChip(
                                  label: currentLocale == 'ar'
                                      ? 'معمل'
                                      : 'Lab Staff',
                                  role: 'LAB_STAFF',
                                  email: 'demo.lab@smartaid.local',
                                  icon: Icons.science_rounded,
                                  color: const Color(0xFF7C3AED),
                                ),
                                _demoChip(
                                  label: currentLocale == 'ar'
                                      ? 'طبيب'
                                      : 'Doctor',
                                  role: 'DOCTOR',
                                  email: 'demo.doctor@smartaid.local',
                                  icon: Icons.medical_information_rounded,
                                  color: const Color(0xFF0F766E),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Clinical Card Container
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.deepNavy.withValues(alpha: 0.07),
                              blurRadius: 28,
                              spreadRadius: 0,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Interactive Segmented Tab Header (Sign In vs Register)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: submitting
                                        ? null
                                        : () => setState(
                                            () => _registering = false,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !_registering
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: !_registering
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.login_rounded,
                                            size: 18,
                                            color: !_registering
                                                ? AppTheme.navyBlue
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              l.text('signIn'),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontWeight: !_registering
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: !_registering
                                                    ? AppTheme.navyBlue
                                                    : Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: submitting
                                        ? null
                                        : () => setState(
                                            () => _registering = true,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _registering
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _registering
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_add_alt_1_rounded,
                                            size: 18,
                                            color: _registering
                                                ? AppTheme.navyBlue
                                                : Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              l.text('register'),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontWeight: _registering
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: _registering
                                                    ? AppTheme.navyBlue
                                                    : Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Form Subtitle
                          Text(
                            _registering
                                ? l.text('joinEmergencyNetwork')
                                : l.text('secureSignIn'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Demo Role Active Banner
                          if (_selectedDemoRole != null && !_registering) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.blue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.blue.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.blue,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Demo persona loaded: $_selectedDemoRole',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.navyBlue,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(
                                      () => _selectedDemoRole = null,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Error Panel
                          if (error != null) ...[
                            _AuthErrorPanel(
                              message: error,
                              onConfigureServer:
                                  session.hasError &&
                                      session.error is ApiFailure &&
                                      (session.error as ApiFailure)
                                          .isNetworkError
                                  ? () => showServerConfigDialog(
                                      context,
                                      isArabic: currentLocale == 'ar',
                                      onSaved: () => setState(() {}),
                                    )
                                  : null,
                              configureLabel: currentLocale == 'ar'
                                  ? 'تعديل عنوان السيرفر'
                                  : 'Configure Server IP',
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Registration: Full Name
                          if (_registering) ...[
                            TextFormField(
                              controller: _name,
                              enabled: !submitting,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: InputDecoration(
                                labelText: l.text('displayName'),
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                              validator: (value) => AuthFormValidators.required(
                                value,
                                l.text('required'),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _email,
                            enabled: !submitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            decoration: InputDecoration(
                              labelText: l.text('email'),
                              prefixIcon: const Icon(
                                Icons.alternate_email_rounded,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            validator: (value) => AuthFormValidators.email(
                              value,
                              requiredMessage: l.text('required'),
                              invalidMessage: l.text('invalidEmail'),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextFormField(
                            controller: _password,
                            enabled: !submitting,
                            obscureText: _obscurePassword,
                            textInputAction: _registering
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              if (_registering)
                                AutofillHints.newPassword
                              else
                                AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: l.text('password'),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? l.text('showPassword')
                                    : l.text('hidePassword'),
                                onPressed: submitting
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => AuthFormValidators.password(
                              value,
                              requiredMessage: l.text('required'),
                              shortMessage: l.text('passwordLength'),
                              requireLength: _registering,
                            ),
                            onFieldSubmitted: (_) =>
                                _registering ? null : _submit(),
                          ),

                          // Registration: Password Strength Meter
                          if (_registering) ...[_buildPasswordStrengthMeter(l)],

                          // Registration: Confirm Password & Account Type
                          if (_registering) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmation,
                              enabled: !submitting,
                              obscureText: _obscureConfirmation,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: l.text('confirmPassword'),
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmation
                                      ? l.text('showPassword')
                                      : l.text('hidePassword'),
                                  onPressed: submitting
                                      ? null
                                      : () => setState(
                                          () => _obscureConfirmation =
                                              !_obscureConfirmation,
                                        ),
                                  icon: Icon(
                                    _obscureConfirmation
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  AuthFormValidators.confirmPassword(
                                    value,
                                    password: _password.text,
                                    requiredMessage: l.text('required'),
                                    mismatchMessage: l.text('passwordMismatch'),
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l.text('selectPersona'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyBlue,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              children: [
                                _roleCard(
                                  type: RegistrationType.citizen,
                                  title: l.text('citizenAccount'),
                                  subtitle: l.text('citizenDesc'),
                                  icon: Icons.person_rounded,
                                  color: AppTheme.blue,
                                  enabled: !submitting,
                                ),
                                const SizedBox(height: 8),
                                _roleCard(
                                  type: RegistrationType.volunteer,
                                  title: l.text('volunteerAccount'),
                                  subtitle: l.text('volunteerDesc'),
                                  icon: Icons.volunteer_activism_rounded,
                                  color: AppTheme.success,
                                  enabled: !submitting,
                                ),
                                const SizedBox(height: 8),
                                _roleCard(
                                  type: RegistrationType.hospital,
                                  title: l.text('hospitalPartnerAccount'),
                                  subtitle: l.text('hospitalDesc'),
                                  icon: Icons.local_hospital_rounded,
                                  color: AppTheme.emergencyRed,
                                  enabled: !submitting,
                                ),
                              ],
                            ),
                            if (_accountType == RegistrationType.hospital) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _organization,
                                enabled: !submitting,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: l.text('organizationName'),
                                  prefixIcon: const Icon(
                                    Icons.business_rounded,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) =>
                                    AuthFormValidators.required(
                                      value,
                                      l.text('organizationRequired'),
                                    ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _registrationNumber,
                                enabled: !submitting,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: l.text('registrationNumber'),
                                  helperText: l.text('registrationNumberHint'),
                                  prefixIcon: const Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            ],
                          ],
                          const SizedBox(height: 24),

                          // High-impact Submit Button
                          FilledButton(
                            onPressed: submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.navyBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _registering
                                            ? l.text('createAccount')
                                            : l.text('signIn'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // Switch between Login and Register
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () => setState(
                                    () => _registering = !_registering,
                                  ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.blue,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              _registering
                                  ? l.text('switchToLogin')
                                  : l.text('switchToRegister'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security & Disclaimer Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '256-bit Encrypted Emergency Session',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.text('disclaimer'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _demoChip({
    required String label,
    required String role,
    required String email,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedDemoRole == role;
    return InkWell(
      onTap: () => _fillDemo(role, email),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? color : Colors.grey.shade700,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthMeter(AppLocalizations l) {
    final strength = _passwordStrength;
    if (_password.text.isEmpty) return const SizedBox.shrink();

    final Color color;
    final String label;
    if (strength == 1) {
      color = AppTheme.emergencyRed;
      label = l.text('passwordWeak');
    } else if (strength == 2) {
      color = Colors.amber.shade700;
      label = l.text('passwordMedium');
    } else {
      color = AppTheme.success;
      label = l.text('passwordStrong');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 1; i <= 3; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= strength ? color : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l.text('passwordStrength')}:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required RegistrationType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
  }) {
    final isSelected = _accountType == type;
    return InkWell(
      onTap: enabled ? () => setState(() => _accountType = type) : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? AppTheme.navyBlue
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(sessionControllerProvider.notifier);
    if (_registering) {
      await controller.register(
        _email.text.trim(),
        _password.text,
        _name.text.trim(),
        _accountType,
        organizationName: _organization.text.trim(),
        registrationNumber: _registrationNumber.text.trim(),
      );
    } else {
      await controller.login(_email.text.trim(), _password.text);
    }
  }

  String _errorMessage(AppLocalizations l, Object? error) {
    if (error is ApiFailure) {
      if (error.isNetworkError) {
        return l.isArabic
            ? 'تعذّر الاتصال بالخادم، تم تفعيل نمط العمل التلقائي.'
            : 'Could not connect to server, offline mode active.';
      }
      if (error.status == 401) return l.text('authFailed');
    }
    return _registering ? l.text('registerFailed') : l.text('authFailed');
  }
}

class _AuthErrorPanel extends StatelessWidget {
  const _AuthErrorPanel({
    required this.message,
    this.onConfigureServer,
    this.configureLabel,
  });

  final String message;
  final VoidCallback? onConfigureServer;
  final String? configureLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.emergencyRed.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.emergencyRed.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.emergencyRed,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.emergencyRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (onConfigureServer != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.emergencyRed,
                  side: const BorderSide(color: AppTheme.emergencyRed),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onConfigureServer,
                icon: const Icon(Icons.settings_ethernet_rounded, size: 16),
                label: Text(
                  configureLabel ?? 'Server URL',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class AuthFormValidators {
  const AuthFormValidators._();

  static String? required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  static String? email(
    String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final missing = required(value, requiredMessage);
    if (missing != null) return missing;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : invalidMessage;
  }

  static String? password(
    String? value, {
    required String requiredMessage,
    required String shortMessage,
    required bool requireLength,
  }) {
    final missing = required(value, requiredMessage);
    if (missing != null || !requireLength) return missing;
    return value!.length >= 12 ? null : shortMessage;
  }

  static String? confirmPassword(
    String? value, {
    required String password,
    required String requiredMessage,
    required String mismatchMessage,
  }) {
    final missing = required(value, requiredMessage);
    if (missing != null) return missing;
    return value == password ? null : mismatchMessage;
  }
}
