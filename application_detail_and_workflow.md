# CareSkill (Punjabi Welfare Trust) — Complete API, Frontend & Backend Reference

> Last updated: 26 June 2026. Covers every backend endpoint, every frontend repository method, all role-specific API access, and the complete frontend ↔ backend linking chain.

---

## Contents

1. [Architecture overview](#1-architecture-overview)
2. [Frontend ↔ backend linking model](#2-frontend--backend-linking-model)
3. [Authentication — all roles](#3-authentication--all-roles)
4. [Role: Student / Volunteer](#4-role-student--volunteer)
5. [Role: Admin / Super-Admin](#5-role-admin--super-admin)
6. [Role: Event Manager](#6-role-event-manager)
7. [Role: Counsellor / Mentor](#7-role-counsellor--mentor)
8. [Role: Content Creator](#8-role-content-creator)
9. [Shared modules (all roles)](#9-shared-modules-all-roles)
10. [Complete backend API endpoint index](#10-complete-backend-api-endpoint-index)
11. [Frontend repository → endpoint mapping](#11-frontend-repository--endpoint-mapping)
12. [Data flow diagrams](#12-data-flow-diagrams)
13. [Start the application](#13-start-the-application)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Architecture overview

### Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) — Android, Web, Linux desktop |
| Backend | FastAPI (Python 3.11) + SQLAlchemy ORM |
| Database | SQLite `careskill.db` (single file for dev) |
| Auth | JWT HS256 · 60-minute expiry · bcrypt passwords |
| Social login | Google OAuth2 ID token, Auth0 ID token |
| File storage | Local `uploads/` + `videos/` served by FastAPI |
| Video delivery | Authenticated range-request streaming `/video/stream/{filename}` |
| Real-time chat | WebSocket `/ws/chat/{other_user_id}` |
| Calendar | Google OAuth2 for Meet link generation |

### Roles

| Role value | Dashboard | Key access areas |
|---|---|---|
| `student` | Home / Learn / Work / Impact / Profile | Volunteer activities, courses, counselling |
| `admin` | Home / Users / Manage / Impact / Settings | All user management and content approval |
| `super_admin` | Same as admin + all data | Full platform access |
| `event_manager` | Home / Events / Students / Impact / Profile | Event pipeline, volunteer assignments, impact posts |
| `counsellor` | Home / Requests / Schedule / Sessions / Profile | Session management, school requests |
| `content_creator` | Home / Analytics / Upload / Content / Profile | Course and lesson creation, quiz creation |
| `school_partner` | Home / Learn / Calendar / Support / Profile | Partial — informational portal |
| `support_staff` | Home / Learn / Calendar / Support / Profile | Read-access portal |

### Account lifecycle

```
Register → pending → Admin approves + assigns role → approved (dashboard opens)
                  → Admin rejects → rejected
                  → Admin blocks → blocked
```

---

## 2. Frontend ↔ backend linking model

### API client chain

```
Screen / Widget
    └── ViewModel  (ChangeNotifier — lib/viewmodels/)
            └── Repository  (static class — lib/repositories/)
                    └── ApiClient  (lib/repositories/api_client.dart)
                            └── HTTP + Bearer token → FastAPI backend
```

### ApiClient internals (`lib/repositories/api_client.dart`)

- Reads `AppState.token` and adds `Authorization: Bearer <token>` header on every request.
- Base URL resolved from `lib/core/config.dart` → environment variable `API_BASE_URL` or `BACKEND_ENV`.
- Methods: `get(path)`, `post(path, body)`, `patch(path, body)`, `delete(path)`, `postMultipart(path, fields, file)`.
- On 401 response: clears `AppState` and navigates to sign-in.
- Returns decoded JSON (`Map` or `List`); throws `Exception` on non-2xx.

### AppState (`lib/app_state.dart`)

Global in-memory + `flutter_secure_storage` singleton.

| Field | Type | Populated by |
|---|---|---|
| `token` | `String?` | Login / register / social login response |
| `userId` | `int?` | `GET /auth/me` on startup or login |
| `role` | `AppRole` | JWT payload `role` field |
| `studentName` | `String?` | JWT payload `name` field |
| `accessStatus` | `String?` | JWT payload `access_status` |

### Role routing (`lib/main.dart`)

On app start: reads saved token → calls `GET /auth/me` → reads `role` → mounts correct shell widget:

| Role | Shell widget |
|---|---|
| student | `StudentShell` |
| admin / super_admin | `AdminShell` |
| event_manager | `EventManagerShell` |
| counsellor | `CounsellorShell` |
| content_creator | `ContentCreatorShell` |
| pending / unknown | `PendingApprovalScreen` |

### Backend security enforcement

Every backend route that is role-restricted uses FastAPI `Depends`:

```python
Depends(require_role(UserRole.admin))      # admin / super_admin only
Depends(require_role(UserRole.event_manager))
Depends(_student)                          # student role only
Depends(get_current_user)                  # any authenticated user
```

The frontend role checks are UI-only. The backend enforces independently.

---

## 3. Authentication — all roles

### Backend router: `/auth` (`backend/app/routers/auth.py`)

| Method | Endpoint | Who calls it | Purpose |
|---|---|---|---|
| POST | `/auth/register` | `AuthRepository.register()` | Student registration (name, email, password, class, school) |
| POST | `/auth/login` | `AuthRepository.login()` | Email + password → JWT |
| POST | `/auth/logout` | `AuthRepository.logout()` | Blacklists JWT `jti`; clears session |
| GET | `/auth/me` | `AuthRepository.getMe()` | Returns current user profile from token |
| POST | `/auth/change-password` | `AuthRepository.changePassword()` | Requires current + new password |
| POST | `/auth/forgot-password` | `AuthRepository.forgotPassword()` | Generates 6-digit OTP for email |
| POST | `/auth/verify-reset-code` | `AuthRepository.verifyResetCode()` | Validates OTP; returns reset token |
| POST | `/auth/reset-password` | `AuthRepository.resetPassword()` | Sets new password with reset token |
| POST | `/auth/google` | `AuthRepository.loginWithGoogle()` | Google ID token → JWT |
| POST | `/auth/auth0` | `AuthRepository.loginWithAuth0()` | Auth0 ID token → JWT |
| GET | `/auth/google/calendar/status` | `CounsellingRepository` | Check if counsellor has Calendar OAuth |
| GET | `/auth/google/calendar/authorize` | Browser redirect | Starts Google Calendar OAuth flow |
| GET | `/auth/google/callback` | Google redirect | OAuth callback; saves refresh token |

### Frontend files

| File | Purpose |
|---|---|
| `lib/repositories/auth_repository.dart` | All auth API calls |
| `lib/screens/auth/auth_page.dart` | Login / register tab container |
| `lib/screens/auth/login_view.dart` | Sign-in form, Google/Auth0 buttons |
| `lib/screens/auth/student_register_screen.dart` | Registration form |
| `lib/screens/auth/pending_approval_screen.dart` | Shown when `access_status = pending` |

### JWT payload fields

```json
{
  "sub": "42",
  "role": "student",
  "name": "Simran Kaur",
  "access_status": "approved",
  "jti": "<uuid4>",
  "exp": 1234567890
}
```

---

## 4. Role: Student / Volunteer

The student sees 5 tabs: **Home**, **Learn**, **Work**, **Impact**, **Profile**.

### 4.1 Home — volunteer sections

Screen: `lib/screens/home/home_view.dart`  
ViewModel: `VolunteerViewModel` (`lib/viewmodels/volunteer_viewmodel.dart`)

The home screen initialises `VolunteerViewModel` and `EventPipelineViewModel` only for students (`AppState.role.isStudent`). Each section:

| Section | Flutter widget | API called | Backend endpoint |
|---|---|---|---|
| Your Impact (4 stat cards) | `_NGOImpactSummaryRow` | `VolunteerRepository.getMyStats()` | `GET /volunteer/stats/me` |
| My Assignments | `_NGOAssignmentsSection` | `VolunteerRepository.getMyAssignments()` | `GET /student/assignments` |
| Open Activities | `_NGOOpenActivitiesCard` | `VolunteerRepository.getActivities()` | `GET /student/activities` |
| Active Event | `_ActivePipelineEventCard` | `EventPipelineViewModel.load()` | `GET /events?status=published` |
| Counselling session | `CounsellingSessionCard` | `HomeViewModel` | `GET /users/{id}/wellness/counselling` |
| Daily challenge | `DailyChallengeCard` | `HomeViewModel` | `GET /quizzes/daily` |
| Emergency help | `_EmergencyHelpCard` | `HomeViewModel` | `GET /emergency-contacts` |

**Activity visibility rule**: `GET /student/activities` returns activities where `is_active = true` **OR** the activity's linked event has status `published` / `registration_open` / `live`. This ensures activities from already-published events are always visible.

### 4.2 Student volunteer APIs (`/student` prefix)

Backend: `backend/app/routers/student.py`  
Frontend: `lib/repositories/volunteer_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/student/activities` | `VolunteerRepository.getActivities()` | List open activities (active + published-event linked) |
| GET | `/student/activities/{id}` | `VolunteerRepository.getActivity(id)` | Single activity detail |
| POST | `/student/activities/{id}/apply` | `VolunteerRepository.applyForActivity(id)` | Apply for an activity |
| GET | `/student/assignments` | `VolunteerRepository.getMyAssignments()` | Student's assigned activities |
| GET | `/student/assignments/{id}` | (direct call) | Single assignment detail |
| POST | `/student/assignments/{id}/submit-work` | `VolunteerRepository.submitWork(assignmentId:)` | Submit work proof for assignment |
| GET | `/student/work-summary` | (via stats) | Student work totals |
| POST | `/student/upload-proof` | `VolunteerRepository.uploadProof()` | Multipart proof file upload → returns URL |

### 4.3 Volunteer module APIs (`/volunteer` prefix)

Backend: `backend/app/routers/volunteer.py`  
Frontend: `lib/repositories/volunteer_repository.dart`

| Method | Endpoint | Flutter call | Access | Purpose |
|---|---|---|---|---|
| GET | `/volunteer/activities` | (admin use) | admin/EM | All activities (no is_active filter for admin) |
| GET | `/volunteer/activities/{id}` | (admin use) | any auth | Activity by ID |
| POST | `/volunteer/activities` | (admin/EM creates) | admin/EM | Create volunteer activity |
| PATCH | `/volunteer/activities/{id}` | (admin/EM edits) | admin/EM | Update activity |
| POST | `/volunteer/assignments` | (admin assigns) | admin/EM | Assign student to activity |
| GET | `/volunteer/assignments/me` | `VolunteerRepository.getMyAssignments()` | student | My assignments |
| GET | `/volunteer/assignments` | (admin) | admin/EM | All assignments |
| POST | `/volunteer/submissions` | `VolunteerRepository.submitWork()` | student | Submit work (no assignment) |
| GET | `/volunteer/submissions/me` | `VolunteerRepository.getMySubmissions()` | student | My submissions |
| GET | `/volunteer/submissions/pending` | `VolunteerRepository.getPendingSubmissions()` | admin/EM | Pending review queue |
| PATCH | `/volunteer/submissions/{id}/review` | `VolunteerRepository.reviewSubmission()` | admin | Approve or reject submission |
| POST | `/volunteer/logs` | `VolunteerRepository.createLog()` | student | Create daily logbook entry |
| GET | `/volunteer/logs/me` | `VolunteerRepository.getMyLogs()` | student | My logbook entries |
| GET | `/volunteer/logs/public` | `VolunteerRepository.getPublicLogs()` | any | Public logbook entries |
| PATCH | `/volunteer/logs/{id}` | `VolunteerRepository.updateLog()` | student | Edit log entry |
| PATCH | `/volunteer/logs/{id}/approve` | (admin) | admin | Approve log for public display |
| GET | `/volunteer/impact` | `VolunteerRepository.getImpactStories()` | any | Wall of Impact stories |
| POST | `/volunteer/impact` | (admin/EM) | admin/EM | Create impact story |
| PATCH | `/volunteer/impact/{id}/publish` | (admin) | admin | Publish impact story |
| GET | `/volunteer/stats/me` | `VolunteerRepository.getMyStats()` | student | Hours, activities, rank stats |
| GET | `/volunteer/stats/{student_id}` | (admin) | admin | Stats for specific student |

### 4.4 Learn — courses

Screen: `lib/screens/home/home_view.dart` (Learn tab) + course workspace  
Repository: `lib/repositories/course_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/categories` | `CourseRepository.getCategories()` | Skill categories for filter chips |
| GET | `/learn/skills` | `CourseRepository.getSkillCourses()` | Skill-category courses |
| GET | `/learn/academic` | `CourseRepository.getAcademicCourses()` | Academic courses |
| GET | `/learn/recommended` | `CourseRepository.getRecommended()` | Recommended courses |
| GET | `/courses` | `CourseRepository.getCourses()` | All published courses |
| GET | `/courses/{id}` | `CourseRepository.getCourse(id)` | Course summary |
| GET | `/courses/{id}/detail` | `CourseRepository.getCourseDetail(id)` | Full course + subjects + chapters + lessons |
| GET | `/courses/{id}/lessons` | `CourseRepository.getLessons(courseId)` | Lessons for a course |
| POST | `/courses/{id}/lessons/{lId}/complete` | `CourseRepository.completeLesson(cId, lId)` | Mark lesson complete |
| PATCH | `/lessons/{lId}/complete` | `CourseRepository.markComplete(lId)` | Shortcut complete |
| GET | `/users/{uid}/courses` | `CourseRepository.getUserProgress(uid)` | Course progress for user |
| GET | `/courses/{id}/lessons/{lId}/resources` | `CourseRepository.getResources(cId, lId)` | Lesson resources (PDF, links) |

### 4.5 Counselling (student)

Repository: `lib/repositories/counselling_repository.dart`  
Repository: `lib/repositories/wellness_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/counselling/mentors` | `CounsellingRepository.getMentors()` | Browse mentor directory |
| GET | `/counselling/mentors/{id}` | `CounsellingRepository.getMentor(id)` | Mentor profile detail |
| GET | `/counselling/slots/mentor/{uid}` | `CounsellingRepository.getMentorSlots(uid)` | Available booking slots |
| POST | `/users/{uid}/wellness/counselling/availability/{slotId}/book` | `WellnessRepository.bookSlot(slotId)` | Book a slot |
| GET | `/users/{uid}/wellness/counselling` | `WellnessRepository.getSessions()` | My booked sessions |
| WS | `/ws/chat/{other_user_id}` | Direct WebSocket | Real-time chat |
| GET | `/chat/{other_user_id}/history` | `CounsellingRepository.getChatHistory()` | Past chat messages |

### 4.6 Certificates

Repository: `lib/repositories/certificate_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/student/certificates/me` | `CertificateRepository.getMyCertificates()` | My certificates |
| GET | `/student/certificates/{id}` | `CertificateRepository.getCertificate(id)` | Certificate detail |
| GET | `/student/certificates/{id}/download` | `CertificateRepository.downloadUrl(id)` | Signed PDF download URL |
| GET | `/public/certificates/verify/{token}` | Public URL | QR-code certificate verification |

### 4.7 Donations

Repository: `lib/repositories/donation_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/donations/ngo-payment` | `DonationRepository.getNGOPaymentDetails()` | NGO UPI/bank details |
| POST | `/donations` | `DonationRepository.submitDonation()` | Record a donation |
| GET | `/donations/me` | `DonationRepository.getMyDonations()` | My donation history |
| GET | `/donations/stipends/me` | `DonationRepository.getMyStipends()` | My stipend records |

### 4.8 Quizzes and daily challenge

Repository: `lib/repositories/quiz_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/quizzes/daily` | `QuizRepository.getDailyChallenge()` | Today's challenge |
| GET | `/quizzes/{id}` | `QuizRepository.getQuiz(id)` | Quiz with questions |
| POST | `/quizzes/{id}/attempt` | `QuizRepository.submitAttempt(id, answers)` | Submit answers → score + XP |
| GET | `/leaderboard` | `LeaderboardRepository.getLeaderboard()` | XP leaderboard |
| GET | `/leaderboard/{uid}/rank` | `LeaderboardRepository.getUserRank(uid)` | Single user rank |

### 4.9 Safety awareness

Repository: `lib/repositories/safety_awareness_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/safety-awareness/daily` | `SafetyAwarenessRepository.getDaily()` | Today's safety question |
| POST | `/safety-awareness/answer` (via `POST /safety-awareness/{id}/answer`) | `SafetyAwarenessRepository.submitAnswer()` | Submit answer → XP |

### 4.10 Calendar

Repository: `lib/repositories/calendar_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/calendar/me` | `CalendarRepository.getMyCalendar()` | Aggregated calendar items |
| POST | `/calendar/reminders` | `CalendarRepository.createReminder()` | Set study reminder |
| PATCH | `/calendar/reminders/{id}` | `CalendarRepository.updateReminder()` | Edit reminder |

---

## 5. Role: Admin / Super-Admin

Tabs: **Home**, **Users**, **Manage**, **Impact**, **Settings**.

### 5.1 Admin dashboard and user management

Backend: `backend/app/routers/admin.py`  
Frontend: `lib/repositories/admin_repository.dart`  
ViewModels: `lib/viewmodels/admin_viewmodel.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/admin/stats` | `AdminRepository.getStats()` | Platform overview stats |
| GET | `/admin/dashboard/summary` | `AdminRepository.getDashboardSummary()` | Pending-action counts |
| GET | `/admin/users` | `AdminRepository.getUsers()` | All users (search, filter by status/role) |
| GET | `/admin/users/pending` | `AdminRepository.getPendingUsers()` | Pending approval queue |
| GET | `/admin/users/{id}` | `AdminRepository.getUser(id)` | User detail |
| PATCH | `/admin/users/{id}/approve` | `AdminRepository.approveUser(id, role)` | Approve + assign role |
| PATCH | `/admin/users/{id}/assign-role` | `AdminRepository.assignRole(id, role)` | Change role only |
| PATCH | `/admin/users/{id}/reject` | `AdminRepository.rejectUser(id)` | Reject registration |
| PATCH | `/admin/users/{id}/block` | `AdminRepository.blockUser(id)` | Block account |
| PATCH | `/admin/users/{id}/unblock` | `AdminRepository.unblockUser(id)` | Unblock account |
| DELETE | `/admin/users/{id}` | `AdminRepository.deleteUser(id)` | Permanent delete |
| GET | `/admin/notifications` | `AdminRepository.getNotifications()` | Admin notification list |
| PATCH | `/admin/notifications/{id}/read` | `AdminRepository.markRead(id)` | Mark single read |
| PATCH | `/admin/notifications/read-all` | `AdminRepository.markAllRead()` | Mark all read |

### 5.2 Certificate management (admin)

Backend: `backend/app/routers/certificates.py` (`admin_router` prefix `/admin/certificates`)

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| POST | `/certificates` | `CertificateRepository.generate()` | Generate certificate from approved assignment |
| GET | `/certificates` | `CertificateRepository.getAll()` | All certificates (admin) |
| PATCH | `/certificates/{id}/upload` | `CertificateRepository.uploadSigned(id, file)` | Upload signed PDF |
| GET | `/certificates/{id}` | `CertificateRepository.getById(id)` | Certificate detail |

### 5.3 Volunteer submission review (admin)

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/volunteer/submissions/pending` | `VolunteerRepository.getPendingSubmissions()` | Review queue |
| PATCH | `/volunteer/submissions/{id}/review` | `VolunteerRepository.reviewSubmission(id, status, notes)` | Approve / reject with notes |

### 5.4 Admin settings

Backend: `backend/app/routers/admin_settings.py`  
Repository: `lib/repositories/admin_settings_repository.dart`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/admin/settings/ngo-profile` | NGO name, mission, contact |
| PATCH | `/admin/settings/ngo-profile` | Update NGO profile |
| GET | `/admin/settings/bank` | Bank / UPI details |
| PATCH | `/admin/settings/bank` | Update bank details |
| GET | `/admin/roles` | Role list |
| GET | `/admin/roles/{role}/permissions` | Role permission data |
| PATCH | `/admin/roles/{role}/permissions` | Update permissions |
| GET | `/admin/audit-logs` | Audit log entries |
| POST | `/admin/announcements` | Create announcement |
| GET | `/admin/announcements` | List announcements |
| PATCH | `/admin/announcements/{id}` | Edit announcement |
| DELETE | `/admin/announcements/{id}` | Delete announcement |
| GET | `/admin/app-settings` | App feature flags |
| PATCH | `/admin/app-settings` | Update feature flags |

### 5.5 Donation and stipend management (admin)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/donations` | All donation records |
| PATCH | `/donations/{id}/review` | Approve / reject donation proof |
| GET | `/donations/stipends` | All stipend records |
| PATCH | `/donations/stipends/{id}/approve` | Approve stipend |
| PATCH | `/donations/stipends/{id}/pay` | Mark stipend paid |
| PUT | `/donations/ngo-payment` | Update NGO payment details |
| PUT | `/donations/stipend-config` | Set stipend configuration |

### 5.6 Safety content management (admin)

Backend: `backend/app/routers/safety.py`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/safety-awareness` | All questions |
| POST | `/safety-awareness` | Create question |
| GET | `/safety-awareness/daily` | Today's question |
| GET | `/safety-awareness/{id}` | Single question |
| POST | `/safety-awareness/{id}/answer` | Submit answer |
| PATCH | `/safety-awareness/{id}` | Edit question |
| DELETE | `/safety-awareness/{id}` | Delete question |

### 5.7 Emergency contacts (admin)

Backend: `backend/app/routers/emergency.py`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/emergency-contacts` | List contacts (authenticated) |
| GET | `/emergency-contacts/all` | All contacts including inactive |
| POST | `/emergency-contacts` | Create contact |
| PATCH | `/emergency-contacts/{id}` | Update contact |
| DELETE | `/emergency-contacts/{id}` | Delete contact |

### 5.8 Impact post approval (admin)

Backend: `backend/app/routers/impact.py`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/impact/posts` | All impact posts |
| GET | `/impact/posts/{id}` | Single post detail |
| GET | `/impact/metrics` | Aggregate platform metrics |
| POST | `/impact/posts` | Create impact post draft |
| PATCH | `/impact/posts/{id}` | Edit post or advance status |
| POST | `/impact/posts/{id}/publish` | Admin publishes post to Wall of Impact |
| POST | `/impact/posts/{id}/appreciate` | User appreciation |
| POST | `/impact/posts/{id}/share` | Generate shareable link |

---

## 6. Role: Event Manager

Tabs: **Home**, **Events**, **Students**, **Impact**, **Profile**.

### 6.1 EM dashboard

Backend: `backend/app/routers/event_manager.py`  
Frontend: `lib/repositories/event_manager_repository.dart`  
ViewModel: `lib/viewmodels/event_manager_viewmodel.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/event-manager/dashboard` | `EventManagerRepository.getDashboard()` | Events, assignments, impact posts, stats |
| PATCH | `/event-manager/assignments/{id}` | `EventManagerRepository.updateAssignment(id, status)` | Update assignment status (verify, reject, request resubmission) |

The dashboard response bundles everything in one call:
- `stats`: today_events, active_activities, pending_submissions, students_assigned
- `events`: full event list with nested activities and volunteer counts
- `assignments`: all assignment records with student info and submission data
- `impact_posts`: EM's impact post drafts

### 6.2 Event lifecycle

Backend: `backend/app/routers/events.py`  
Frontend: `lib/repositories/event_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| POST | `/events/create` | `EventRepository.createEvent()` | Create event (also used by admin/creator) |
| GET | `/events` | `EventRepository.getEvents()` | List events (filter by status, type) |
| GET | `/events/{id}` | `EventRepository.getEvent(id)` | Single event |
| PATCH | `/events/{id}` | `EventRepository.updateEvent(id)` | Edit event |
| DELETE | `/events/{id}` | `EventRepository.deleteEvent(id)` | Delete event |
| POST | `/events/{id}/publish` | `EventRepository.publishEvent(id)` | Publish → sets activities `is_active=true` |
| POST | `/events/{id}/status` | `EventRepository.advanceStatus(id, status)` | Move event through pipeline stages |
| GET | `/events/{id}/participants` | `EventRepository.getParticipants(id)` | Registered students |
| POST | `/events/{id}/register` | `EventRepository.register(id)` | Student self-registers |
| POST | `/events/{id}/book-slot` | `EventRepository.bookSlot(id, slotId)` | Book a counselling slot |
| GET | `/events/{id}/my-registration` | `EventRepository.getMyRegistration(id)` | Check own registration |
| POST | `/events/{id}/select` | (admin/EM) | Run selection algorithm on participants |
| GET | `/events/{id}/selections` | (admin/EM) | View selected participants |
| POST | `/events/{id}/quizzes` | (creator/admin) | Attach quiz to event |
| GET | `/events/{id}/quizzes` | (student) | Event quizzes |

**Publish effect on activities**:  
When `POST /events/{id}/publish` is called, `event_crud.publish_event()` calls `_set_linked_activities_active(db, event_id, True)` which sets `is_active=True` on all `VolunteerActivity` records linked to that event. When reverted to draft, they are set `is_active=False`.

### 6.3 Activity creation (EM / admin)

Activities are created separately from events via:

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| POST | `/volunteer/activities` | `EventManagerRepository.createActivity(eventId)` | Create activity linked to event |
| PATCH | `/volunteer/activities/{id}` | `EventManagerRepository.updateActivity(id)` | Edit activity |

### 6.4 Event reports

Backend: `backend/app/routers/reports.py`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| POST | `/events/{id}/reports/generate` | `EventManagerRepository.generateReport(id)` | Generate event report |
| GET | `/events/{id}/reports` | `EventManagerRepository.getReports(id)` | List reports |
| GET | `/events/{id}/reports/{rid}` | `EventManagerRepository.getReport(id, rid)` | Report detail |
| GET | `/events/{id}/reports/{rid}/download` | `EventManagerRepository.reportDownloadUrl()` | PDF download URL |
| POST | `/events/{id}/reports/{rid}/share` | `EventManagerRepository.shareReport(id, rid)` | Generate public URL |
| PATCH | `/events/{id}/reports/{rid}/finalize` | `EventManagerRepository.finalizeReport(id, rid)` | Lock report |
| GET | `/public/event-reports/{token}` | Public URL | Public report access via shared token |

### 6.5 Event status pipeline

```
draft → published → registration_open → selection → scheduled
     → live → work_submission → verification_pending
     → admin_approval_pending → completed
     → impact_published → archived
```

Each `POST /events/{id}/status` call with `new_status` body advances one stage. When `new_status = draft`, linked volunteer activities are deactivated.

### 6.6 Individual assignment status pipeline

```
assigned → submitted → event_manager_verified → admin_approved
                    ↳ resubmission_requested → submitted
                    ↳ rejected
→ certificate_generated → completed
```

EM updates via `PATCH /event-manager/assignments/{id}` with body `{status: "verified"|"rejected", instructions: "..."}`.  
Admin updates via `PATCH /volunteer/submissions/{id}/review`.

---

## 7. Role: Counsellor / Mentor

Tabs: **Home**, **Requests**, **Schedule**, **Sessions**, **Profile**.

### 7.1 Counsellor workspace

Backend: `backend/app/routers/counsellor_workspace.py`  
Frontend: `lib/repositories/counselling_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/counsellor/requests` | `CounsellingRepository.getRequests()` | School counselling requests |
| POST | `/counsellor/requests/{id}/accept` | `CounsellingRepository.acceptRequest(id)` | Accept request → sends notification |
| POST | `/counsellor/requests/{id}/decline` | `CounsellingRepository.declineRequest(id)` | Decline with note |
| POST | `/counsellor/requests/{id}/reschedule` | `CounsellingRepository.reschedule(id)` | Flag for rescheduling |
| GET | `/counsellor/sessions` | `CounsellingRepository.getSessions()` | All sessions |
| GET | `/counsellor/sessions/{id}` | `CounsellingRepository.getSession(id)` | Session detail |
| POST | `/counsellor/sessions/{id}/complete` | `CounsellingRepository.completeSession(id)` | Mark session done |
| POST | `/counsellor/sessions/{id}/report` | `CounsellingRepository.submitReport(id)` | Submit session outcome report |
| GET | `/counsellor/availability` | `CounsellingRepository.getMyAvailability()` | My time slots |
| POST | `/counsellor/availability` | `CounsellingRepository.createSlot()` | Add availability slot |
| PATCH | `/counsellor/availability/{id}` | `CounsellingRepository.updateSlot(id)` | Edit slot |
| DELETE | `/counsellor/availability/{id}` | `CounsellingRepository.deleteSlot(id)` | Remove slot |

### 7.2 Counselling profile

Backend: `backend/app/routers/counselling.py`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/counselling/mentors/me` | Own mentor profile |
| PATCH | `/counselling/mentors/me` | Update mentor profile |
| GET | `/counselling/analytics` | Session analytics |
| POST | `/counselling/calendar/sync/{mentor_id}` | Sync with Google Calendar |

### 7.3 Wellness / user-level counselling

Backend: `backend/app/routers/wellness.py` (prefix `/users/{user_id}/wellness`)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/users/{uid}/wellness/counselling` | Student's booked sessions |
| GET | `/users/{uid}/wellness/counselling/availability` | Available slots |
| POST | `/users/{uid}/wellness/counselling/availability` | Create availability slot |
| PATCH | `/users/{uid}/wellness/counselling/availability/{sid}` | Edit slot |
| DELETE | `/users/{uid}/wellness/counselling/availability/{sid}` | Delete slot |
| POST | `/users/{uid}/wellness/counselling/availability/{sid}/book` | Book a slot |
| POST | `/users/{uid}/wellness/counselling` | Admin: create session directly |
| PATCH | `/users/{uid}/wellness/counselling/{sid}` | Update session |

---

## 8. Role: Content Creator

Tabs: **Home**, **Analytics**, **Upload**, **Content**, **Profile**.

### 8.1 Creator content management

Backend: `backend/app/routers/creator.py`  
Frontend: `lib/repositories/creator_repository.dart`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/creator/home` | `CreatorRepository.getHome()` | Creator dashboard stats |
| GET | `/creator/content` | `CreatorRepository.getContent()` | All creator's content items |
| GET | `/creator/posts` | `CreatorRepository.getPosts()` | Creator's posts |
| POST | `/creator/posts` | `CreatorRepository.createPost()` | Create learning/NGO post |
| GET | `/creator/content/{type}/{id}` | `CreatorRepository.getItem(type, id)` | Single content item |
| PATCH | `/creator/content/{type}/{id}` | `CreatorRepository.updateItem(type, id)` | Edit content |
| DELETE | `/creator/content/{type}/{id}` | `CreatorRepository.deleteItem(type, id)` | Delete content |
| POST | `/creator/content/{type}/{id}/submit-review` | `CreatorRepository.submitForReview(type, id)` | Submit for admin review |
| POST | `/creator/content/{type}/{id}/publish` | `CreatorRepository.publish(type, id)` | Publish content (admin only) |
| POST | `/creator/content/{type}/{id}/unpublish` | `CreatorRepository.unpublish(type, id)` | Unpublish |

`type` is one of: `course`, `lesson`, `quiz`, `post`.

### 8.2 Course and lesson management (creator + admin)

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| POST | `/courses` | `CourseRepository.createCourse()` | Create course |
| PATCH | `/courses/{id}` | `CourseRepository.updateCourse(id)` | Edit course |
| DELETE | `/courses/{id}` | `CourseRepository.deleteCourse(id)` | Delete course |
| POST | `/courses/{id}/lessons` | `CourseRepository.createLesson(cId)` | Add lesson |
| PATCH | `/courses/{id}/lessons/{lId}` | `CourseRepository.updateLesson(cId, lId)` | Edit lesson |
| DELETE | `/courses/{id}/lessons/{lId}` | `CourseRepository.deleteLesson(cId, lId)` | Delete lesson |
| POST | `/courses/{id}/lessons/{lId}/resources` | `CourseRepository.addResource(cId, lId)` | Attach PDF/link resource |
| PATCH | `/courses/{id}/lessons/{lId}/resources/{rId}` | `CourseRepository.updateResource()` | Edit resource |
| DELETE | `/courses/{id}/lessons/{lId}/resources/{rId}` | `CourseRepository.deleteResource()` | Remove resource |
| POST | `/categories` | `CourseRepository.createCategory()` | Create skill category |
| PATCH | `/categories/{id}` | `CourseRepository.updateCategory(id)` | Edit category |
| DELETE | `/categories/{id}` | `CourseRepository.deleteCategory(id)` | Delete category |

### 8.3 File upload

Backend: `backend/app/routers/upload.py`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| POST | `/upload/video` | `CourseRepository.uploadVideo(file)` | Upload lesson video → returns `/video/stream/{filename}` URL |
| POST | `/upload/users/me/photo` | `UserRepository.uploadPhoto(file)` | Upload profile photo → returns URL |
| POST | `/student/upload-proof` | `VolunteerRepository.uploadProof(file)` | Upload work proof file |

### 8.4 Quiz management (creator + admin)

Backend: `backend/app/routers/quiz.py`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/quizzes` | List quizzes (filter by category/status) |
| POST | `/quizzes` | Create quiz |
| GET | `/quizzes/{id}` | Quiz with all questions |
| PATCH | `/quizzes/{id}` | Edit quiz |
| DELETE | `/quizzes/{id}` | Delete quiz |
| GET | `/quizzes/{id}/questions` | List questions |
| POST | `/quizzes/{id}/questions` | Add question |
| PATCH | `/quizzes/{id}/questions/{qid}` | Edit question |
| DELETE | `/quizzes/{id}/questions/{qid}` | Delete question |
| POST | `/quizzes/{id}/attempt` | Submit quiz attempt → score + XP |
| POST | `/quizzes/import` | Bulk import quiz from JSON |
| GET | `/quizzes/{id}/leaderboard` | Quiz-specific leaderboard |
| POST | `/quizzes/daily` | Set today's daily challenge quiz |

---

## 9. Shared modules (all roles)

### 9.1 User profile

Backend: `backend/app/routers/users.py` and `backend/app/routers/profile.py`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/users` | `UserRepository.getUsers()` | All users (admin) |
| PATCH | `/users/me/profile` | `UserRepository.updateProfile()` | Edit own profile fields |
| GET | `/users/{id}` | `UserRepository.getUser(id)` | User detail (admin) |
| PATCH | `/users/{id}` | `UserRepository.updateUser(id)` | Update user (admin) |
| PATCH | `/users/{id}/role` | `UserRepository.assignRole(id, role)` | Change role |
| PATCH | `/users/{id}/status` | `UserRepository.setStatus(id, status)` | Change account status |
| POST | `/users/{id}/xp` | `UserRepository.addXP(id, amount)` | Award XP |
| GET | `/users/{id}/stats` | `UserRepository.getStats(id)` | User stats |
| GET | `/settings/me` | `UserRepository.getSettings()` | User notification settings |
| PATCH | `/settings/me` | `UserRepository.updateSettings()` | Update settings |
| GET | `/profile/reports` | `UserRepository.getProfileReports()` | Profile activity reports |

### 9.2 Notifications

Backend: `backend/app/routers/notifications.py`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/notifications` | `HomeViewModel` (admin) | User notifications |
| POST | `/notifications/{id}/read` | (inline) | Mark single notification read |
| POST | `/notifications/read-all` | `AdminRepository.markAllRead()` | Mark all read |

### 9.3 Badges

Backend: `backend/app/routers/badges.py`

| Method | Endpoint | Flutter call | Purpose |
|---|---|---|---|
| GET | `/badges` | `BadgeRepository.getBadges()` | All badge definitions |
| GET | `/users/{id}/badges` | `BadgeRepository.getUserBadges(id)` | User's earned badges |
| POST | `/users/{id}/badges/{bid}` | (admin) | Award badge to user |

### 9.4 Chat

Backend: `backend/app/routers/chat.py`

| Method | Endpoint | Purpose |
|---|---|---|
| WS | `/ws/chat/{other_user_id}` | Real-time WebSocket chat |
| GET | `/chat/{other_user_id}/history` | Load past messages |
| GET | `/chat/conversations` | List all conversations |

### 9.5 School / parent

Backend: `backend/app/routers/school_partner.py`

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/school/counsellor-requests` | School submits counselling request |
| GET | `/school/my-requests` | School's own requests |
| GET | `/school/my-requests/{id}` | Request detail |
| PATCH | `/school/my-requests/{id}/confirm-time` | Confirm proposed time |
| PATCH | `/school/my-requests/{id}/cancel` | Cancel request |

---

## 10. Complete backend API endpoint index

All routes served by the single FastAPI app at `http://<host>:8000`.

### Authentication (`/auth`)

```
POST   /auth/register
POST   /auth/login
POST   /auth/logout
GET    /auth/me
POST   /auth/change-password
POST   /auth/forgot-password
POST   /auth/verify-reset-code
POST   /auth/reset-password
POST   /auth/google
POST   /auth/auth0
GET    /auth/google/calendar/status
GET    /auth/google/calendar/authorize
GET    /auth/google/callback
```

### Admin (`/admin`)

```
GET    /admin/stats
GET    /admin/dashboard/summary
GET    /admin/users
GET    /admin/users/pending
GET    /admin/users/{user_id}
PATCH  /admin/users/{user_id}/approve
PATCH  /admin/users/{user_id}/assign-role
PATCH  /admin/users/{user_id}/reject
PATCH  /admin/users/{user_id}/block
PATCH  /admin/users/{user_id}/unblock
DELETE /admin/users/{user_id}
GET    /admin/notifications
PATCH  /admin/notifications/{id}/read
PATCH  /admin/notifications/read-all
GET    /admin/settings/ngo-profile
PATCH  /admin/settings/ngo-profile
GET    /admin/settings/bank
PATCH  /admin/settings/bank
GET    /admin/roles
GET    /admin/roles/{role}/permissions
PATCH  /admin/roles/{role}/permissions
GET    /admin/audit-logs
POST   /admin/announcements
GET    /admin/announcements
PATCH  /admin/announcements/{id}
DELETE /admin/announcements/{id}
GET    /admin/app-settings
PATCH  /admin/app-settings
```

### Users (`/users`)

```
GET    /users
POST   /users
PATCH  /users/me/profile
GET    /users/{user_id}
PATCH  /users/{user_id}
PATCH  /users/{user_id}/role
PATCH  /users/{user_id}/status
POST   /users/{user_id}/xp
GET    /users/{user_id}/stats
GET    /users/{user_id}/courses
GET    /settings/me
PATCH  /settings/me
GET    /profile/reports
GET    /profile/reports/{report_id}
```

### Courses & Learning

```
GET    /categories
POST   /categories
PATCH  /categories/{category_id}
DELETE /categories/{category_id}
GET    /courses
POST   /courses
GET    /courses/{id}
GET    /courses/{id}/detail
PATCH  /courses/{id}
DELETE /courses/{id}
GET    /learn/recommended
GET    /learn/courses
GET    /learn/academic
GET    /learn/skills
GET    /users/{user_id}/courses
PUT    /users/{user_id}/courses/{course_id}/progress
GET    /courses/{id}/lessons
POST   /courses/{id}/lessons
PATCH  /courses/{id}/lessons/{lid}
DELETE /courses/{id}/lessons/{lid}
POST   /courses/{id}/lessons/{lid}/complete
PATCH  /lessons/{lid}/complete
GET    /courses/{id}/lessons/{lid}/resources
POST   /courses/{id}/lessons/{lid}/resources
PATCH  /courses/{id}/lessons/{lid}/resources/{rid}
DELETE /courses/{id}/lessons/{lid}/resources/{rid}
```

### Events (`/events`)

```
POST   /events
POST   /events/create
GET    /events
GET    /events/{id}
PATCH  /events/{id}
DELETE /events/{id}
POST   /events/{id}/publish
POST   /events/{id}/status
POST   /events/{id}/quizzes
GET    /events/{id}/quizzes
POST   /events/{id}/slots
GET    /events/{id}/slots
POST   /events/{id}/register
POST   /events/{id}/book-slot
GET    /events/{id}/my-registration
GET    /events/{id}/participants
POST   /events/{id}/select
GET    /events/{id}/selections
POST   /events/{id}/counselling
POST   /events/{id}/reports/generate
GET    /events/{id}/reports
GET    /events/{id}/reports/{rid}
GET    /events/{id}/reports/{rid}/download
POST   /events/{id}/reports/{rid}/share
PATCH  /events/{id}/reports/{rid}/finalize
GET    /public/event-reports/{token}
```

### Event Manager (`/event-manager`)

```
GET    /event-manager/dashboard
PATCH  /event-manager/assignments/{id}
```

### Volunteer (`/volunteer`)

```
GET    /volunteer/activities
GET    /volunteer/activities/{id}
POST   /volunteer/activities
PATCH  /volunteer/activities/{id}
POST   /volunteer/assignments
GET    /volunteer/assignments/me
GET    /volunteer/assignments
POST   /volunteer/submissions
GET    /volunteer/submissions/me
GET    /volunteer/submissions/pending
PATCH  /volunteer/submissions/{id}/review
POST   /volunteer/logs
GET    /volunteer/logs/me
GET    /volunteer/logs/public
PATCH  /volunteer/logs/{id}
PATCH  /volunteer/logs/{id}/approve
GET    /volunteer/impact
POST   /volunteer/impact
PATCH  /volunteer/impact/{id}/publish
GET    /volunteer/stats/me
GET    /volunteer/stats/{student_id}
```

### Student (`/student`)

```
POST   /student/upload-proof
GET    /student/activities
GET    /student/activities/{id}
POST   /student/activities/{id}/apply
GET    /student/assignments
GET    /student/assignments/{id}
POST   /student/assignments/{id}/submit-work
GET    /student/work-summary
```

### Counselling (`/counselling`)

```
GET    /counselling/mentors/me
PATCH  /counselling/mentors/me
GET    /counselling/mentors
GET    /counselling/mentors/{id}
POST   /counselling/mentors
POST   /counselling/mentors/for-user/{user_id}
PATCH  /counselling/mentors/{id}
GET    /counselling/slots
GET    /counselling/slots/mentor/{user_id}
GET    /counselling/analytics
POST   /counselling/calendar/sync/{mentor_id}
```

### Wellness (`/users/{user_id}/wellness`)

```
GET    /users/{uid}/wellness/counselling
GET    /users/{uid}/wellness/counselling/availability
GET    /users/{uid}/wellness/counselling/mentor-slots
GET    /users/{uid}/wellness/counselling/mentor-sessions
POST   /users/{uid}/wellness/counselling/availability
PATCH  /users/{uid}/wellness/counselling/availability/{sid}
DELETE /users/{uid}/wellness/counselling/availability/{sid}
POST   /users/{uid}/wellness/counselling/availability/{sid}/book
POST   /users/{uid}/wellness/counselling
PATCH  /users/{uid}/wellness/counselling/{sid}
```

### Counsellor Workspace

```
GET    /counsellor/requests
POST   /counsellor/requests/{id}/accept
POST   /counsellor/requests/{id}/decline
POST   /counsellor/requests/{id}/reschedule
GET    /counsellor/sessions
GET    /counsellor/sessions/{id}
POST   /counsellor/sessions/{id}/complete
POST   /counsellor/sessions/{id}/report
GET    /counsellor/availability
POST   /counsellor/availability
PATCH  /counsellor/availability/{id}
DELETE /counsellor/availability/{id}
```

### Quizzes (`/quizzes`)

```
GET    /quizzes
POST   /quizzes
GET    /quizzes/daily
POST   /quizzes/daily
GET    /quizzes/users/{user_id}/history
GET    /quizzes/{id}
PATCH  /quizzes/{id}
DELETE /quizzes/{id}
GET    /quizzes/{id}/questions
POST   /quizzes/{id}/questions
PATCH  /quizzes/{id}/questions/{qid}
DELETE /quizzes/{id}/questions/{qid}
POST   /quizzes/{id}/attempt
POST   /quizzes/import
GET    /quizzes/{id}/leaderboard
```

### Certificates

```
POST   /certificates
GET    /certificates/me
GET    /certificates
GET    /certificates/verify/{token}
PATCH  /certificates/{id}/upload
GET    /certificates/{id}
GET    /admin/certificates/{id}          (admin view)
GET    /student/certificates/me
GET    /student/certificates/{id}
GET    /student/certificates/{id}/download
GET    /public/certificates/verify/{token}
```

### Donations (`/donations`)

```
GET    /donations/ngo-payment
PUT    /donations/ngo-payment
GET    /donations/stipend-config
PUT    /donations/stipend-config
POST   /donations
GET    /donations/me
GET    /donations
PATCH  /donations/{id}/review
GET    /donations/stipends/me
GET    /donations/stipends
PATCH  /donations/stipends/{id}/approve
PATCH  /donations/stipends/{id}/pay
```

### Impact (`/impact`)

```
GET    /impact/posts
GET    /impact/posts/{id}
GET    /impact/metrics
POST   /impact/posts
PATCH  /impact/posts/{id}
POST   /impact/posts/{id}/publish
POST   /impact/posts/{id}/appreciate
POST   /impact/posts/{id}/share
```

### Creator (`/creator`)

```
GET    /creator/home
GET    /creator/content
GET    /creator/posts
POST   /creator/posts
GET    /creator/content/{type}/{id}
PATCH  /creator/content/{type}/{id}
DELETE /creator/content/{type}/{id}
POST   /creator/content/{type}/{id}/submit-review
POST   /creator/content/{type}/{id}/publish
POST   /creator/content/{type}/{id}/unpublish
```

### Safety Awareness (`/safety-awareness`)

```
GET    /safety-awareness
POST   /safety-awareness
GET    /safety-awareness/daily
GET    /safety-awareness/questions
GET    /safety-awareness/{id}
POST   /safety-awareness/{id}/answer
PATCH  /safety-awareness/{id}
DELETE /safety-awareness/{id}
```

### Other modules

```
GET    /leaderboard
GET    /leaderboard/{user_id}/rank
GET    /calendar/me
POST   /calendar/reminders
PATCH  /calendar/reminders/{id}
GET    /emergency-contacts
GET    /emergency-contacts/all
POST   /emergency-contacts
PATCH  /emergency-contacts/{id}
DELETE /emergency-contacts/{id}
GET    /notifications
POST   /notifications/{id}/read
POST   /notifications/read-all
GET    /badges
GET    /users/{id}/badges
POST   /users/{id}/badges/{bid}
WS     /ws/chat/{other_user_id}
GET    /chat/{other_user_id}/history
GET    /chat/conversations
POST   /school/counsellor-requests
GET    /school/my-requests
GET    /school/my-requests/{id}
PATCH  /school/my-requests/{id}/confirm-time
PATCH  /school/my-requests/{id}/cancel
POST   /upload/video
POST   /upload/users/me/photo
GET    /video/stream/{filename}
GET    /uploads/{filename}
GET    /health
```

---

## 11. Frontend repository → endpoint mapping

### `lib/repositories/auth_repository.dart`

| Method | Endpoint |
|---|---|
| `login(email, password)` | `POST /auth/login` |
| `getMe()` | `GET /auth/me` |
| `register(...)` | `POST /auth/register` |
| `registerStudent(...)` | `POST /auth/register` |
| `forgotPassword(email)` | `POST /auth/forgot-password` |
| `verifyResetCode(email, code)` | `POST /auth/verify-reset-code` |
| `resetPassword(email, code, newPwd)` | `POST /auth/reset-password` |
| `changePassword(current, new)` | `POST /auth/change-password` |
| `logout()` | `POST /auth/logout` |
| `loginWithAuth0(idToken)` | `POST /auth/auth0` |

### `lib/repositories/volunteer_repository.dart`

| Method | Endpoint |
|---|---|
| `getActivities({category})` | `GET /student/activities[?category=]` |
| `getActivity(id)` | `GET /student/activities/{id}` |
| `getMyAssignments()` | `GET /student/assignments` |
| `applyForActivity(id, note)` | `POST /student/activities/{id}/apply` |
| `submitWork(assignmentId, ...)` | `POST /student/assignments/{id}/submit-work` |
| `submitWork(no assignment, ...)` | `POST /volunteer/submissions` |
| `uploadProof(file)` | `POST /student/upload-proof` (multipart) |
| `getMySubmissions()` | `GET /volunteer/submissions/me` |
| `getPendingSubmissions()` | `GET /volunteer/submissions/pending` |
| `reviewSubmission(id, status, notes)` | `PATCH /volunteer/submissions/{id}/review` |
| `createLog(...)` | `POST /volunteer/logs` |
| `getMyLogs()` | `GET /volunteer/logs/me` |
| `getPublicLogs()` | `GET /volunteer/logs/public` |
| `updateLog(id, ...)` | `PATCH /volunteer/logs/{id}` |
| `getImpactStories({featuredOnly})` | `GET /volunteer/impact[?featured_only=]` |
| `getMyStats()` | `GET /volunteer/stats/me` |

### `lib/repositories/event_repository.dart`

| Method | Endpoint |
|---|---|
| `createEvent(data)` | `POST /events/create` |
| `getEvents({status, type})` | `GET /events` |
| `getEvent(id)` | `GET /events/{id}` |
| `updateEvent(id, data)` | `PATCH /events/{id}` |
| `deleteEvent(id)` | `DELETE /events/{id}` |
| `publishEvent(id)` | `POST /events/{id}/publish` |
| `advanceStatus(id, status)` | `POST /events/{id}/status` |
| `registerForEvent(id)` | `POST /events/{id}/register` |
| `getMyRegistration(id)` | `GET /events/{id}/my-registration` |
| `getParticipants(id)` | `GET /events/{id}/participants` |

### `lib/repositories/event_manager_repository.dart`

| Method | Endpoint |
|---|---|
| `getDashboard()` | `GET /event-manager/dashboard` |
| `updateAssignment(id, status, note)` | `PATCH /event-manager/assignments/{id}` |
| `createActivity(eventId, data)` | `POST /volunteer/activities` |
| `generateReport(eventId)` | `POST /events/{id}/reports/generate` |
| `getReports(eventId)` | `GET /events/{id}/reports` |
| `shareReport(eventId, reportId)` | `POST /events/{id}/reports/{rid}/share` |
| `finalizeReport(eventId, reportId)` | `PATCH /events/{id}/reports/{rid}/finalize` |
| `reportDownloadUrl(eventId, reportId)` | builds `GET /events/{id}/reports/{rid}/download` URL |

### `lib/repositories/admin_repository.dart`

| Method | Endpoint |
|---|---|
| `getStats()` | `GET /admin/stats` |
| `getDashboardSummary()` | `GET /admin/dashboard/summary` |
| `getUsers({status, role, search})` | `GET /admin/users` |
| `getPendingUsers()` | `GET /admin/users/pending` |
| `getUser(id)` | `GET /admin/users/{id}` |
| `approveUser(id, role)` | `PATCH /admin/users/{id}/approve` |
| `rejectUser(id)` | `PATCH /admin/users/{id}/reject` |
| `blockUser(id)` | `PATCH /admin/users/{id}/block` |
| `deleteUser(id)` | `DELETE /admin/users/{id}` |
| `getNotifications()` | `GET /admin/notifications` |
| `markRead(id)` | `PATCH /admin/notifications/{id}/read` |
| `markAllRead()` | `PATCH /admin/notifications/read-all` |

### `lib/repositories/counselling_repository.dart`

| Method | Endpoint |
|---|---|
| `getMentors()` | `GET /counselling/mentors` |
| `getMentor(id)` | `GET /counselling/mentors/{id}` |
| `getMentorSlots(uid)` | `GET /counselling/slots/mentor/{uid}` |
| `getRequests()` | `GET /counsellor/requests` |
| `acceptRequest(id)` | `POST /counsellor/requests/{id}/accept` |
| `declineRequest(id)` | `POST /counsellor/requests/{id}/decline` |
| `getSessions()` | `GET /counsellor/sessions` |
| `getMyAvailability()` | `GET /counsellor/availability` |
| `createSlot(data)` | `POST /counsellor/availability` |
| `updateSlot(id, data)` | `PATCH /counsellor/availability/{id}` |
| `deleteSlot(id)` | `DELETE /counsellor/availability/{id}` |
| `getChatHistory(otherUserId)` | `GET /chat/{other_user_id}/history` |

### `lib/repositories/course_repository.dart`

| Method | Endpoint |
|---|---|
| `getCategories()` | `GET /categories` |
| `getSkillCourses()` | `GET /learn/skills` |
| `getAcademicCourses()` | `GET /learn/academic` |
| `getCourses()` | `GET /courses` |
| `getCourse(id)` | `GET /courses/{id}` |
| `getCourseDetail(id)` | `GET /courses/{id}/detail` |
| `createCourse(data)` | `POST /courses` |
| `updateCourse(id, data)` | `PATCH /courses/{id}` |
| `getLessons(cId)` | `GET /courses/{id}/lessons` |
| `createLesson(cId, data)` | `POST /courses/{id}/lessons` |
| `updateLesson(cId, lId, data)` | `PATCH /courses/{id}/lessons/{lid}` |
| `completeLesson(cId, lId)` | `POST /courses/{id}/lessons/{lid}/complete` |
| `getResources(cId, lId)` | `GET /courses/{id}/lessons/{lid}/resources` |
| `addResource(cId, lId, data)` | `POST /courses/{id}/lessons/{lid}/resources` |

### `lib/repositories/certificate_repository.dart`

| Method | Endpoint |
|---|---|
| `getMyCertificates()` | `GET /student/certificates/me` (student) or `GET /certificates/me` |
| `getCertificate(id)` | `GET /certificates/{id}` |
| `generate(assignmentId)` | `POST /certificates` |
| `uploadSigned(id, file)` | `PATCH /certificates/{id}/upload` |
| `downloadUrl(id)` | builds `GET /student/certificates/{id}/download` URL |

### `lib/repositories/donation_repository.dart`

| Method | Endpoint |
|---|---|
| `getNGOPaymentDetails()` | `GET /donations/ngo-payment` |
| `submitDonation(...)` | `POST /donations` |
| `getMyDonations()` | `GET /donations/me` |
| `getMyStipends()` | `GET /donations/stipends/me` |

### `lib/repositories/quiz_repository.dart`

| Method | Endpoint |
|---|---|
| `getDailyChallenge()` | `GET /quizzes/daily` |
| `getQuiz(id)` | `GET /quizzes/{id}` |
| `submitAttempt(id, answers)` | `POST /quizzes/{id}/attempt` |
| `getQuizzes()` | `GET /quizzes` |
| `createQuiz(data)` | `POST /quizzes` |
| `updateQuiz(id, data)` | `PATCH /quizzes/{id}` |
| `addQuestion(quizId, data)` | `POST /quizzes/{id}/questions` |

### `lib/repositories/creator_repository.dart`

| Method | Endpoint |
|---|---|
| `getHome()` | `GET /creator/home` |
| `getContent()` | `GET /creator/content` |
| `submitForReview(type, id)` | `POST /creator/content/{type}/{id}/submit-review` |
| `publish(type, id)` | `POST /creator/content/{type}/{id}/publish` |
| `delete(type, id)` | `DELETE /creator/content/{type}/{id}` |

### `lib/repositories/impact_repository.dart`

| Method | Endpoint |
|---|---|
| `getPosts()` | `GET /impact/posts` |
| `getMetrics()` | `GET /impact/metrics` |
| `createPost(data)` | `POST /impact/posts` |
| `updatePost(id, data)` | `PATCH /impact/posts/{id}` |
| `publishPost(id)` | `POST /impact/posts/{id}/publish` |
| `appreciatePost(id)` | `POST /impact/posts/{id}/appreciate` |
| `sharePost(id)` | `POST /impact/posts/{id}/share` |

---

## 12. Data flow diagrams

### Student registers and gets approved

```
Student: POST /auth/register
  → Backend: creates User(access_status=pending, role=null)
  → Returns: JWT with access_status=pending
  → Flutter: shows PendingApprovalScreen

Admin: GET /admin/users/pending  (sees new registration)
Admin: PATCH /admin/users/{id}/approve  (role=student)
  → Backend: User.access_status=approved, User.role=student
  → Sends notification to student

Student: POST /auth/login (next login)
  → Returns: JWT with role=student, access_status=approved
  → Flutter: mounts StudentShell → HomeView
```

### Admin publishes event → student sees activities

```
Admin/EM: POST /events/create  →  Event(status=draft)
Admin/EM: POST /volunteer/activities  {event_id: X}  →  VolunteerActivity(is_active=False)

Admin/EM: POST /events/{id}/publish
  → Backend: Event.status=published
  → Backend: UPDATE volunteer_activities SET is_active=True WHERE event_id=X
  → Returns: updated Event

Student: GET /student/activities
  → Backend query:
      SELECT * FROM volunteer_activities va
      LEFT JOIN events e ON va.event_id = e.id
      WHERE va.is_active=True OR e.status IN ('published','registration_open','live')
  → Returns: [activity "collect people", ...]
  → Flutter: _NGOOpenActivitiesCard shows activity
```

### Student applies for activity

```
Student: POST /student/activities/{id}/apply  {note: "..."}
  → Backend: creates ActivityApplication(student_id, activity_id, status=pending)
  → Returns: ApplicationOut

Admin/EM: GET /event-manager/dashboard  (sees application)
Admin/EM: POST /volunteer/assignments  {student_id, activity_id}
  → Backend: creates ActivityAssignment(status=assigned)
  → Notifies student

Student: GET /student/assignments  →  sees assignment
Student: POST /student/assignments/{id}/submit-work  {hours, description, proof_files}
  → Backend: ActivityAssignment.status=submitted
  → Notifies EM

EM: PATCH /event-manager/assignments/{id}  {status: "verified"}
  → Backend: status=event_manager_verified

Admin: PATCH /volunteer/submissions/{id}/review  {status: "approved"}
  → Backend: status=admin_approved
  → Student impact stats update
```

### Work submission → certificate flow

```
Assignment status: admin_approved

Admin: POST /certificates  {assignment_id}
  → Certificate(status=pending, assignment=admin_approved)

Admin: PATCH /certificates/{id}/upload  (signed PDF)
  → Certificate(status=signed, file_url=...)

Student: GET /student/certificates/me  →  sees certificate
Student: GET /student/certificates/{id}/download  →  opens PDF
```

---

## 13. Start the application

### Backend

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Must run from the `backend/` directory. The `app` module is at `backend/app/main.py`.

### Frontend — URL configuration (`lib/core/config.dart`)

Priority order:
1. `--dart-define=API_BASE_URL=<url>` — direct override
2. `--dart-define=BACKEND_ENV=<name>` — named environment
3. `_defaultBackendEnvironment` in config.dart (default: `'local'`)

| Environment name | URL |
|---|---|
| `local` | `http://10.42.112.128:8000` (ZeroTier LAN) |
| `ngrok` / `tunnel` | ngrok HTTPS URL |
| `android` / `emulator` | `http://10.0.2.2:8000` |
| `same-host` | Flutter Web host + `:8000` |

### Run commands

```bash
# Chrome (same machine)
flutter run -d chrome --web-port=5000 \
  --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator
flutter run -d emulator \
  --dart-define=BACKEND_ENV=android

# Physical Android (ZeroTier)
flutter run -d <device-id> \
  --dart-define=BACKEND_ENV=local

# Physical Android (ngrok)
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app
```

### Backend logs

```bash
tail -f /tmp/careskill_backend.log
```

---

## 14. Troubleshooting

### Backend does not start — `No module named 'app'`

Must run from the `backend/` directory:
```bash
cd backend && uvicorn app.main:app --reload
```

### Student activities are empty despite published event

- The admin must have published the event **after** the `_set_linked_activities_active` fix was deployed, OR
- The `/student/activities` endpoint now includes activities from published events even if `is_active=False` (via `outerjoin` on events) — restart the backend to pick up this change.
- Confirm the student's JWT has `role=student`; the endpoint returns 403 for other roles.
- Pull-to-refresh the student home screen.

### Student dashboard shows 403 for activity endpoint

The student user's `role` field in the database must be `student`. Check via `GET /admin/users/{id}`. If still `null` or `pending`, the admin must approve and assign the student role.

### App cannot reach backend

```bash
curl http://localhost:8000/health          # local
curl http://10.0.2.2:8000/health           # from emulator
```

For physical Android: device must be on the same network or using ngrok. ZeroTier IP: confirm with `ip addr show zt*`.

### Token expires / 401 errors

JWT expiry is 60 minutes. `ApiClient` auto-clears session on 401. Log in again. The backend's `POST /auth/logout` blacklists the old token's `jti`.

### Publish/Unpublish button not toggling

The event detail sheet is a `StatefulWidget` (`_EventDetailSheet`). It calls `EventRepository.publishEvent(id)` or `EventRepository.advanceStatus(id, 'draft')` and rebuilds with the returned status. If the button shows the wrong state, pull-to-refresh the events list to reload the full event from `GET /event-manager/dashboard`.

### Counselling Meet link missing

Google Calendar OAuth must be authorized for the counsellor account via `GET /auth/google/calendar/authorize`. Sessions without it show a manual placeholder link.

### Video does not play

Video requires a valid Bearer token in the Authorization header (stream uses authenticated range requests at `/video/stream/{filename}`). Confirm `AppState.token` is not expired.

### Submission totals (hours, donations) do not update

Stats are computed from `admin_approved` submissions only. The student's impact score updates only after the admin approves — not at EM-verify or submit stages.
