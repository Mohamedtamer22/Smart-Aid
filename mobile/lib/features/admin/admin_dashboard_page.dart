import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/language_toggle_button.dart';
import '../analytics/analytics_page.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../disaster/disaster_management_page.dart';
import '../resources/nearby_resources_page.dart';
import 'admin_audit_logs_page.dart';
import 'admin_controller.dart';
import 'admin_repository.dart';
import 'admin_users_page.dart';
import 'admin_volunteers_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isAr = l.isArabic;
    final overviewAsync = ref.watch(adminOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffEF4444), AppTheme.emergencyRed],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.text('adminDashboard'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const LanguageToggleButton(isCompact: true),
          IconButton(
            tooltip: l.text('retry'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminOverviewProvider),
          ),
          IconButton(
            tooltip: l.text('signOut'),
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: QaPageFrame(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminOverviewProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Elevated Admin Command Hero
              QaHeroCard(
                eyebrow: isAr ? 'القيادة المركزية • ECC' : 'ECC GOVERNANCE',
                title: session.displayName.isNotEmpty
                    ? session.displayName
                    : session.email,
                message: isAr
                    ? 'إدارة الحسابات، اعتماد المتطوعين، مؤشرات Smart ER، وسجل التدقيق الأمني.'
                    : 'Manage platform accounts, field volunteer licenses, Smart ER KPIs, and immutable audit trails.',
                icon: Icons.admin_panel_settings_rounded,
                color: AppTheme.navyBlue,
              ),
              const SizedBox(height: 20),

              // Overview KPIs
              SectionHeader(title: l.text('systemOverview')),
              const SizedBox(height: 12),
              overviewAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.warning),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.text('error'))),
                      TextButton(
                        onPressed: () => ref.invalidate(adminOverviewProvider),
                        child: Text(l.text('retry')),
                      ),
                    ],
                  ),
                ),
                data: (overview) => _OverviewGrid(overview: overview),
              ),
              const SizedBox(height: 22),

              // Navigation Actions
              SectionHeader(title: l.text('managementActions')),
              const SizedBox(height: 12),

              _AdminNavCard(
                icon: Icons.manage_accounts_rounded,
                iconColor: AppTheme.oceanBlue,
                title: l.text('userManagement'),
                subtitle: isAr
                    ? 'عرض قائمة المستخدمين، تعديل الأدوار التسعة وتفعيل الحسابات'
                    : 'View user roster, update roles, toggle account status',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminUsersPage()),
                ),
              ),
              const SizedBox(height: 10),

              _AdminNavCard(
                icon: Icons.verified_user_rounded,
                iconColor: AppTheme.mintTeal,
                title: l.text('volunteerApprovals'),
                subtitle: isAr
                    ? 'مراجعة الشهادات واعتماد المتطوعين للتدخل السريع'
                    : 'Review certifications and approve field volunteer licenses',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminVolunteersPage(),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _AdminNavCard(
                icon: Icons.emergency_rounded,
                iconColor: AppTheme.emergencyRed,
                title: l.text('disasterManagement'),
                subtitle: isAr
                    ? 'بروتوكول فرز الإصابات START وإدارة الكوارث الجماعية'
                    : 'START triage protocol, multi-casualty incident board',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DisasterManagementPage(),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _AdminNavCard(
                icon: Icons.analytics_rounded,
                iconColor: AppTheme.indigo,
                title: l.text('analytics'),
                subtitle: isAr
                    ? 'مؤشرات الأداء التشغيلية ومقارنة التوجيه الذكي Smart ER'
                    : 'EOC operational KPIs & Smart ER scientific evaluation',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalyticsPage()),
                ),
              ),
              const SizedBox(height: 10),

              _AdminNavCard(
                icon: Icons.local_hospital_rounded,
                iconColor: Colors.teal,
                title: l.text('resources'),
                subtitle: isAr
                    ? 'المستشفيات المعتمدة وأجهزة الصدمات الكهربائية AED'
                    : 'Hospitals and verified life-saving AED registry',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NearbyResourcesPage(),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _AdminNavCard(
                icon: Icons.receipt_long_rounded,
                iconColor: AppTheme.charcoal,
                title: l.text('auditLogs'),
                subtitle: isAr
                    ? 'سجل عمليات أمني غير قابل للتعديل مع تفاصيل المنفذين'
                    : 'Traceable immutable operations history with actors and events',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminAuditLogsPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.overview});

  final SystemOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 560 ? 4 : 2;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.48,
          children: [
            _KpiTile(
              label: l.text('totalUsers'),
              value: '${overview.totalUsers}',
              icon: Icons.people_rounded,
              color: AppTheme.oceanBlue,
            ),
            _KpiTile(
              label: l.text('totalVolunteers'),
              value: '${overview.totalVolunteers}',
              icon: Icons.volunteer_activism_rounded,
              color: AppTheme.mintTeal,
            ),
            _KpiTile(
              label: l.text('pendingVerifications'),
              value: '${overview.pendingVolunteerVerifications}',
              icon: Icons.pending_actions_rounded,
              color: overview.pendingVolunteerVerifications > 0
                  ? AppTheme.warning
                  : AppTheme.textMuted,
            ),
            _KpiTile(
              label: l.text('activeIncidents'),
              value: '${overview.activeIncidents}',
              icon: Icons.warning_amber_rounded,
              color: overview.activeIncidents > 0
                  ? AppTheme.emergencyRed
                  : AppTheme.success,
            ),
            _KpiTile(
              label: l.text('totalHospitals'),
              value: '${overview.totalHospitals}',
              icon: Icons.local_hospital_rounded,
              color: Colors.teal,
            ),
            _KpiTile(
              label: l.text('totalAmbulances'),
              value: '${overview.totalAmbulances}',
              icon: Icons.airport_shuttle_rounded,
              color: AppTheme.navy,
            ),
            _KpiTile(
              label: l.text('totalAeds'),
              value: '${overview.totalAeds}',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD97706),
            ),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return QaCard(
      padding: const EdgeInsets.all(13),
      borderColor: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavCard extends StatelessWidget {
  const _AdminNavCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QaCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                      iconColor.withValues(alpha: 0.16),
                      iconColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
