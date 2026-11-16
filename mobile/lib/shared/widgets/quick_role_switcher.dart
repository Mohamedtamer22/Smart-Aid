import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_controller.dart';
import 'app_widgets.dart';

class QuickRoleSwitcher extends ConsumerStatefulWidget {
  const QuickRoleSwitcher({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickRoleSwitcher(),
    );
  }

  @override
  ConsumerState<QuickRoleSwitcher> createState() => _QuickRoleSwitcherState();
}

class _QuickRoleSwitcherState extends ConsumerState<QuickRoleSwitcher> {
  String? _switchingEmail;

  Future<void> _switchTo(String email) async {
    setState(() => _switchingEmail = email);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(email, 'SmartAidDemo2026!');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('authFailed')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _switchingEmail = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isAr = l.isArabic;

    final roles = [
      _RoleOption(
        title: l.text('citizenAccount'),
        subtitle: isAr
            ? 'بلاغات SOS، الملف الطبي والخدمات الصحية'
            : 'Emergency SOS, Personal Health & Connected Care',
        email: 'demo.user@smartaid.local',
        icon: Icons.person_rounded,
        badgeColor: AppTheme.blue,
      ),
      _RoleOption(
        title: l.text('volunteerAccount'),
        subtitle: isAr
            ? 'متطوع معتمد، استلام المهام وتتبع الموقع'
            : 'Certified Responder, GPS Beacon & Dispatches',
        email: 'demo.volunteer@smartaid.local',
        icon: Icons.volunteer_activism_rounded,
        badgeColor: AppTheme.mintTeal,
      ),
      _RoleOption(
        title: isAr ? 'مسعف / مركز الإسعاف' : 'EMS Dispatcher',
        subtitle: isAr
            ? 'التوجيه الذكي Smart ER وتسليم الحالات'
            : 'Operations Control Center & Smart ER Dispatch',
        email: 'demo.ems@smartaid.local',
        icon: Icons.emergency_rounded,
        badgeColor: AppTheme.emergencyRed,
      ),
      _RoleOption(
        title: isAr ? 'موظف المستشفى' : 'Hospital Staff',
        subtitle: isAr
            ? 'السعة والأسرّة واستقبال التسليم الطبي'
            : 'Hospital Capacity, ER Beds & Incoming Handovers',
        email: 'demo.hospital@smartaid.local',
        icon: Icons.local_hospital_rounded,
        badgeColor: const Color(0xFF0F766E),
      ),
      _RoleOption(
        title: isAr ? 'الصيدلي' : 'Pharmacist',
        subtitle: isAr
            ? 'إدارة الصيدلية وتجهيز طلبات الأدوية والتوصيل'
            : 'Smart Pharmacy Stock, Orders & Medical Delivery',
        email: 'demo.pharmacist@smartaid.local',
        icon: Icons.local_pharmacy_rounded,
        badgeColor: const Color(0xFF0369A1),
      ),
      _RoleOption(
        title: isAr ? 'بنك الدم' : 'Blood Bank Staff',
        subtitle: isAr
            ? 'فصائل الدم والرد على طلبات الدم الطارئة'
            : 'Smart Blood Bank Inventory & Emergency Requests',
        email: 'demo.bloodbank@smartaid.local',
        icon: Icons.bloodtype_rounded,
        badgeColor: const Color(0xFFB91C1C),
      ),
      _RoleOption(
        title: isAr ? 'موظف المعمل' : 'Laboratory Staff',
        subtitle: isAr
            ? 'إدارة حجوزات التحاليل والنتائج المصرح بها'
            : 'Smart Lab Appointments & Authorized Results',
        email: 'demo.lab@smartaid.local',
        icon: Icons.biotech_rounded,
        badgeColor: const Color(0xFF6D28D9),
      ),
      _RoleOption(
        title: isAr ? 'الطبيب' : 'Doctor',
        subtitle: isAr
            ? 'مواعيد العيادات والاستشارات والمتابعة الطبية'
            : 'Smart Medical Services & Clinical Appointments',
        email: 'demo.doctor@smartaid.local',
        icon: Icons.medical_services_rounded,
        badgeColor: const Color(0xFF047857),
      ),
      _RoleOption(
        title: isAr ? 'مدير النظام / ECC' : 'System Administrator',
        subtitle: isAr
            ? 'لوحة القيادة المركزية ECC والاعتمادات وسجل التدقيق'
            : 'Executive KPIs, Roster, Verifications & Audit',
        email: 'demo.admin@smartaid.local',
        icon: Icons.admin_panel_settings_rounded,
        badgeColor: AppTheme.navy,
      ),
    ];

    final maxSheetHeight = MediaQuery.of(context).size.height * 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppTheme.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Aid V2 Workspace',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'تبديل فوري بين جميع أدوار المنظومة التسعة (9 أدوار)'
                            : 'Switch personas instantly across all 9 system roles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...roles.map((role) {
                      final isSwitchingThis = _switchingEmail == role.email;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QaCard(
                          padding: EdgeInsets.zero,
                          borderColor: role.badgeColor.withValues(alpha: 0.24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius,
                            ),
                            onTap: _switchingEmail != null
                                ? null
                                : () => _switchTo(role.email),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          role.badgeColor.withValues(
                                            alpha: 0.16,
                                          ),
                                          role.badgeColor.withValues(
                                            alpha: 0.06,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: role.badgeColor.withValues(
                                          alpha: 0.24,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      role.icon,
                                      color: role.badgeColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role.title,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          role.subtitle,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSwitchingThis)
                                    const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: role.badgeColor.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.email,
    required this.icon,
    required this.badgeColor,
  });

  final String title;
  final String subtitle;
  final String email;
  final IconData icon;
  final Color badgeColor;
}
