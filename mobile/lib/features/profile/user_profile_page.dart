import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../notifications/notifications_controller.dart';
import '../notifications/notifications_page.dart';
import '../training/training_courses_page.dart';
import 'emergency_contacts_page.dart';
import 'medical_profile_page.dart';
import 'profile_controller.dart';
import 'settings_page.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.session});
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly pre-warm profile data in memory so pages open instantaneously
    ref.watch(medicalProfileProvider);
    ref.watch(emergencyContactsProvider);
    ref.watch(notificationsProvider);

    final l = AppLocalizations.of(context);
    final primaryRole = session.roles.isEmpty ? 'USER' : session.roles.first;

    return QaPageFrame(
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient(AppTheme.blue),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.blue.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: .2),
                    foregroundColor: Colors.white,
                    child: Text(
                      session.displayName.isEmpty
                          ? '?'
                          : session.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayName.isEmpty
                            ? session.email
                            : session.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        session.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: .88),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          primaryRole,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(title: l.text('account')),
          const SizedBox(height: 10),
          QaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _row(
                  context,
                  Icons.medical_information_rounded,
                  AppTheme.emergencyRed,
                  l.text('medicalProfile'),
                  () => _go(context, const MedicalProfilePage()),
                ),
                const Divider(height: 1),
                _row(
                  context,
                  Icons.contacts_rounded,
                  AppTheme.blue,
                  l.text('emergencyContacts'),
                  () => _go(context, const EmergencyContactsPage()),
                ),
                const Divider(height: 1),
                _row(
                  context,
                  Icons.notifications_active_rounded,
                  AppTheme.warning,
                  l.text('notifications'),
                  () => _go(context, const NotificationsPage()),
                ),
                const Divider(height: 1),
                _row(
                  context,
                  Icons.workspace_premium_rounded,
                  AppTheme.mintTeal,
                  l.text('training'),
                  () => _go(context, const TrainingCoursesPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(title: l.text('settings')),
          const SizedBox(height: 10),
          QaCard(
            padding: EdgeInsets.zero,
            child: _row(
              context,
              Icons.settings_rounded,
              AppTheme.navyBlue,
              l.text('settings'),
              () => _go(context, const SettingsPage()),
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.emergencyRed,
              side: BorderSide(
                color: AppTheme.emergencyRed.withValues(alpha: 0.35),
              ),
            ),
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.text('signOut')),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    Color accent,
    String title,
    VoidCallback onTap,
  ) => ListTile(
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: accent, size: 20),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AppTheme.textMuted,
    ),
    onTap: onTap,
    minVerticalPadding: 14,
  );

  void _go(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
