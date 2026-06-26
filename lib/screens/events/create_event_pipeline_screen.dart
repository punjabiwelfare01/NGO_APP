import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../models/event_manager_models.dart';
import '../../viewmodels/event_pipeline_viewmodel.dart';

class CreateEventPipelineScreen extends StatefulWidget {
  const CreateEventPipelineScreen({required this.vm, super.key});
  final EventPipelineViewModel vm;

  @override
  State<CreateEventPipelineScreen> createState() => _CreateEventPipelineScreenState();
}

class _CreateEventPipelineScreenState extends State<CreateEventPipelineScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  static const _totalSteps = 4;

  // Step 1 — Basic info
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _partnerSchoolCtrl = TextEditingController();
  EventCategory _category = EventCategory.workshop;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  bool _isOnline = false;

  // Step 2 — Volunteer setup
  int _maxVolunteers = 10;
  bool _certificateEligible = true;
  bool _donationEligible = false;
  bool _stipendEligible = false;
  double _stipendAmount = 0;
  final _expectedWorkCtrl = TextEditingController();
  final _proofRequiredCtrl = TextEditingController();

  // Step 3 — Activities
  final List<_ActivityDraft> _activities = [];

  // Step 4 — Settings
  bool _reportRequired = true;
  bool _impactPostEligible = true;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _partnerSchoolCtrl.dispose();
    _expectedWorkCtrl.dispose();
    _proofRequiredCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else {
      _createEvent();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _createEvent() {
    if (_titleCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Color(0xFFC62828), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // In a real app, this would call vm.createEvent(). For now, show success.
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event created successfully! It is now in Draft status.'),
        backgroundColor: Color(0xFF00695C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _titleCtrl.text.trim().isNotEmpty && _locationCtrl.text.trim().isNotEmpty;
      case 1:
        return _maxVolunteers > 0;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        leading: IconButton(
          onPressed: _prevStep,
          icon: Icon(_step == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        title: Text(
          _stepTitle(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _totalSteps,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF41A7F5)),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Row(
              children: List.generate(_totalSteps, (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.primary : AppColors.muted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1BasicInfo(
                  titleCtrl: _titleCtrl,
                  descCtrl: _descCtrl,
                  locationCtrl: _locationCtrl,
                  partnerSchoolCtrl: _partnerSchoolCtrl,
                  category: _category,
                  eventDate: _eventDate,
                  isOnline: _isOnline,
                  onCategoryChanged: (v) => setState(() => _category = v),
                  onDateChanged: (v) => setState(() => _eventDate = v),
                  onOnlineChanged: (v) => setState(() => _isOnline = v),
                  onChanged: () => setState(() {}),
                ),
                _Step2VolunteerSetup(
                  maxVolunteers: _maxVolunteers,
                  certificateEligible: _certificateEligible,
                  donationEligible: _donationEligible,
                  stipendEligible: _stipendEligible,
                  stipendAmount: _stipendAmount,
                  expectedWorkCtrl: _expectedWorkCtrl,
                  proofRequiredCtrl: _proofRequiredCtrl,
                  onMaxVolunteersChanged: (v) => setState(() => _maxVolunteers = v),
                  onCertChanged: (v) => setState(() => _certificateEligible = v),
                  onDonationChanged: (v) => setState(() => _donationEligible = v),
                  onStipendChanged: (v) => setState(() => _stipendEligible = v),
                  onStipendAmountChanged: (v) => setState(() => _stipendAmount = v),
                ),
                _Step3Activities(
                  activities: _activities,
                  onAdd: (a) => setState(() => _activities.add(a)),
                  onRemove: (i) => setState(() => _activities.removeAt(i)),
                ),
                _Step4Settings(
                  reportRequired: _reportRequired,
                  impactPostEligible: _impactPostEligible,
                  title: _titleCtrl.text,
                  category: _category,
                  location: _locationCtrl.text,
                  eventDate: _eventDate,
                  maxVolunteers: _maxVolunteers,
                  activitiesCount: _activities.length,
                  onReportChanged: (v) => setState(() => _reportRequired = v),
                  onImpactChanged: (v) => setState(() => _impactPostEligible = v),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canProceed ? _nextStep : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _step < _totalSteps - 1 ? 'Continue' : 'Create Event',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    const titles = ['Basic Info', 'Volunteer Setup', 'Activities', 'Review & Create'];
    return 'Step ${_step + 1}: ${titles[_step]}';
  }
}

// ─── Step 1 ───────────────────────────────────────────────────────────────────

class _Step1BasicInfo extends StatelessWidget {
  const _Step1BasicInfo({
    required this.titleCtrl,
    required this.descCtrl,
    required this.locationCtrl,
    required this.partnerSchoolCtrl,
    required this.category,
    required this.eventDate,
    required this.isOnline,
    required this.onCategoryChanged,
    required this.onDateChanged,
    required this.onOnlineChanged,
    required this.onChanged,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController partnerSchoolCtrl;
  final EventCategory category;
  final DateTime eventDate;
  final bool isOnline;
  final ValueChanged<EventCategory> onCategoryChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _FieldLabel('Event Title *'),
        _input(titleCtrl, 'e.g. Stationery Drive — Patiala', onChanged: onChanged),
        const SizedBox(height: 14),
        _FieldLabel('Category *'),
        const SizedBox(height: 6),
        _CategorySelector(value: category, onChanged: onCategoryChanged),
        const SizedBox(height: 14),
        _FieldLabel('Description'),
        _input(descCtrl, 'Describe the event, goals and expected outcomes…', maxLines: 4),
        const SizedBox(height: 14),
        _FieldLabel('Event Date *'),
        const SizedBox(height: 6),
        _DatePicker(date: eventDate, onChanged: onDateChanged),
        const SizedBox(height: 14),
        SwitchListTile.adaptive(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          value: isOnline,
          onChanged: onOnlineChanged,
          title: const Text('Online Event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text('Event will be conducted via video call', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
          activeThumbColor: AppColors.primary,
        ),
        const SizedBox(height: 14),
        _FieldLabel(isOnline ? 'Meeting Link' : 'Location / Venue *'),
        _input(locationCtrl, isOnline ? 'https://meet.google.com/…' : 'School name, city', onChanged: onChanged),
        const SizedBox(height: 14),
        _FieldLabel('Partner School (optional)'),
        _input(partnerSchoolCtrl, 'School name if this is a school partnership event'),
      ],
    );
  }

  Widget _input(TextEditingController ctrl, String hint, {int maxLines = 1, VoidCallback? onChanged}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2))),
        contentPadding: const EdgeInsets.all(13),
      ),
    );
  }
}

// ─── Step 2 ───────────────────────────────────────────────────────────────────

class _Step2VolunteerSetup extends StatelessWidget {
  const _Step2VolunteerSetup({
    required this.maxVolunteers,
    required this.certificateEligible,
    required this.donationEligible,
    required this.stipendEligible,
    required this.stipendAmount,
    required this.expectedWorkCtrl,
    required this.proofRequiredCtrl,
    required this.onMaxVolunteersChanged,
    required this.onCertChanged,
    required this.onDonationChanged,
    required this.onStipendChanged,
    required this.onStipendAmountChanged,
  });

  final int maxVolunteers;
  final bool certificateEligible;
  final bool donationEligible;
  final bool stipendEligible;
  final double stipendAmount;
  final TextEditingController expectedWorkCtrl;
  final TextEditingController proofRequiredCtrl;
  final ValueChanged<int> onMaxVolunteersChanged;
  final ValueChanged<bool> onCertChanged;
  final ValueChanged<bool> onDonationChanged;
  final ValueChanged<bool> onStipendChanged;
  final ValueChanged<double> onStipendAmountChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Maximum Volunteers *'),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: maxVolunteers > 1 ? () => onMaxVolunteersChanged(maxVolunteers - 1) : null,
                    icon: const Icon(Icons.remove_circle_rounded),
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$maxVolunteers volunteers',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onMaxVolunteersChanged(maxVolunteers + 1),
                    icon: const Icon(Icons.add_circle_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: certificateEligible,
                onChanged: onCertChanged,
                title: const Text('Certificate Eligible', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Volunteers receive a participation certificate', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                activeThumbColor: AppColors.primary,
              ),
              Divider(height: 1, color: AppColors.muted.withValues(alpha: 0.1)),
              SwitchListTile.adaptive(
                value: donationEligible,
                onChanged: onDonationChanged,
                title: const Text('Donation Collection', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Volunteers will collect donations', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                activeThumbColor: const Color(0xFF2E7D32),
              ),
              Divider(height: 1, color: AppColors.muted.withValues(alpha: 0.1)),
              SwitchListTile.adaptive(
                value: stipendEligible,
                onChanged: onStipendChanged,
                title: const Text('Stipend Eligible', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Volunteers receive a participation stipend', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                activeThumbColor: const Color(0xFF6A1B9A),
              ),
              if (stipendEligible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      const Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (v) => onStipendAmountChanged(double.tryParse(v) ?? 0),
                          decoration: InputDecoration(
                            hintText: 'Stipend amount per volunteer',
                            hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Expected Work from Volunteers'),
        const SizedBox(height: 6),
        TextField(
          controller: expectedWorkCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Photo documentation, attendance sheet, donation receipts…',
            hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(13),
          ),
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Proof Required'),
        const SizedBox(height: 6),
        TextField(
          controller: proofRequiredCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g. Photos + signed attendance sheet + donation receipt',
            hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(13),
          ),
        ),
      ],
    );
  }
}

// ─── Step 3 ───────────────────────────────────────────────────────────────────

class _ActivityDraft {
  String title;
  ActivityRole role;
  int maxStudents;
  bool requiresDonationProof;

  _ActivityDraft({required this.title, required this.role, required this.maxStudents, this.requiresDonationProof = false});
}

class _Step3Activities extends StatefulWidget {
  const _Step3Activities({required this.activities, required this.onAdd, required this.onRemove});
  final List<_ActivityDraft> activities;
  final void Function(_ActivityDraft) onAdd;
  final void Function(int) onRemove;

  @override
  State<_Step3Activities> createState() => _Step3ActivitiesState();
}

class _Step3ActivitiesState extends State<_Step3Activities> {
  void _showAddSheet() {
    final titleCtrl = TextEditingController();
    ActivityRole role = ActivityRole.volunteerSupport;
    int maxStudents = 3;
    bool requiresDonation = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Container(
              margin: const EdgeInsets.all(12),
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF17324D))),
                  const SizedBox(height: 14),
                  const _FieldLabel('Activity Title'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Stationery Packing Team',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Role'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ActivityRole>(
                    initialValue: role,
                    onChanged: (v) => setSheetState(() => role = v ?? role),
                    items: ActivityRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label, style: const TextStyle(fontSize: 13)))).toList(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const _FieldLabel('Max Students'),
                      const Spacer(),
                      IconButton(onPressed: maxStudents > 1 ? () => setSheetState(() => maxStudents--) : null, icon: const Icon(Icons.remove_rounded)),
                      Text('$maxStudents', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      IconButton(onPressed: () => setSheetState(() => maxStudents++), icon: const Icon(Icons.add_rounded)),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: requiresDonation,
                    onChanged: (v) => setSheetState(() => requiresDonation = v),
                    title: const Text('Requires Donation Proof', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    activeThumbColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isNotEmpty) {
                          widget.onAdd(_ActivityDraft(title: title, role: role, maxStudents: maxStudents, requiresDonationProof: requiresDonation));
                          Navigator.pop(ctx);
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (widget.activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Icon(Icons.playlist_add_rounded, size: 44, color: AppColors.muted.withValues(alpha: 0.3)),
                const SizedBox(height: 10),
                Text('No activities yet', style: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Add at least one activity for volunteers to sign up for.', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.7), fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...List.generate(widget.activities.length, (i) {
            final act = widget.activities[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(act.role.icon, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(act.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF17324D))),
                        Text('${act.role.label} · max ${act.maxStudents} students', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        if (act.requiresDonationProof)
                          Text('Requires donation proof', style: TextStyle(fontSize: 11, color: const Color(0xFF2E7D32))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onRemove(i),
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828), size: 18),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showAddSheet,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ─── Step 4 ───────────────────────────────────────────────────────────────────

class _Step4Settings extends StatelessWidget {
  const _Step4Settings({
    required this.reportRequired,
    required this.impactPostEligible,
    required this.title,
    required this.category,
    required this.location,
    required this.eventDate,
    required this.maxVolunteers,
    required this.activitiesCount,
    required this.onReportChanged,
    required this.onImpactChanged,
  });

  final bool reportRequired;
  final bool impactPostEligible;
  final String title;
  final EventCategory category;
  final String location;
  final DateTime eventDate;
  final int maxVolunteers;
  final int activitiesCount;
  final ValueChanged<bool> onReportChanged;
  final ValueChanged<bool> onImpactChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Preview card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A1F44), Color(0xFF1A3A6C)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(category.label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_rounded, color: Colors.white54, size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Text(title.isNotEmpty ? title : 'Event Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(location.isNotEmpty ? location : 'Location', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(_formatDate(eventDate), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_outline, color: Colors.white60, size: 13),
                  const SizedBox(width: 4),
                  Text('$maxVolunteers max volunteers', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.assignment_rounded, color: Colors.white60, size: 13),
                  const SizedBox(width: 4),
                  Text('$activitiesCount activities', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Settings
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: reportRequired,
                onChanged: onReportChanged,
                title: const Text('Require Event Report', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('EM must submit an event report after completion', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                activeThumbColor: const Color(0xFF1565C0),
              ),
              Divider(height: 1, color: AppColors.muted.withValues(alpha: 0.1)),
              SwitchListTile.adaptive(
                value: impactPostEligible,
                onChanged: onImpactChanged,
                title: const Text('Auto-generate Impact Post', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Auto-draft an impact post for Wall of Impact after completion', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                activeThumbColor: const Color(0xFF6A1B9A),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF2E7D32), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The event will be created in Draft status. You can publish it once you\'re ready for registrations.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
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

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.value, required this.onChanged});
  final EventCategory value;
  final ValueChanged<EventCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: EventCategory.values.map((cat) {
          final isSelected = cat == value;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.muted.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon, size: 13, color: isSelected ? Colors.white : AppColors.muted),
                  const SizedBox(width: 5),
                  Text(cat.label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.muted, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              _formatDate(date),
              style: const TextStyle(fontSize: 14, color: Color(0xFF17324D), fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600),
    );
  }
}
