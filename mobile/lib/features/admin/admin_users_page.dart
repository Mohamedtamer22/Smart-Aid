import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'admin_controller.dart';
import 'admin_repository.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _query = '';
  bool _working = false;

  Future<void> _toggleStatus(UserSummary user) async {
    setState(() => _working = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateUserStatus(user.id, !user.enabled);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminOverviewProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).text('error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _editRoles(UserSummary user) async {
    final l = AppLocalizations.of(context);
    final availableRoles = ['USER', 'VOLUNTEER', 'EMS', 'ADMIN'];
    final selectedRoles = Set<String>.from(user.roles);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.text('selectRoles')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableRoles.map((role) {
              final isChecked = selectedRoles.contains(role);
              return CheckboxListTile(
                title: Text(role),
                value: isChecked,
                onChanged: (val) {
                  setDialogState(() {
                    if (val == true) {
                      selectedRoles.add(role);
                    } else if (selectedRoles.length > 1) {
                      selectedRoles.remove(role);
                    }
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.text('save')),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() => _working = true);
      try {
        await ref
            .read(adminRepositoryProvider)
            .updateUserRoles(user.id, selectedRoles.toList());
        ref.invalidate(adminUsersProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.text('rolesUpdated'))));
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.text('error'))));
        }
      } finally {
        if (mounted) setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.text('userManagement')),
        actions: [
          IconButton(
            onPressed: _working
                ? null
                : () => ref.invalidate(adminUsersProvider),
            icon: const Icon(Icons.refresh),
            tooltip: l.text('refresh'),
          ),
        ],
      ),
      body: QaPageFrame(
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: l.text('search'),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (val) =>
                  setState(() => _query = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => PageFailure(
                  title: l.text('userManagement'),
                  message: l.text('error'),
                  retryLabel: l.text('retry'),
                  onRetry: () => ref.invalidate(adminUsersProvider),
                ),
                data: (users) {
                  final filtered = users.where((u) {
                    if (_query.isEmpty) return true;
                    return u.displayName.toLowerCase().contains(_query) ||
                        u.email.toLowerCase().contains(_query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.person_off_outlined,
                      title: l.text('userManagement'),
                      message: l.text('unavailableData'),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return QaCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.blue.withValues(
                                alpha: .12,
                              ),
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppTheme.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName.isEmpty
                                        ? user.email
                                        : user.displayName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    user.email,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: user.roles
                                        .map(
                                          (r) => StatusPill(
                                            label: r,
                                            color: r == 'ADMIN'
                                                ? AppTheme.emergencyRed
                                                : r == 'EMS'
                                                ? AppTheme.warning
                                                : AppTheme.blue,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.manage_accounts_outlined),
                              tooltip: l.text('selectRoles'),
                              onPressed: _working
                                  ? null
                                  : () => _editRoles(user),
                            ),
                            IconButton(
                              icon: Icon(
                                user.enabled ? Icons.check_circle : Icons.block,
                                color: user.enabled
                                    ? AppTheme.success
                                    : AppTheme.emergencyRed,
                              ),
                              tooltip: user.enabled
                                  ? l.text('enabled')
                                  : l.text('disabled'),
                              onPressed: _working
                                  ? null
                                  : () => _toggleStatus(user),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
