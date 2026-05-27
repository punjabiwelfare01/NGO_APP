import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../core/colors.dart';
import '../../../models/auth_models.dart';
import '../../../models/event_models.dart';
import '../../../repositories/event_repository.dart';
import '../../../viewmodels/view_state.dart';
import '../../quiz/quiz_play_screen.dart';
import 'event_registration_form_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({required this.eventId, super.key});

  final int eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  ViewState _state = ViewState.loading;
  EventModel? _event;
  List<EventSlotModel> _slots = [];
  String? _error;
  bool _isRegistered = false;
  bool _isCompleted = false;
  String? _registrationStatus;
  int? _bookedSlotId;

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
      final event = await EventRepository.getEvent(widget.eventId);
      final slots = await EventRepository.getSlots(widget.eventId);

      bool registered = false;
      bool completed = false;
      String? registrationStatus;
      int? bookedSlotId;

      final role = AppState.role;
      final bool isStudent =
          !role.isAdmin &&
          role != UserRole.mentor &&
          role != UserRole.superAdmin;
      if (isStudent) {
        final regMap = await EventRepository.getMyRegistration(widget.eventId);
        if (regMap != null) {
          registered = true;
          completed = regMap['status'] == 'completed';
          registrationStatus = regMap['status'] as String?;
          bookedSlotId = regMap['slot_id'] as int?;
        }
      }

      if (mounted) {
        setState(() {
          _event = event;
          _slots = slots;
          _isRegistered = registered;
          _isCompleted = completed;
          _registrationStatus = registrationStatus;
          _bookedSlotId = bookedSlotId;
          _state = ViewState.idle;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = ViewState.error;
          _error = 'Failed to load event.';
        });
      }
    }
  }

  Future<void> _joinEvent() async {
    try {
      await EventRepository.registerForEvent(widget.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined event successfully.')),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not join this event.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Future<void> _openRegistrationForm(EventModel event) async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventRegistrationFormScreen(event: event),
      ),
    );
    if (registered == true) {
      await _load();
    }
  }

  Future<void> _bookSlot({int? slotId}) async {
    try {
      await EventRepository.bookSlot(widget.eventId, slotId: slotId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot booked successfully.')),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not book a slot for this event.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Future<void> _createSlot(EventModel event) async {
    final slot = await showDialog<_SlotDraft>(
      context: context,
      builder: (_) => _CreateSlotDialog(defaultStart: event.eventStart),
    );
    if (slot == null) return;
    try {
      await EventRepository.createSlot(
        event.id,
        title: slot.title,
        startsAt: slot.startsAt,
        endsAt: slot.endsAt,
        capacity: slot.capacity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Slot created.')));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create slot.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  Future<void> _attachQuizTask(EventModel event) async {
    final quizId = await showDialog<int>(
      context: context,
      builder: (_) => const _AttachQuizDialog(),
    );
    if (quizId == null) return;
    try {
      await EventRepository.attachQuiz(event.id, event.title, quizId: quizId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz task linked to this event.')),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not link quiz. Check the quiz ID.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _state == ViewState.loading
          ? const Center(child: CircularProgressIndicator())
          : _state == ViewState.error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error ?? 'Error',
                    style: const TextStyle(color: AppColors.softRed),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _buildContent(context, _event!),
    );
  }

  Widget _buildContent(BuildContext context, EventModel event) {
    return CustomScrollView(
      slivers: [
        // Banner app bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    event.themeColorValue,
                    event.themeColorValue.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            title: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtitle + badges
                if (event.subtitle != null)
                  Text(
                    event.subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Chip(event.eventType.displayName, event.themeColorValue),
                    const SizedBox(width: 8),
                    _StatusBadge(event.status),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                if (event.description != null) ...[
                  _SectionTitle('About'),
                  const SizedBox(height: 6),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Timeline
                _SectionTitle('Timeline'),
                const SizedBox(height: 10),
                _TimelineRow('Registration Opens', event.registrationStart),
                _TimelineRow('Registration Closes', event.registrationEnd),
                _TimelineRow('Event Starts', event.eventStart),
                _TimelineRow('Event Ends', event.eventEnd),
                _TimelineRow('Results', event.resultDate),
                const SizedBox(height: 20),

                // Rules
                _SectionTitle('Participation Rules'),
                const SizedBox(height: 10),
                if (event.ageMin != null || event.ageMax != null)
                  _InfoRow(
                    Icons.cake_outlined,
                    'Age',
                    '${event.ageMin ?? '—'} – ${event.ageMax ?? '—'} years',
                  ),
                if (event.minQuizScore != null)
                  _InfoRow(
                    Icons.quiz_outlined,
                    'Min Quiz Score',
                    '${event.minQuizScore}',
                  ),
                if (event.requiredChallenges > 0)
                  _InfoRow(
                    Icons.task_alt_outlined,
                    'Required Challenges',
                    '${event.requiredChallenges}',
                  ),
                if (event.maxParticipants != null)
                  _InfoRow(
                    Icons.group_outlined,
                    'Max Participants',
                    '${event.maxParticipants}',
                  ),
                const SizedBox(height: 20),

                // Rewards
                _SectionTitle('Rewards & Benefits'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (event.counsellingEnabled)
                      _RewardChip(
                        Icons.support_agent_rounded,
                        'Counselling',
                        AppColors.primary,
                      ),
                    if (event.certificateEnabled)
                      _RewardChip(
                        Icons.workspace_premium_rounded,
                        'Certificate',
                        AppColors.accent,
                      ),
                    if (event.scholarshipEnabled)
                      _RewardChip(
                        Icons.school_rounded,
                        'Scholarship',
                        AppColors.secondary,
                      ),
                    if (event.mentorshipEnabled)
                      _RewardChip(
                        Icons.people_alt_rounded,
                        'Mentorship',
                        const Color(0xFF9C6FDE),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                ..._buildTypeSection(event),

                const SizedBox(height: 20),

                // Action button depending on event type and registration status
                _buildActionButton(context, event),
                const SizedBox(height: 14),
                _TaskPanel(
                  event: event,
                  isRegistered: _isRegistered,
                  isCompleted: _isCompleted,
                  bookedSlotId: _bookedSlotId,
                  slots: _slots,
                  isAdminOrMentor:
                      AppState.role.isAdmin ||
                      AppState.role == UserRole.mentor ||
                      AppState.role == UserRole.superAdmin,
                  onAttachQuiz: () => _attachQuizTask(event),
                  onCreateSlot: () => _createSlot(event),
                  onJoin: _joinEvent,
                  onRegister: () => _openRegistrationForm(event),
                  onBookSlot: (slotId) => _bookSlot(slotId: slotId),
                  onStartQuiz: event.quizId == null
                      ? null
                      : () async {
                          await Navigator.of(
                            context,
                          ).pushNamed('/quiz/${event.quizId}');
                          _load();
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, EventModel event) {
    final bool isQuizOrChallenge =
        event.eventType == EventType.quiz ||
        event.eventType == EventType.dailyChallenge;
    final bool isCounsellingDrive =
        event.eventType == EventType.counsellingDrive;
    final bool hasBookedSlot =
        _bookedSlotId != null || _registrationStatus == 'slot_booked';

    final bool isAdminOrMentor =
        AppState.role.isAdmin ||
        AppState.role == UserRole.mentor ||
        AppState.role == UserRole.superAdmin;
    if (isAdminOrMentor) {
      if (event.quizId != null) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizPlayScreen(quizId: event.quizId!),
              ),
            ),
            icon: const Icon(Icons.quiz_rounded),
            label: const Text('Preview Linked Quiz (Admin/Mentor)'),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (event.eventType == EventType.dailyChallenge && event.quizId != null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isCompleted
              ? null
              : () async {
                  await Navigator.of(
                    context,
                  ).pushNamed('/quiz/${event.quizId}');
                  _load();
                },
          icon: Icon(
            _isCompleted
                ? Icons.check_circle_rounded
                : Icons.play_arrow_rounded,
          ),
          label: Text(_isCompleted ? 'Challenge Completed' : 'Start Challenge'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (isQuizOrChallenge) {
      if (_isCompleted) {
        return const SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 8),
                Text('Quiz Completed'),
              ],
            ),
          ),
        );
      }
      if (_isRegistered) {
        if (event.quizId != null) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizPlayScreen(quizId: event.quizId!),
                  ),
                );
                _load();
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Quiz'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          );
        } else {
          return const SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              child: Text('No Quiz Linked to this Event'),
            ),
          );
        }
      }
    }

    if (isCounsellingDrive && _isRegistered && !hasBookedSlot) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.event_seat_rounded),
          label: const Text('Registered - choose a slot below'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (_isRegistered) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.done_rounded),
          label: Text(hasBookedSlot ? 'Slot Booked' : 'Registered'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.muted,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (event.canRegister ||
        (isCounsellingDrive && event.status == EventStatus.live)) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isCounsellingDrive
              ? () => _openRegistrationForm(event)
              : _isSlotEvent(event) && _slots.isNotEmpty
              ? () => _bookSlot()
              : _joinEvent,
          icon: const Icon(Icons.how_to_reg_rounded),
          label: Text(_primaryActionLabel(event)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _primaryActionLabel(EventModel event) {
    return switch (event.eventType) {
      EventType.counsellingDrive => 'Register for Counselling',
      EventType.workshop => 'Book Slot',
      EventType.quiz || EventType.dailyChallenge => 'Join Event',
      EventType.competition => 'Join Competition',
      _ => 'Join Event',
    };
  }

  bool _isSlotEvent(EventModel event) {
    return event.eventType == EventType.workshop ||
        event.eventType == EventType.counsellingDrive;
  }

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  List<Widget> _buildTypeSection(EventModel event) {
    switch (event.eventType) {
      case EventType.competition:
        return [
          const _SectionTitle('Competition Info'),
          const SizedBox(height: 10),
          _TypeInfoCard(
            icon: Icons.emoji_events_rounded,
            color: AppColors.accent,
            children: [
              _TypeRow('Selection', event.selectionMethod.displayName),
              if (event.maxParticipants != null)
                _TypeRow('Spots', '${event.maxParticipants} total'),
              if (event.participantCount > 0)
                _TypeRow('Joined', '${event.participantCount} participants'),
              _TypeRow(
                'Scoring',
                event.quizId != null ? 'Quiz score based' : 'Admin evaluated',
              ),
            ],
          ),
          if (event.selectionMethod == SelectionMethod.scoreBased) ...[
            const SizedBox(height: 10),
            _HighlightBanner(
              icon: Icons.leaderboard_rounded,
              text: 'Top scorers advance — submit your best attempt.',
              color: AppColors.accent,
            ),
          ],
        ];

      case EventType.scholarship:
        final hasEligibility =
            event.ageMin != null ||
            event.ageMax != null ||
            event.minQuizScore != null ||
            event.requiredChallenges > 0;
        return [
          const _SectionTitle('Eligibility Criteria'),
          const SizedBox(height: 10),
          _TypeInfoCard(
            icon: Icons.checklist_rounded,
            color: AppColors.secondary,
            children: [
              if (event.ageMin != null || event.ageMax != null)
                _TypeRow(
                  'Age Range',
                  '${event.ageMin ?? 'Any'} – ${event.ageMax ?? 'Any'} yrs',
                ),
              if (event.minQuizScore != null)
                _TypeRow('Min Quiz Score', '${event.minQuizScore}%'),
              if (event.requiredChallenges > 0)
                _TypeRow(
                  'Challenges Needed',
                  '${event.requiredChallenges} completed',
                ),
              if (!hasEligibility)
                const _TypeRow('Eligibility', 'Open to all registered users'),
            ],
          ),
          if (event.resultDate != null) ...[
            const SizedBox(height: 10),
            _HighlightBanner(
              icon: Icons.hourglass_bottom_rounded,
              text: 'Results announced on ${_fmtDate(event.resultDate!)}',
              color: AppColors.secondary,
            ),
          ],
        ];

      case EventType.workshop:
        return [
          const _SectionTitle('Workshop Details'),
          const SizedBox(height: 10),
          const _TypeInfoCard(
            icon: Icons.co_present_rounded,
            color: AppColors.primary,
            children: [
              _TypeRow('Format', 'Live session with Q&A'),
              _TypeRow('Booking', 'Choose a slot to secure your seat'),
              _TypeRow('What to bring', 'Notepad, questions, curiosity'),
            ],
          ),
        ];

      case EventType.counsellingDrive:
        return [
          const _SectionTitle('Counselling Event Details'),
          const SizedBox(height: 10),
          if (event.counsellingDate != null) ...[
            _HighlightBanner(
              icon: Icons.calendar_month_rounded,
              text: 'Counselling day: ${_fmtDate(event.counsellingDate!)}',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
          ],
          const _TypeInfoCard(
            icon: Icons.support_agent_rounded,
            color: AppColors.primary,
            children: [
              _TypeRow('Mentor', 'Event Counsellor'),
              _TypeRow('Format', 'One-on-one 30-minute session'),
              _TypeRow('Support Area', 'Career guidance & academic support'),
              _TypeRow('Privacy', 'Private session with trusted mentor'),
              _TypeRow('Next Step', 'Register, then pick a slot below'),
            ],
          ),
        ];

      case EventType.awarenessCampaign:
      case EventType.cyberSecurity:
        return [
          const _SectionTitle('Campaign Details'),
          const SizedBox(height: 10),
          _TypeInfoCard(
            icon: event.eventType == EventType.cyberSecurity
                ? Icons.security_rounded
                : Icons.campaign_rounded,
            color: AppColors.primary,
            children: const [
              _TypeRow('How to join', 'Register and complete the quiz'),
              _TypeRow('Impact', 'Contribute to community outreach goals'),
              _TypeRow('Certificate', 'Issued on completion'),
            ],
          ),
        ];

      case EventType.talentHunt:
        return [
          const _SectionTitle('Talent Hunt'),
          const SizedBox(height: 10),
          const _TypeInfoCard(
            icon: Icons.star_rounded,
            color: Color(0xFF9C6FDE),
            children: [
              _TypeRow('Round 1', 'Online screening quiz'),
              _TypeRow('Round 2', 'Live performance / project submission'),
              _TypeRow('Evaluation', 'Panel judging + audience vote'),
              _TypeRow('Winner', 'Announced on results date'),
            ],
          ),
        ];

      default:
        return const [];
    }
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({
    required this.event,
    required this.isRegistered,
    required this.isCompleted,
    required this.bookedSlotId,
    required this.slots,
    required this.isAdminOrMentor,
    required this.onAttachQuiz,
    required this.onCreateSlot,
    required this.onJoin,
    required this.onRegister,
    required this.onBookSlot,
    required this.onStartQuiz,
  });

  final EventModel event;
  final bool isRegistered;
  final bool isCompleted;
  final int? bookedSlotId;
  final List<EventSlotModel> slots;
  final bool isAdminOrMentor;
  final VoidCallback onAttachQuiz;
  final VoidCallback onCreateSlot;
  final VoidCallback onJoin;
  final VoidCallback onRegister;
  final ValueChanged<int?> onBookSlot;
  final VoidCallback? onStartQuiz;

  bool get _usesQuiz =>
      event.eventType == EventType.quiz ||
      event.eventType == EventType.dailyChallenge ||
      event.eventType == EventType.competition;

  bool get _usesSlot =>
      event.eventType == EventType.workshop ||
      event.eventType == EventType.counsellingDrive;

  bool get _hasBookedSlot => bookedSlotId != null;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (isAdminOrMentor) {
      items.add(
        _TaskTile(
          icon: _usesQuiz ? Icons.quiz_rounded : Icons.event_available_rounded,
          title: _usesQuiz ? 'Quiz Task' : 'Event Task',
          subtitle: _usesQuiz
              ? event.quizId == null
                    ? 'Attach an existing quiz ID after creating the event.'
                    : 'Quiz #${event.quizId} is linked and ready to preview.'
              : 'Students can join this event from the detail page.',
          actionLabel: _usesQuiz && event.quizId == null
              ? 'Attach Quiz'
              : _usesQuiz
              ? 'Preview'
              : null,
          onTap: _usesQuiz && event.quizId == null ? onAttachQuiz : onStartQuiz,
        ),
      );
      if (_usesSlot) {
        items.add(const SizedBox(height: 10));
        items.add(
          _TaskTile(
            icon: Icons.event_seat_rounded,
            title: 'Slots',
            subtitle: slots.isEmpty
                ? 'Create bookable time slots for this ${event.eventType.displayName.toLowerCase()}.'
                : '${slots.length} slot${slots.length == 1 ? '' : 's'} configured.',
            actionLabel: 'Add Slot',
            onTap: onCreateSlot,
          ),
        );
      }
    } else {
      if (_usesQuiz) {
        items.add(
          _TaskTile(
            icon: Icons.play_circle_fill_rounded,
            title: event.eventType == EventType.dailyChallenge
                ? 'Daily Challenge'
                : 'Quiz Task',
            subtitle: event.quizId == null
                ? 'This event does not have a quiz linked yet.'
                : isRegistered || event.eventType == EventType.dailyChallenge
                ? 'Start the linked quiz when you are ready.'
                : 'Join the event first, then start the quiz.',
            actionLabel: event.quizId == null
                ? null
                : isCompleted
                ? 'Completed'
                : isRegistered || event.eventType == EventType.dailyChallenge
                ? 'Start'
                : 'Join',
            onTap: event.quizId == null
                ? null
                : isCompleted
                ? null
                : isRegistered || event.eventType == EventType.dailyChallenge
                ? onStartQuiz
                : onJoin,
          ),
        );
      } else if (_usesSlot) {
        if (slots.isEmpty) {
          items.add(
            _TaskTile(
              icon: Icons.event_seat_rounded,
              title: event.eventType == EventType.counsellingDrive
                  ? 'Counselling Slot'
                  : 'Book Slot',
              subtitle: isRegistered
                  ? 'You are registered. Slot schedule will be shared soon.'
                  : 'Register first so the mentor can review your details.',
              actionLabel: isRegistered ? 'Registered' : 'Register',
              onTap: isRegistered ? null : onRegister,
            ),
          );
        } else {
          if (!isRegistered && event.eventType == EventType.counsellingDrive) {
            items.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskTile(
                  icon: Icons.assignment_ind_rounded,
                  title: 'Register First',
                  subtitle:
                      'Review the mentor details and timeline, then submit the registration form before choosing a slot.',
                  actionLabel: 'Register',
                  onTap: onRegister,
                ),
              ),
            );
          }
          for (final slot in slots) {
            final isThisSlotBooked = bookedSlotId == slot.id;
            items.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SlotTile(
                  slot: slot,
                  booked: isThisSlotBooked,
                  onBook: !isRegistered || _hasBookedSlot || slot.isFull
                      ? null
                      : () => onBookSlot(slot.id),
                ),
              ),
            );
          }
        }
      } else {
        items.add(
          _TaskTile(
            icon: Icons.group_add_rounded,
            title: 'Join Event',
            subtitle: isRegistered
                ? 'You have joined this event.'
                : 'Join to participate and receive updates.',
            actionLabel: isRegistered ? 'Joined' : 'Join',
            onTap: isRegistered ? null : onJoin,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Event Task'),
        const SizedBox(height: 10),
        ...items,
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: onTap == null
                    ? AppColors.muted
                    : AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.booked,
    required this.onBook,
  });

  final EventSlotModel slot;
  final bool booked;
  final VoidCallback? onBook;

  String _fmt(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_seat_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_fmt(slot.startsAt)} • ${slot.availableCount}/${slot.capacity} seats left',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onBook,
            style: FilledButton.styleFrom(
              backgroundColor: onBook == null
                  ? AppColors.muted
                  : AppColors.primary,
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              booked
                  ? 'Booked'
                  : slot.isFull
                  ? 'Full'
                  : 'Book',
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotDraft {
  const _SlotDraft({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
  });

  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int capacity;
}

class _CreateSlotDialog extends StatefulWidget {
  const _CreateSlotDialog({required this.defaultStart});

  final DateTime? defaultStart;

  @override
  State<_CreateSlotDialog> createState() => _CreateSlotDialogState();
}

class _CreateSlotDialogState extends State<_CreateSlotDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _capacityCtrl;
  late DateTime _startsAt;

  @override
  void initState() {
    super.initState();
    _startsAt =
        widget.defaultStart ?? DateTime.now().add(const Duration(days: 1));
    _titleCtrl = TextEditingController(text: 'Session 1');
    _capacityCtrl = TextEditingController(text: '20');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Slot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Slot title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacityCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Capacity',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickStart,
            icon: const Icon(Icons.schedule_rounded),
            label: Text(
              '${_startsAt.day}/${_startsAt.month}/${_startsAt.year} '
              '${_startsAt.hour.toString().padLeft(2, '0')}:'
              '${_startsAt.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 1;
            final title = _titleCtrl.text.trim();
            if (title.isEmpty || capacity <= 0) return;
            Navigator.of(context).pop(
              _SlotDraft(
                title: title,
                startsAt: _startsAt,
                endsAt: null,
                capacity: capacity,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
}

class _AttachQuizDialog extends StatefulWidget {
  const _AttachQuizDialog();

  @override
  State<_AttachQuizDialog> createState() => _AttachQuizDialogState();
}

class _AttachQuizDialogState extends State<_AttachQuizDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attach Quiz'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Quiz ID',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final quizId = int.tryParse(_controller.text.trim());
            if (quizId != null) Navigator.of(context).pop(quizId);
          },
          child: const Text('Attach'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(this.label, this.date);
  final String label;
  final DateTime? date;

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              _fmt(date),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final EventStatus status;

  Color get _color => switch (status) {
    EventStatus.draft => AppColors.muted,
    EventStatus.published => AppColors.primary,
    EventStatus.registrationOpen => AppColors.secondary,
    EventStatus.live => AppColors.accent,
    EventStatus.completed => AppColors.muted,
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeInfoCard extends StatelessWidget {
  const _TypeInfoCard({
    required this.icon,
    required this.color,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  const _HighlightBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
