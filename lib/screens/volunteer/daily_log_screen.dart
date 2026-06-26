import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/volunteer_models.dart';
import '../../viewmodels/volunteer_viewmodel.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({required this.vm, super.key});
  final VolunteerViewModel vm;

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Logbook',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => setState(() => _showForm = true),
            tooltip: 'New Log',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          return Column(
            children: [
              if (_showForm)
                _LogEntryForm(
                  onSaved: () => setState(() => _showForm = false),
                  vm: widget.vm,
                ),
              Expanded(
                child: widget.vm.logs.isEmpty
                    ? _EmptyState(
                        onAdd: () => setState(() => _showForm = true))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.vm.logs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _LogCard(log: widget.vm.logs[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogEntryForm extends StatefulWidget {
  const _LogEntryForm({required this.vm, required this.onSaved});
  final VolunteerViewModel vm;
  final VoidCallback onSaved;

  @override
  State<_LogEntryForm> createState() => _LogEntryFormState();
}

class _LogEntryFormState extends State<_LogEntryForm> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _reflectionCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _reflectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your log entry')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.vm.createLog(
      date: _date,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      reflection: _reflectionCtrl.text.trim().isEmpty
          ? null
          : _reflectionCtrl.text.trim(),
    );
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('New Log Entry',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      fontSize: 15)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context);
                  if (context.mounted) widget.onSaved();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Date
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: _inputDeco('Log title (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: _inputDeco(
                'What did you do today? Who did you help? (required)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reflectionCtrl,
            maxLines: 2,
            decoration: _inputDeco('What did you learn today? (optional)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(_saving ? 'Saving…' : 'Save Log'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.muted.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.muted.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      );
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});
  final DailyLog log;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (log.status) {
      'approved'  => AppColors.secondary,
      'submitted' => AppColors.accent,
      _           => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${log.date.day}/${log.date.month}/${log.date.year}',
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.isPublic ? 'Public' : log.status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (log.title != null) ...[
            const SizedBox(height: 6),
            Text(
              log.title!,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 14),
            ),
          ],
          if (log.content != null) ...[
            const SizedBox(height: 6),
            Text(
              log.content!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
          ],
          if (log.reflection != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      log.reflection!,
                      style: const TextStyle(
                          color: AppColors.ink, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.book_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No log entries yet',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text(
              'Start documenting your social work journey. Daily logs build your verified volunteer portfolio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Write First Log'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
