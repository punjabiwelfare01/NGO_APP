# CareSkill — Complete Project Description

> NGO Learning & Counselling Platform  
> Stack: Flutter (MVVM) + FastAPI + SQLite + Google Calendar API + Auth0 + WebSocket

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [System Architecture](#system-architecture)
3. [Role Hierarchy & Permissions](#role-hierarchy--permissions)
4. [App Navigation Structure](#app-navigation-structure)
5. [Authentication Flow](#authentication-flow)
6. [State Management Pattern](#state-management-pattern)
7. [Feature: Home](#feature-home)
8. [Feature: Learn](#feature-learn)
9. [Feature: Events](#feature-events)
10. [Feature: Helping Support & Counselling](#feature-helping-support--counselling)
11. [Feature: Chat (WebSocket)](#feature-chat-websocket)
12. [Feature: Profile & Badges](#feature-profile--badges)
13. [Google Meet Auto-Generation Flow](#google-meet-auto-generation-flow)
14. [Backend API Map](#backend-api-map)
15. [Database Models](#database-models)
16. [Data Flow: ViewState Lifecycle](#data-flow-viewstate-lifecycle)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart), Material 3, MVVM |
| HTTP Client | `package:http` via `ApiClient` |
| WebSocket | `web_socket_channel` |
| Auth | Auth0 (Native OAuth) + JWT (local email/password) |
| Backend | FastAPI (Python 3.11) |
| Database | SQLite via SQLAlchemy ORM + Alembic |
| Calendar/Meet | Google Calendar API v3 (OAuth2) |
| Tunnelling | ngrok (dev) |
| Testing | pytest + FastAPI TestClient |

---

## System Architecture

```mermaid
graph TB
    subgraph Flutter["Flutter App (Android / Web)"]
        UI[Screens & Widgets]
        VM[ViewModels\nChangeNotifier]
        REPO[Repositories]
        AC[ApiClient\nHTTP + JWT]
        WS[ChatService\nWebSocket]
        AS[AppState\nGlobal Singleton]
        SS[SessionStorage\nPersistent Token]
    end

    subgraph Backend["FastAPI Backend"]
        MW[Middleware\nCORS + RBAC Logging]
        AUTH_R[/auth router/]
        USER_R[/users router/]
        WELL_R[/wellness router/]
        COUN_R[/counselling router/]
        COURSE_R[/courses router/]
        EVENT_R[/events router/]
        QUIZ_R[/quiz router/]
        CHAT_R[/chat WebSocket/]
        SAFE_R[/safety router/]
        EMRG_R[/emergency router/]
        BADGE_R[/badges router/]
        DB[(SQLite DB)]
        GCal[Google Calendar API]
    end

    subgraph Auth["Auth Providers"]
        Auth0[Auth0\nNative OAuth]
        JWT[JWT\nLocal]
    end

    UI --> VM
    VM --> REPO
    REPO --> AC
    REPO --> WS
    AC --> MW
    WS --> CHAT_R
    MW --> AUTH_R & USER_R & WELL_R & COUN_R
    MW --> COURSE_R & EVENT_R & QUIZ_R & SAFE_R & EMRG_R & BADGE_R
    AUTH_R --> Auth0
    AUTH_R --> JWT
    WELL_R --> GCal
    AUTH_R & USER_R & WELL_R & COUN_R & COURSE_R & EVENT_R --> DB
    QUIZ_R & SAFE_R & EMRG_R & BADGE_R & CHAT_R --> DB
    AS --> AC
    AS --> SS
```

---

## Role Hierarchy & Permissions

```mermaid
graph TD
    SA[super_admin]
    AD[admin]
    ME[mentor]
    CC[content_creator]
    ST[student]
    GU[guest]

    SA -->|inherits all| AD
    AD -->|inherits all| ME
    ME -->|inherits content| CC
    CC -->|more than| ST
    ST -->|more than| GU

    style SA fill:#e74c3c,color:#fff
    style AD fill:#e67e22,color:#fff
    style ME fill:#2980b9,color:#fff
    style CC fill:#8e44ad,color:#fff
    style ST fill:#27ae60,color:#fff
    style GU fill:#95a5a6,color:#fff
```

```mermaid
graph LR
    subgraph Mentor["Mentor Only"]
        M1[Create counselling slots]
        M2[Manage slot bookings]
        M3[Chat with students]
        M4[Award badges]
        M5[View student wellness data]
    end

    subgraph ContentCreator["Content Creator Only"]
        C1[View booking analytics]
        C2[Manage mentor profiles]
    end

    subgraph Shared["Mentor + Content Creator"]
        S1[Create / edit lessons]
        S2[Create / edit quizzes]
        S3[Create / publish events]
        S4[Set daily challenge]
    end

    subgraph Admin["Admin + Above"]
        A1[Manage all users]
        A2[Google Calendar status]
        A3[Emergency contacts]
        A4[Safety questions]
    end

    subgraph Student["Student"]
        T1[Browse mentors]
        T2[Book sessions]
        T3[Take quizzes]
        T4[Enroll in courses]
        T5[Register for events]
    end
```

---

## App Navigation Structure

```mermaid
graph TD
    ENTRY[App Launch\nmain.dart]
    RESTORE[AppState.restore\nfrom SessionStorage]
    ENTRY --> RESTORE

    RESTORE -->|token exists| HOME
    RESTORE -->|no token| LOGIN

    LOGIN[LoginView\n/login]
    LOGIN -->|email+password| JWTLOGIN[AuthViewModel.login]
    LOGIN -->|Auth0 button| AUTH0[AuthViewModel.loginWithAuth0]
    JWTLOGIN & AUTH0 -->|success| HOME

    HOME[AppShell\nBottomNavigationBar]

    HOME --> NAV1[Home\nindex 0]
    HOME --> NAV2[Learn\nindex 1]
    HOME --> NAV3[Events\nindex 2]
    HOME --> NAV4[Helping Support\nindex 3]
    HOME --> NAV5[Profile\nindex 4]

    NAV1 --> HomeView
    NAV2 --> LearnView
    NAV3 --> EventsView
    NAV4 --> HelpingSupportView
    NAV5 --> ProfileView
```

---

## Authentication Flow

```mermaid
sequenceDiagram
    actor User
    participant LoginView
    participant AuthViewModel
    participant AuthRepository
    participant Backend as FastAPI /auth
    participant AppState
    participant SessionStorage

    User->>LoginView: Enter email + password
    LoginView->>AuthViewModel: login(email, password)
    AuthViewModel->>AuthViewModel: state = loading
    AuthViewModel->>AuthRepository: login(email, password)
    AuthRepository->>Backend: POST /auth/login {email, password}
    Backend-->>AuthRepository: {access_token, role, user_id, name}
    AuthRepository-->>AuthViewModel: TokenResponse
    AuthViewModel->>AppState: setFromLogin(userId, token, role)
    AppState->>SessionStorage: persist token + userId + role
    AuthViewModel->>AuthViewModel: state = idle
    AuthViewModel-->>LoginView: return true
    LoginView->>LoginView: Navigator.pushReplacementNamed('/home')

    Note over User,SessionStorage: Auth0 Flow
    User->>LoginView: Tap "Sign in with Auth0"
    LoginView->>AuthViewModel: loginWithAuth0()
    AuthViewModel->>AuthRepository: loginWithAuth0()
    AuthRepository->>Backend: POST /auth/auth0 {id_token}
    Backend->>Backend: verify_auth0_token(id_token)
    Backend-->>AuthRepository: {access_token, role, user_id, name}
    AuthRepository-->>AuthViewModel: TokenResponse
    AuthViewModel->>AppState: setFromLogin(...)
```

---

## State Management Pattern

```mermaid
stateDiagram-v2
    [*] --> idle : ViewModel created
    idle --> loading : load() called
    loading --> idle : data fetched successfully
    loading --> error : ApiException or network error
    error --> loading : retry / load() called again
    idle --> idle : filterByCategory / local update

    note right of loading
        notifyListeners() → UI shows
        CircularProgressIndicator
    end note

    note right of error
        errorMessage set
        notifyListeners() → UI shows
        error banner + Retry button
    end note

    note right of idle
        data lists populated
        notifyListeners() → UI
        renders content
    end note
```

```mermaid
graph LR
    subgraph MVVM["MVVM Layer Responsibilities"]
        V[View / Screen\nStatelessWidget or StatefulWidget\nListens to ViewModel]
        VM2[ViewModel\nextends ChangeNotifier\nHolds ViewState + data\nCalls Repository]
        R[Repository\nStatic methods\nWraps ApiClient calls\nReturns typed models]
        M[Model\nPlain Dart class\nfromJson factory\nImmutable]
    end
    V -->|reads state + data| VM2
    VM2 -->|calls| R
    R -->|returns| M
    M -->|rendered by| V
```

---

## Feature: Home

```mermaid
graph TD
    HomeView -->|creates| HVM[HomeViewModel]
    HVM -->|Future.wait parallel| P1[CourseRepository.getCategories]
    HVM -->|Future.wait parallel| P2[WellnessRepository.getCounsellingSessions]
    HVM -->|Future.wait parallel| P3[QuizRepository.getDailyChallenge]
    HVM -->|Future.wait parallel| P4[EventRepository.getEvents counselling-drive]
    HVM -->|Future.wait parallel| P5[WellnessRepository.getAvailableSlots]

    HomeView --> W1[WelcomeBanner\nuser name + level]
    HomeView --> W2[UpcomingCounsellingBanner\nshows next session with Meet link]
    HomeView --> W3[CounsellingSessionCard\nquick book widget]
    HomeView --> W4[DailyChallengeCard\nquiz shortcut]
    HomeView --> W5[SkillCategoryCard × N\nbrowse courses]
    HomeView --> W6[DailyMotivationCard]
    HomeView --> W7[SafetyStoryCard]
    HomeView --> W8[ParentPreviewPanel\nparent role only]
```

---

## Feature: Learn

```mermaid
graph TD
    LearnView -->|creates| LVM[LearnViewModel]
    LVM --> CourseRepository

    LearnView --> CourseList[Course list\nCourseCard widgets]
    CourseList -->|tap| CourseDetail[CourseDetailScreen\nlesson list]
    CourseDetail -->|tap lesson| LessonViewer[LessonViewerScreen\nvideo + text]

    subgraph AdminContent["Admin / Content Creator"]
        LearnView --> CreateLesson[CreateLessonScreen]
        CreateLesson --> CourseRepository2[CourseRepository.createLesson\nPOST /courses/lessons]
    end

    CourseDetail -->|enroll| CourseRepository3[CourseRepository.enrollUser\nPOST /courses/id/enroll]
```

---

## Feature: Events

```mermaid
graph TD
    EventsView --> EVL[EventListViewModel]
    EVL --> EventRepository

    EventsView --> EList[EventListScreen\nfilter by type]
    EList -->|tap| EDetail[EventDetailScreen\nrules, timeline, prizes]
    EDetail -->|register| RegForm[EventRegistrationFormScreen]
    RegForm --> EventRepository2[EventRepository.register\nPOST /events/id/register]

    subgraph AdminEvents["Admin / Mentor / Content Creator"]
        EventsView --> EM[EventManagerScreen]
        EM --> CEV[CreateEventView\n8-step wizard]
        CEV --> Step1[Step 1: Basic Info\ntitle, type, theme]
        CEV --> Step2[Step 2: Timeline\ndates]
        CEV --> Step3[Step 3: Rules]
        CEV --> Step4[Step 4: Quiz\nattach quiz]
        CEV --> Step5[Step 5: Selection\nlucky draw / merit]
        CEV --> Step6[Step 6: Rewards\nbadge, certificate]
        CEV --> Step7[Step 7: Notifications\npush / email]
        CEV --> Step8[Step 8: Preview & Publish]
    end

    subgraph QuizPlay["Quiz Play"]
        EDetail -->|start quiz| QPScreen[QuizPlayScreen]
        QPScreen --> QPVM[QuizPlayViewModel]
        QPVM --> QuizRepository
        QPScreen --> QRScreen[QuizResultScreen\nXP + badge award]
    end
```

---

## Feature: Helping Support & Counselling

```mermaid
graph TD
    HSV[HelpingSupportView]

    HSV -->|role: student| SV[Student View]
    HSV -->|role: mentor| MV[Mentor View]
    HSV -->|role: admin/cc| AV[Admin View]

    subgraph StudentView["Student"]
        SV --> MList[MentorListScreen\nbrowse mentors]
        SV --> MSess[MySessionsScreen\nupcoming + past]
        SV --> AllSlots[AllSlotsScreen\nall available slots]
        MList -->|tap mentor| MDetail[MentorDetailScreen]
        MDetail -->|book| SlotBook[SlotBookingScreen\ntopic + slot select]
        SlotBook --> WR[WellnessRepository\nPOST .../availability/id/book]
        MSess -->|has meet link| JoinMeet[Open Meet URL\nurl_launcher]
        SV --> ChatBtn[Chat with mentor\nChatScreen]
    end

    subgraph MentorView["Mentor"]
        MV --> MChats[MentorChatsScreen\nstudent list]
        MV --> MSched[MentorScheduleScreen\ntabs: Slots / Bookings]
        MSched --> FAB[FAB: New Session Slot]
        FAB --> CreateSheet[_CreateSlotSheet\nbottom sheet]
        CreateSheet --> Fields[Topic + Date/Time\nDuration + Capacity\nMeeting URL optional]
        Fields -->|submit| WR2[WellnessRepository\nPOST .../availability]
        WR2 -->|backend auto-generates| GCal[Google Meet link\ngoogle_calendar.py]
    end

    subgraph AdminView["Admin / Content Creator"]
        AV --> CAScreen[CounsellingAdminScreen\nmanage mentor profiles]
        AV --> ECScreen[EmergencyContactsAdminScreen]
    end
```

### Counselling Session Booking — Full Sequence

```mermaid
sequenceDiagram
    actor Mentor
    actor Student
    participant MentorUI as MentorScheduleScreen
    participant WellnessRepo
    participant Backend as FastAPI /wellness
    participant GCal as google_calendar.py
    participant StudentUI as SlotBookingScreen
    participant SessionsUI as MySessionsScreen

    Mentor->>MentorUI: Tap "+ New Session Slot"
    MentorUI->>MentorUI: Open _CreateSlotSheet
    Mentor->>MentorUI: Fill topic, date, time, duration, capacity
    Mentor->>MentorUI: Leave Meeting URL blank
    MentorUI->>WellnessRepo: createAvailabilitySlot(startsAt, endsAt, topic, capacity, meetingUrl=null)
    WellnessRepo->>Backend: POST /users/{id}/wellness/counselling/availability
    Backend->>GCal: create_meet_link(title, starts_at, ends_at)
    GCal->>GCal: _get_credentials() → valid token?
    alt Calendar authorized
        GCal-->>Backend: "https://meet.google.com/xxx-yyyy-zzz"
        Backend->>Backend: save slot with meeting_url
    else Not authorized
        GCal-->>Backend: None
        Backend->>Backend: save slot without meeting_url
    end
    Backend-->>WellnessRepo: ApiCounsellingSlot (with or without meetingUrl)
    WellnessRepo-->>MentorUI: slot created
    MentorUI->>MentorUI: _load() refresh — slot appears in "My Slots" tab

    Student->>StudentUI: Browse available slots
    StudentUI->>WellnessRepo: getAvailableSlots(userId)
    WellnessRepo->>Backend: GET /users/{id}/wellness/counselling/availability
    Backend-->>StudentUI: list of slots with meetingUrl
    Student->>StudentUI: Tap "Book" on a slot
    StudentUI->>WellnessRepo: bookAvailabilitySlot(userId, slotId, topic)
    WellnessRepo->>Backend: POST .../availability/{slotId}/book {topic}
    Backend->>Backend: create CounsellingSession\ncopy meetingUrl from slot
    Backend-->>StudentUI: ApiCounsellingSession {meetingUrl, status: upcoming}
    Student->>SessionsUI: View My Sessions
    SessionsUI->>SessionsUI: Show session card with "Join" button
    Student->>SessionsUI: Tap "Join"
    SessionsUI->>SessionsUI: url_launcher → opens Google Meet
```

---

## Feature: Chat (WebSocket)

```mermaid
sequenceDiagram
    participant Flutter as ChatScreen (Flutter)
    participant CS as ChatService
    participant WS as WebSocket /ws/chat/{userId}
    participant Backend as FastAPI chat router
    participant DB as ChatMessage table

    Flutter->>CS: ChatService(otherUserId: X)
    Flutter->>CS: connect()
    CS->>WS: WebSocket.connect(wss://.../ws/chat/X?token=JWT)
    Backend->>Backend: verify JWT, resolve room(mentor_id, student_id)
    Backend->>DB: load message history
    Backend-->>WS: {"type":"history","messages":[...]}
    WS-->>CS: history received → historyCompleter.complete(list)
    CS-->>Flutter: List<ChatMessage> (past messages)
    Flutter->>Flutter: render history in ListView

    loop Live messages
        Flutter->>CS: send("Hello!")
        CS->>WS: sink.add({"content":"Hello!"})
        Backend->>DB: save ChatMessage
        Backend-->>WS: {"type":"message","content":"Hello!","sender_id":...}
        WS-->>CS: stream event
        CS->>CS: _controller.add(ChatMessage)
        CS-->>Flutter: messages stream emits
        Flutter->>Flutter: ListView appends new bubble
    end

    Flutter->>CS: dispose()
    CS->>WS: sink.close()
```

---

## Feature: Profile & Badges

```mermaid
graph TD
    ProfileView -->|creates| PVM[ProfileViewModel]
    PVM --> UserRepository
    PVM --> BadgeRepository
    PVM --> WellnessRepository

    ProfileView --> PHC[ProfileHeroCard\nname, level, XP bar]
    ProfileView --> AT[AnalyticsTile\nweekly hours + skill growth]
    ProfileView --> BP[BadgePill × N\nearned badges]
    ProfileView --> CHC[CounsellingHistoryCard\npast sessions]

    subgraph XP["XP & Level System"]
        QuizCorrect[Correct quiz answer] -->|+XP| Backend
        SafetyAnswer[Safety awareness answer] -->|+5 XP| Backend
        Backend -->|xp // 500 + 1| Level[User.level updated]
    end
```

---

## Google Meet Auto-Generation Flow

```mermaid
flowchart TD
    A[Mentor submits Create Slot form] --> B{meeting_url provided?}
    B -->|Yes| C[Use provided URL\nno API call]
    B -->|No| D[call create_meet_link]
    D --> E{_get_credentials valid?}
    E -->|No token file| F[return None\nslot saved without URL]
    E -->|Token expired + refresh_token| G[creds.refresh Request]
    G -->|success| H[save refreshed token\ngoogle_token.json]
    G -->|GoogleAuthError| F
    H --> I[build Calendar service]
    E -->|Token valid| I
    I --> J[service.events.insert\nconferenceDataVersion=1]
    J -->|HttpError| F
    J -->|success| K{video entryPoint\nin response?}
    K -->|No| F
    K -->|Yes| L[return meet.google.com/xxx URL]
    C & L & F --> M[slot saved to DB\nwith or without meetingUrl]
    M --> N[ApiCounsellingSlot returned to Flutter]
    N --> O[Slot card shows Meet link chip]

    subgraph OneTimeSetup["One-Time Admin Setup"]
        S1[Admin: GET /auth/google/calendar/authorize]
        S2[get_authorization_url returns OAuth URL]
        S3[Admin opens URL in browser]
        S4[Google consent screen]
        S5[Redirect to /auth/google/callback?code=...&state=...]
        S6[exchange_code_for_tokens saves google_token.json]
        S1 --> S2 --> S3 --> S4 --> S5 --> S6
    end
```

---

## Backend API Map

```mermaid
graph LR
    subgraph Auth["/auth"]
        A1[POST /auth/register]
        A2[POST /auth/login]
        A3[POST /auth/logout]
        A4[GET  /auth/me]
        A5[POST /auth/google]
        A6[POST /auth/auth0]
        A7[GET  /auth/google/calendar/status]
        A8[GET  /auth/google/calendar/authorize]
        A9[GET  /auth/google/callback]
    end

    subgraph Users["/users"]
        U1[GET  /users]
        U2[GET  /users/me]
        U3[PATCH /users/id]
        U4[GET  /users/id/stats]
    end

    subgraph Wellness["/users/{id}/wellness"]
        W1[GET  .../counselling]
        W2[POST .../counselling]
        W3[PATCH .../counselling/session_id]
        W4[GET  .../counselling/availability]
        W5[POST .../counselling/availability]
        W6[PATCH .../counselling/availability/slot_id]
        W7[DELETE .../counselling/availability/slot_id]
        W8[POST .../counselling/availability/slot_id/book]
        W9[GET  .../counselling/mentor-slots]
        W10[GET .../counselling/mentor-sessions]
    end

    subgraph Counselling["/counselling"]
        COU1[GET  /counselling/mentors]
        COU2[GET  /counselling/mentors/id]
        COU3[POST /counselling/mentors]
        COU4[PATCH /counselling/mentors/id]
        COU5[GET  /counselling/slots]
        COU6[GET  /counselling/slots/mentor/user_id]
        COU7[GET  /counselling/analytics]
    end

    subgraph Courses["/courses"]
        CO1[GET  /courses/categories]
        CO2[GET  /courses]
        CO3[POST /courses/id/enroll]
        CO4[POST /courses/lessons]
        CO5[PATCH /courses/lessons/id]
        CO6[DELETE /courses/lessons/id]
    end

    subgraph Events["/events"]
        EV1[GET  /events]
        EV2[POST /events]
        EV3[GET  /events/id]
        EV4[PATCH /events/id]
        EV5[POST /events/id/publish]
        EV6[POST /events/id/register]
        EV7[POST /events/id/quiz]
    end

    subgraph Quiz["/quiz"]
        Q1[GET  /quiz]
        Q2[POST /quiz]
        Q3[GET  /quiz/daily-challenge]
        Q4[POST /quiz/daily-challenge]
        Q5[POST /quiz/id/attempt]
        Q6[POST /quiz/id/questions]
    end

    subgraph Chat["/chat + WebSocket"]
        CH1[GET  /chat/conversations]
        CH2[WS   /ws/chat/other_user_id]
    end

    subgraph Safety["/safety"]
        SA1[GET  /safety/questions]
        SA2[POST /safety/questions]
        SA3[POST /safety/answers]
    end

    subgraph Emergency["/emergency"]
        EM1[GET  /emergency/contacts]
        EM2[POST /emergency/contacts]
        EM3[DELETE /emergency/contacts/id]
    end

    subgraph Badges["/badges"]
        BA1[GET  /users/id/badges]
        BA2[POST /users/id/badges]
    end
```

---

## Database Models

```mermaid
erDiagram
    User {
        int id PK
        string name
        string email UK
        string hashed_password
        int age
        int level
        int xp
        enum role
        bool is_active
        string parent_email
        datetime created_at
    }

    CounsellingAvailability {
        int id PK
        int mentor_id FK
        string mentor_name
        datetime starts_at
        datetime ends_at
        string topic
        int capacity
        int booked_count
        string meeting_url
        bool is_active
    }

    CounsellingSession {
        int id PK
        int user_id FK
        int slot_id FK
        int mentor_id FK
        string counsellor_name
        string topic
        datetime scheduled_at
        datetime ends_at
        enum status
        string meeting_url
        string notes
    }

    MentorProfile {
        int id PK
        int user_id FK
        string display_name
        string bio
        string expertise
        string category
        string profile_image_url
        bool is_active
        float rating
        int session_count
    }

    Course {
        int id PK
        string title
        string category
        string description
        string icon_name
    }

    Lesson {
        int id PK
        int course_id FK
        string title
        string content
        string video_url
        int order_index
    }

    Event {
        int id PK
        string title
        enum event_type
        enum status
        string theme_color
        datetime registration_start
        datetime registration_end
        datetime event_start
        datetime event_end
        bool counselling_enabled
        bool scholarship_enabled
    }

    Quiz {
        int id PK
        string title
        string category
        enum difficulty
        int xp_reward
    }

    Question {
        int id PK
        int quiz_id FK
        string question_text
        string option_a
        string option_b
        string option_c
        string option_d
        enum correct_option
    }

    DailyChallenge {
        int id PK
        int quiz_id FK
        date challenge_date
    }

    ChatMessage {
        int id PK
        int mentor_id FK
        int student_id FK
        int sender_id FK
        string content
        datetime created_at
    }

    Badge {
        int id PK
        string icon_name
        string label
        string category
    }

    UserBadge {
        int id PK
        int user_id FK
        int badge_id FK
        datetime earned_at
    }

    EmergencyContact {
        int id PK
        string name
        string phone
        string description
        string category
        bool is_active
    }

    SafetyAwarenessQuestion {
        int id PK
        string question_text
        string option_a
        string option_b
        string option_c
        enum correct_option
        string explanation
        string category
        bool is_active
    }

    User ||--o{ CounsellingSession : "books"
    User ||--o{ MentorProfile : "has"
    User ||--o{ UserBadge : "earns"
    User ||--o{ ChatMessage : "sends"
    CounsellingAvailability ||--o{ CounsellingSession : "generates"
    Course ||--o{ Lesson : "contains"
    Quiz ||--o{ Question : "has"
    Quiz ||--o| DailyChallenge : "featured as"
    Badge ||--o{ UserBadge : "awarded via"
```

---

## Data Flow: ViewState Lifecycle

```mermaid
sequenceDiagram
    participant Screen
    participant ViewModel
    participant Repository
    participant ApiClient
    participant FastAPI

    Screen->>ViewModel: ListenableBuilder watches ViewModel
    Screen->>ViewModel: initState → vm.load()
    ViewModel->>ViewModel: _state = loading\nnotifyListeners()
    Screen->>Screen: renders CircularProgressIndicator

    ViewModel->>Repository: static method call
    Repository->>ApiClient: get/post/patch/delete
    ApiClient->>ApiClient: attach Bearer token from AppState
    ApiClient->>FastAPI: HTTP request + timeout 10s
    FastAPI->>FastAPI: verify JWT → RBAC check → DB query
    FastAPI-->>ApiClient: JSON response

    alt Success (2xx)
        ApiClient-->>Repository: decoded JSON
        Repository-->>ViewModel: typed model / list
        ViewModel->>ViewModel: populate lists\n_state = idle\nnotifyListeners()
        Screen->>Screen: renders data widgets
    else ApiException (4xx/5xx)
        ApiClient->>ApiClient: throw ApiException(statusCode, body)
        ViewModel->>ViewModel: _state = error\n_errorMessage set\nnotifyListeners()
        Screen->>Screen: renders error banner + Retry button
    else Timeout / Network error
        ViewModel->>ViewModel: _state = error\n"Could not reach server"
        Screen->>Screen: renders error banner + Retry button
    end
```

---

## File Structure Summary

```
lib/
├── main.dart                    ← app entry, AppShell (BottomNav), routes
├── app_state.dart               ← global singleton: userId, token, role
├── core/
│   ├── config.dart              ← API URLs, Auth0, timeouts, constants
│   └── colors.dart              ← AppColors design tokens
├── models/
│   ├── auth_models.dart         ← UserRole enum, TokenResponse
│   ├── api_models.dart          ← ApiCounsellingSession, ApiCounsellingSlot, AppUser, ...
│   ├── counselling_models.dart  ← MentorProfile, CounsellingAnalytics
│   ├── event_models.dart        ← EventModel, EventType, EventStatus
│   ├── quiz_models.dart         ← QuizModel, DailyChallengeModel
│   └── ...
├── repositories/
│   ├── api_client.dart          ← HTTP wrapper: get/post/patch/delete/multipart
│   ├── auth_repository.dart     ← login, logout, Auth0 flow
│   ├── wellness_repository.dart ← counselling sessions + slots CRUD
│   ├── counselling_repository.dart ← mentor profiles + analytics
│   ├── course_repository.dart
│   ├── event_repository.dart
│   ├── quiz_repository.dart
│   └── ...
├── viewmodels/
│   ├── view_state.dart          ← enum ViewState { idle, loading, error }
│   ├── auth_viewmodel.dart
│   ├── counselling_viewmodel.dart
│   ├── home_viewmodel.dart
│   ├── learn_viewmodel.dart
│   ├── create_event_viewmodel.dart
│   └── ...
├── screens/
│   ├── auth/login_view.dart
│   ├── home/home_view.dart + widgets/
│   ├── learn/learn_view.dart + ...
│   ├── events/events_view.dart + admin/ + student/
│   ├── helping_support/
│   │   ├── helping_support_view.dart
│   │   ├── mentor/mentor_schedule_screen.dart   ← slot creation + Meet link
│   │   ├── mentor/mentor_chats_screen.dart
│   │   ├── student/slot_booking_screen.dart
│   │   ├── student/my_sessions_screen.dart
│   │   └── widgets/live_session_banner.dart
│   ├── profile/profile_view.dart + widgets/
│   └── wellness/wellness_view.dart + widgets/
└── services/
    ├── chat_service.dart        ← WebSocket connection manager
    └── session_storage.dart     ← platform-safe token persistence

backend/
├── app/
│   ├── main.py                  ← FastAPI app, middleware, router registration
│   ├── config.py                ← Settings from .env
│   ├── database.py              ← SQLAlchemy engine + session
│   ├── dependencies.py          ← get_current_user, require_role, admin_only, mentor_or_above
│   ├── google_calendar.py       ← OAuth2 + Meet link auto-generation
│   ├── models/                  ← SQLAlchemy ORM models
│   ├── schemas/                 ← Pydantic request/response schemas
│   ├── crud/                    ← DB query functions
│   └── routers/
│       ├── auth.py              ← login, register, Auth0, Google Calendar OAuth
│       ├── wellness.py          ← counselling slots + sessions + booking
│       ├── counselling.py       ← mentor profiles + analytics
│       ├── courses.py
│       ├── events.py
│       ├── quiz.py
│       ├── chat.py              ← WebSocket + REST conversation list
│       ├── safety.py
│       ├── emergency.py
│       ├── badges.py
│       └── users.py
└── tests/
    ├── conftest.py              ← shared fixtures, test DB, user helpers
    ├── test_auth.py
    ├── test_events.py
    ├── test_quiz.py
    ├── test_safety.py
    └── test_google_meet.py      ← 27 tests: unit + API for Meet integration
```
