import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'notifications_controller.dart';
import 'notifications_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.text('notifications'))),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => PageFailure(
          title: l.text('notifications'),
          message: l.text('networkError'),
          retryLabel: l.text('retry'),
          onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none_rounded,
                title: l.text('noNotificationsTitle'),
                message: l.text('noNotificationsMessage'),
              )
            : QaPageFrame(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(notificationsProvider.notifier).refresh(),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _NotificationTile(notification: items[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(notification.createdAt.toLocal());
    return QaCard(
      color: notification.read ? null : AppTheme.blue.withValues(alpha: .06),
      child: InkWell(
        onTap: notification.read
            ? null
            : () => ref
                  .read(notificationsProvider.notifier)
                  .markRead(notification.id),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icon(notification.type),
              color: notification.read
                  ? Theme.of(context).colorScheme.outline
                  : AppTheme.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(l, notification.type),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (!notification.read)
              const SizedBox(
                width: 9,
                height: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
    'EMERGENCY_ALERT' => Icons.emergency_outlined,
    'RESPONDER_ASSIGNED' => Icons.volunteer_activism_outlined,
    'AMBULANCE_ASSIGNED' => Icons.emergency_outlined,
    'HOSPITAL_RECOMMENDED' => Icons.local_hospital_outlined,
    _ => Icons.notifications_outlined,
  };
  String _label(AppLocalizations l, String type) => switch (type) {
    'EMERGENCY_ALERT' => l.text('notificationEmergencyAlert'),
    'RESPONDER_ASSIGNED' => l.text('notificationResponderAssigned'),
    'INCIDENT_ACCEPTED' => l.text('notificationIncidentAccepted'),
    'AMBULANCE_ASSIGNED' => l.text('notificationAmbulanceAssigned'),
    'HOSPITAL_RECOMMENDED' => l.text('notificationHospitalRecommended'),
    'STATUS_CHANGED' => l.text('notificationStatusChanged'),
    _ => l.text('notificationSystem'),
  };
}
