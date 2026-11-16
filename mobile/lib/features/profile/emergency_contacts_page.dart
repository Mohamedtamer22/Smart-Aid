import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'profile_controller.dart';
import 'profile_repository.dart';

class EmergencyContactsPage extends ConsumerWidget {
  const EmergencyContactsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final contacts = ref.watch(emergencyContactsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.text('emergencyContacts'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.text('addContact')),
      ),
      body: contacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => PageFailure(
          title: l.text('emergencyContacts'),
          message: l.text('contactSaveFailed'),
          retryLabel: l.text('retry'),
          onRetry: () => ref.read(emergencyContactsProvider.notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.contacts_outlined,
                title: l.text('contactsEmptyTitle'),
                message: l.text('contactsEmptyMessage'),
                action: FilledButton.icon(
                  onPressed: () => _edit(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(l.text('addContact')),
                ),
              )
            : QaPageFrame(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _ContactCard(
                    contact: items[index],
                    onEdit: () => _edit(context, ref, items[index]),
                    onDelete: () => _delete(context, ref, items[index]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    EmergencyContactData? existing,
  ]) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactEditor(contact: existing),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    EmergencyContactData contact,
  ) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.text('deleteContactTitle')),
        content: Text(l.text('deleteContactBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
            ),
            child: Text(l.text('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .deleteContact(contact.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.text('contactDeleteFailed'))));
      }
    }
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });
  final EmergencyContactData contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return QaCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.blue.withValues(alpha: .12),
            foregroundColor: AppTheme.blue,
            child: Text(
              contact.fullName.isEmpty
                  ? '?'
                  : contact.fullName[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contact.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (contact.primary)
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xffF79009),
                        semanticLabel: '',
                      ),
                  ],
                ),
                if (contact.relationship != null)
                  Text(
                    contact.relationship!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 2),
                Text(contact.phone),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l.text('editContact'))),
              PopupMenuItem(
                value: 'delete',
                child: Text(l.text('deleteContact')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactEditor extends ConsumerStatefulWidget {
  const _ContactEditor({this.contact});
  final EmergencyContactData? contact;
  @override
  ConsumerState<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends ConsumerState<_ContactEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.contact?.fullName ?? '',
  );
  late final _relationship = TextEditingController(
    text: widget.contact?.relationship ?? '',
  );
  late final _phone = TextEditingController(text: widget.contact?.phone ?? '');
  late bool _primary = widget.contact?.primary ?? false;
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .saveContact(
            EmergencyContactData(
              id: widget.contact?.id ?? '',
              fullName: _name.text,
              relationship: _relationship.text,
              phone: _phone.text,
              primary: _primary,
            ),
          );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.text('contactSaveFailed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.text(widget.contact == null ? 'addContact' : 'editContact'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                decoration: InputDecoration(labelText: l.text('fullName')),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l.text('required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationship,
                enabled: !_saving,
                decoration: InputDecoration(labelText: l.text('relationship')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l.text('phone')),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l.text('required')
                    : null,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _primary,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _primary = value),
                title: Text(l.text('primaryContact')),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l.text(_saving ? 'saving' : 'save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
