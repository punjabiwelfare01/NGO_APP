import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_pipeline_models.dart';
import '../../viewmodels/event_pipeline_viewmodel.dart';

class PipelineImpactDraftScreen extends StatefulWidget {
  const PipelineImpactDraftScreen({
    required this.event,
    required this.vm,
    super.key,
  });

  final PipelineEvent event;
  final EventPipelineViewModel vm;

  @override
  State<PipelineImpactDraftScreen> createState() => _PipelineImpactDraftScreenState();
}

class _PipelineImpactDraftScreenState extends State<PipelineImpactDraftScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _descCtrl;
  late final TextEditingController _appreciationCtrl;
  late ImpactPostDraft _draft;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _draft = widget.event.impactDraft!;
    _descCtrl = TextEditingController(text: _draft.description);
    _appreciationCtrl = TextEditingController(text: _draft.appreciationMessage);
    _descCtrl.addListener(_markChanged);
    _appreciationCtrl.addListener(_markChanged);
  }

  void _markChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _tabs.dispose();
    _descCtrl.dispose();
    _appreciationCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.vm.saveImpactDraft(
      widget.event.id,
      description: _descCtrl.text.trim(),
      appreciationMessage: _appreciationCtrl.text.trim(),
    );
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully!'),
        backgroundColor: Color(0xFF00695C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitForApproval() {
    if (_hasChanges) _save();
    widget.vm.submitImpactDraftForApproval(widget.event.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impact post submitted for Admin approval!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final updatedEvent = widget.vm.events.where((e) => e.id == widget.event.id).firstOrNull;
        if (updatedEvent?.impactDraft != null) {
          _draft = updatedEvent!.impactDraft!;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1F44),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
            title: const Text(
              'Impact Post Draft',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
            ),
            actions: [
              if (_hasChanges)
                TextButton(
                  onPressed: _save,
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
            ],
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF7BA8D4),
              indicatorColor: const Color(0xFF41A7F5),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [Tab(text: 'Edit'), Tab(text: 'Preview')],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _EditTab(
                draft: _draft,
                descCtrl: _descCtrl,
                appreciationCtrl: _appreciationCtrl,
              ),
              _PreviewTab(
                draft: _draft,
                descText: _descCtrl.text,
                appreciationText: _appreciationCtrl.text,
              ),
            ],
          ),
          bottomNavigationBar: _BottomBar(
            draft: _draft,
            onSave: _save,
            onSubmit: _submitForApproval,
            hasChanges: _hasChanges,
          ),
        );
      },
    );
  }
}

// ─── Edit Tab ─────────────────────────────────────────────────────────────────

class _EditTab extends StatelessWidget {
  const _EditTab({required this.draft, required this.descCtrl, required this.appreciationCtrl});
  final ImpactPostDraft draft;
  final TextEditingController descCtrl;
  final TextEditingController appreciationCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Auto-generated notice
        if (draft.isAutoGenerated)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This draft was auto-generated from event data. Edit before submitting for Admin approval.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // Stats summary (read-only)
        _StatsSummary(draft: draft),
        const SizedBox(height: 16),

        // Description editor
        _SectionLabel(icon: Icons.description_rounded, label: 'Event Description'),
        const SizedBox(height: 6),
        TextField(
          controller: descCtrl,
          maxLines: 6,
          decoration: _inputDeco('Describe the event, activities, and impact on beneficiaries…'),
        ),
        const SizedBox(height: 16),

        // Appreciation message editor
        _SectionLabel(icon: Icons.volunteer_activism_rounded, label: 'Appreciation Message'),
        const SizedBox(height: 6),
        TextField(
          controller: appreciationCtrl,
          maxLines: 4,
          decoration: _inputDeco('Message of appreciation for volunteers and sponsors…'),
        ),
        const SizedBox(height: 16),

        // Volunteer list (read-only)
        _VolunteersList(draft: draft),
        const SizedBox(height: 16),

        // Photo placeholder
        _PhotosSection(draft: draft),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),
    contentPadding: const EdgeInsets.all(14),
  );
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.draft});
  final ImpactPostDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF6A1B9A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF6A1B9A), size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Impact Summary (auto-filled)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF17324D))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBubble('${draft.totalVolunteers}', 'Volunteers', AppColors.primary),
              const SizedBox(width: 8),
              _StatBubble('${draft.peopleReached}', 'Reached', const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              _StatBubble('₹${draft.donationCollected.toStringAsFixed(0)}', 'Donated', const Color(0xFFF57F17)),
              const SizedBox(width: 8),
              _StatBubble('${draft.certificatesIssued}', 'Certs', const Color(0xFF1565C0)),
            ],
          ),
          if (draft.partnerSchool != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.school_rounded, size: 13, color: AppColors.muted),
                const SizedBox(width: 5),
                Text('Partner: ${draft.partnerSchool}', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _VolunteersList extends StatelessWidget {
  const _VolunteersList({required this.draft});
  final ImpactPostDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Volunteers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF17324D))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: draft.volunteerNames.map((name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(name, style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.draft});
  final ImpactPostDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Event Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF17324D))),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 14),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          if (draft.photoUrls.isEmpty)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.muted.withValues(alpha: 0.2), style: BorderStyle.solid),
              ),
              child: Center(
                child: Text('Tap "Add" to include event photos', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Preview Tab ──────────────────────────────────────────────────────────────

class _PreviewTab extends StatelessWidget {
  const _PreviewTab({required this.draft, required this.descText, required this.appreciationText});
  final ImpactPostDraft draft;
  final String descText;
  final String appreciationText;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo placeholder header
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1F44), Color(0xFF1A3A6C)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(draft.eventCategory.icon, color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        draft.eventName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NGO badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, size: 11, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('Pranam Welfare Trust', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatDate(draft.eventDate), style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      descText.isNotEmpty ? descText : draft.description,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF17324D), height: 1.55),
                    ),
                    const SizedBox(height: 14),

                    // Stats row
                    Row(
                      children: [
                        _PreviewStat('${draft.totalVolunteers}', 'Volunteers', Icons.people_rounded),
                        _PreviewStat('${draft.peopleReached}', 'Reached', Icons.volunteer_activism_rounded),
                        _PreviewStat('${draft.certificatesIssued}', 'Certificates', Icons.workspace_premium_rounded),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(draft.location, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Appreciation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF70D98B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF70D98B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote_rounded, color: Color(0xFF2E7D32), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appreciationText.isNotEmpty ? appreciationText : draft.appreciationMessage,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF2E7D32), fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Volunteer names
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: draft.volunteerNames.map((n) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.muted.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(n, style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Preview of Wall of Impact post',
            style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF17324D))),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.draft, required this.onSave, required this.onSubmit, required this.hasChanges});
  final ImpactPostDraft draft;
  final VoidCallback onSave;
  final VoidCallback onSubmit;
  final bool hasChanges;

  @override
  Widget build(BuildContext context) {
    if (draft.status == ImpactPostDraftStatus.published) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF1B5E20), size: 18),
            const SizedBox(width: 8),
            const Text('Published on Wall of Impact', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.white,
      child: Row(
        children: [
          if (hasChanges) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: onSave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: draft.status == ImpactPostDraftStatus.adminApproved ? null : onSubmit,
              icon: const Icon(Icons.send_rounded, size: 15),
              label: Text(
                draft.status == ImpactPostDraftStatus.emEdited
                    ? 'Awaiting Admin Approval'
                    : 'Submit for Admin Approval',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
