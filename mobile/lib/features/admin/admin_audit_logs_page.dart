import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'admin_controller.dart';
import 'admin_repository.dart';

class AdminAuditLogsPage extends ConsumerStatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  ConsumerState<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends ConsumerState<AdminAuditLogsPage> {
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('auditLogs')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminAuditLogsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l.text('search'),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _query = val.toLowerCase()),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l.text('all')),
                        selected: _filter == 'all',
                        onSelected: (_) => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('INCIDENT'),
                        selected: _filter == 'INCIDENT',
                        onSelected: (_) => setState(() => _filter = 'INCIDENT'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('USER'),
                        selected: _filter == 'USER',
                        onSelected: (_) => setState(() => _filter = 'USER'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('VOLUNTEER'),
                        selected: _filter == 'VOLUNTEER',
                        onSelected: (_) =>
                            setState(() => _filter = 'VOLUNTEER'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('DISASTER'),
                        selected: _filter == 'DISASTER',
                        onSelected: (_) => setState(() => _filter = 'DISASTER'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.emergencyRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.text('error'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(adminAuditLogsProvider),
                        child: Text(l.text('retry')),
                      ),
                    ],
                  ),
                ),
              ),
              data: (logs) {
                final filtered = logs.where((entry) {
                  final matchesQuery =
                      _query.isEmpty ||
                      entry.action.toLowerCase().contains(_query) ||
                      entry.entityType.toLowerCase().contains(_query) ||
                      (entry.actorId?.toLowerCase().contains(_query) ??
                          false) ||
                      (entry.traceId?.toLowerCase().contains(_query) ?? false);
                  final matchesFilter =
                      _filter == 'all' ||
                      entry.entityType.toUpperCase() == _filter;
                  return matchesQuery && matchesFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.text('noNotificationsTitle'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _AuditLogCard(entry: entry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.entry});

  final AuditLogEntry entry;

  Color _actionColor(String action) {
    if (action.contains('DELETE') ||
        action.contains('SUSPEND') ||
        action.contains('CANCEL')) {
      return AppTheme.emergencyRed;
    }
    if (action.contains('CREATE') ||
        action.contains('VERIF') ||
        action.contains('ACTIVATE')) {
      return AppTheme.success;
    }
    if (action.contains('UPDATE') || action.contains('ROLE')) {
      return AppTheme.oceanBlue;
    }
    return AppTheme.charcoal;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final actionColor = _actionColor(entry.action);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.action,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: actionColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${entry.entityType}${entry.entityId != null ? ' #${entry.entityId!.substring(0, entry.entityId!.length > 8 ? 8 : entry.entityId!.length)}' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (entry.actorId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${l.text('actor')}: ${entry.actorId!.substring(0, entry.actorId!.length > 8 ? 8 : entry.actorId!.length)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
          if (entry.traceId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.fingerprint, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Trace: ${entry.traceId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)} ${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}:${_twoDigits(dt.second)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
