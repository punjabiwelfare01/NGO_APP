import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/emergency_contact.dart';
import '../../../repositories/emergency_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/top_header.dart';

class EmergencyContactsAdminScreen extends StatefulWidget {
  const EmergencyContactsAdminScreen({super.key});

  @override
  State<EmergencyContactsAdminScreen> createState() =>
      _EmergencyContactsAdminScreenState();
}

class _EmergencyContactsAdminScreenState
    extends State<EmergencyContactsAdminScreen> {
  ViewState _state = ViewState.loading;
  List<EmergencyContact> _contacts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = ViewState.loading;
      _error = null;
    });
    try {
      final contacts = await EmergencyRepository.getAllContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _state = ViewState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = ViewState.error;
        _error = 'Could not load emergency contacts.';
      });
    }
  }

  void _showAddSheet() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactFormSheet(
        onSave: (name, phone, description) async {
          Navigator.of(context).pop();
          try {
            await EmergencyRepository.createContact(
              name: name,
              phone: phone,
              description: description,
            );
            await _load();
            messenger.showSnackBar(
              const SnackBar(content: Text('Emergency contact added.')),
            );
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Failed to add contact.')),
            );
          }
        },
      ),
    );
  }

  void _showEditSheet(EmergencyContact contact) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactFormSheet(
        initial: contact,
        onSave: (name, phone, description) async {
          Navigator.of(context).pop();
          try {
            await EmergencyRepository.updateContact(
              contact.id,
              name: name,
              phone: phone,
              description: description,
            );
            await _load();
            messenger.showSnackBar(
              const SnackBar(content: Text('Contact updated.')),
            );
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Failed to update contact.')),
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleActive(EmergencyContact contact) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await EmergencyRepository.updateContact(
        contact.id,
        isActive: !contact.isActive,
      );
      await _load();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to update status.')),
      );
    }
  }

  Future<void> _delete(EmergencyContact contact) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Delete "${contact.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.softRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await EmergencyRepository.deleteContact(contact.id);
      await _load();
      messenger.showSnackBar(
        const SnackBar(content: Text('Contact deleted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete contact.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Contact'),
        backgroundColor: AppColors.softRed,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const TopHeader(
              title: 'Emergency Contacts',
              subtitle: 'Manage support team numbers shown to all users',
              actionIcon: Icons.emergency_rounded,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_state == ViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_state == ViewState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Error',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_missed_rounded,
                size: 56, color: AppColors.softRed.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No emergency contacts yet.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap + Add Contact to add one.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _contacts.length,
      itemBuilder: (_, i) => _ContactTile(
        contact: _contacts[i],
        onEdit: () => _showEditSheet(_contacts[i]),
        onToggle: () => _toggleActive(_contacts[i]),
        onDelete: () => _delete(_contacts[i]),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        color: contact.isActive
            ? AppColors.softRed.withValues(alpha: 0.07)
            : Colors.white,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (contact.isActive ? AppColors.softRed : AppColors.muted)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_rounded,
                color: contact.isActive ? AppColors.softRed : AppColors.muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: TextStyle(
                      color: contact.isActive ? AppColors.ink : AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    contact.phone,
                    style: const TextStyle(
                        color: AppColors.softRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  if (contact.description != null)
                    Text(
                      contact.description!,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: contact.isActive
                          ? AppColors.secondary.withValues(alpha: 0.18)
                          : AppColors.muted.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      contact.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: contact.isActive
                            ? AppColors.secondary
                            : AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'toggle') onToggle();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    const Icon(Icons.edit_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text('Edit'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      contact.isActive
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(contact.isActive ? 'Deactivate' : 'Activate'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_rounded,
                        size: 18, color: AppColors.softRed),
                    const SizedBox(width: 8),
                    const Text('Delete',
                        style: TextStyle(color: AppColors.softRed)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactFormSheet extends StatefulWidget {
  const _ContactFormSheet({required this.onSave, this.initial});

  final EmergencyContact? initial;
  final void Function(String name, String phone, String? description) onSave;

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _description =
      TextEditingController(text: widget.initial?.description);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final desc = _description.text.trim();
    widget.onSave(
      _name.text.trim(),
      _phone.text.trim(),
      desc.isEmpty ? null : desc,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency_rounded,
                      color: AppColors.softRed, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    widget.initial == null
                        ? 'Add Emergency Contact'
                        : 'Edit Emergency Contact',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(
                  labelText: 'Contact Name *',
                  hintText: 'e.g. Child Helpline, Mental Health Support',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g. 1098, +91 98765 43210',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Phone is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Available 24/7 for children in distress',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(widget.initial == null
                      ? 'Add Contact'
                      : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.softRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
