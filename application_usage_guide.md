# Application Usage Guide
## CareSkill NGO Platform — Step-by-Step Guide for All Roles

---

## Table of Contents

1. [Workflow Diagrams](#workflow-diagrams)
   - [Platform Role Hierarchy](#platform-role-hierarchy)
   - [Registration & Approval Flow](#registration--approval-flow)
   - [School Counselling End-to-End](#school-counselling-end-to-end-sequence)
   - [Volunteer Activity Flow](#volunteer-activity-flow)
   - [Content Publishing Flow](#content-publishing-flow)
   - [Event Pipeline Flow](#event-pipeline-flow)
   - [Counselling Request Status States](#counselling-request-status-states)
   - [Certificate Lifecycle](#certificate-lifecycle)
2. [Student / Youth Member](#2-student--youth-member)
3. [Admin / Super Admin](#3-admin--super-admin)
4. [Event Manager](#4-event-manager)
5. [Counsellor (Mentor)](#5-counsellor-mentor)
6. [Content Creator](#6-content-creator)
7. [School Partner](#7-school-partner)

---

## Workflow Diagrams

### Platform Role Hierarchy

```mermaid
flowchart TD
    APP([CareSkill App])
    APP --> G[Guest\nread-only preview]
    APP --> S[Student / Youth Member\nlearn · volunteer · book sessions]
    APP --> SP[School Partner\nbrowse counsellors · book sessions]
    APP --> CC[Content Creator\nupload courses · lessons · notes]
    APP --> M[Counsellor / Mentor\naccept requests · run sessions]
    APP --> EM[Event Manager\ncreate events · approve work · post impact]
    APP --> A[Admin\nmanage users · verify donations · publish]
    APP --> SA[Super Admin\nfull platform control]

    style SA fill:#1a237e,color:#fff
    style A  fill:#1565c0,color:#fff
    style EM fill:#2e7d32,color:#fff
    style M  fill:#4527a0,color:#fff
    style CC fill:#e65100,color:#fff
    style SP fill:#00695c,color:#fff
    style S  fill:#0277bd,color:#fff
    style G  fill:#546e7a,color:#fff
```

---

### Registration & Approval Flow

> Applies to every new user regardless of role.

```mermaid
flowchart TD
    A([Open App]) --> B[Tap Register]
    B --> C{Access Type?}
    C -->|Student| D[Fill Student Form\nname · email · class · school · parent email]
    C -->|School / Volunteer| E[Fill Staff Form\nname · email · phone · requested role]
    D --> F[Submit Registration]
    E --> F
    F --> G[Account Status: PENDING]
    G --> H[Admin receives notification]
    H --> I{Admin Decision}
    I -->|Approve| J[Status → APPROVED]
    I -->|Reject| K[Status → REJECTED]
    J --> L[User receives approval notification]
    K --> M[User sees rejection screen]
    L --> N[User logs in → Role Dashboard]
    M --> O[User may re-register\nwith corrected details]

    style G fill:#f57f17,color:#fff
    style J fill:#2e7d32,color:#fff
    style K fill:#c62828,color:#fff
    style N fill:#1565c0,color:#fff
```

---

### School Counselling End-to-End Sequence

> Shows every actor involved from booking through session completion.

```mermaid
sequenceDiagram
    actor SP as School Partner
    actor C  as Counsellor
    actor EM as Event Manager
    actor A  as Admin
    participant SYS as CareSkill Backend

    SP->>SYS: Browse counsellor directory
    SP->>SYS: Submit booking request (topic, date, students)
    SYS-->>C: 🔔 New request notification
    SYS-->>A: 🔔 New request notification

    alt Counsellor Accepts (single tap — no double-accept)
        C->>SYS: Tap Accept on request card
        SYS-->>SP: 🔔 "Counsellor accepted your request"
        SYS->>SYS: Schedule 3 reminders (24h · 2h · 15min before session)
        SYS->>SYS: Reveal coordinator contact to counsellor
    else Counsellor Reschedules
        C->>SYS: Tap Reschedule → pick new date/time
        SYS-->>SP: 🔔 "New time suggested"
        SP->>SYS: Confirm new time  OR  Cancel request
        SYS-->>C: 🔔 "School confirmed / cancelled"
    else Counsellor Declines
        C->>SYS: Tap Decline → select reason + optional note
        SYS-->>SP: 🔔 "Request declined: [reason]"
    end

    Note over EM,SYS: Event Manager coordinates logistics
    EM->>SYS: Assign EM to request, add preparation notes
    SYS-->>C: Meeting link & coordinator contact revealed

    Note over C,SP: Session is conducted
    C->>SYS: Tap Mark Session as Completed (from Meeting Detail screen)
    C->>SYS: Submit session report\n(notes · students attended · rating)
    SYS-->>A: Session report saved to records
```

---

### Volunteer Activity Flow

```mermaid
flowchart TD
    EM1([Event Manager\nCreates Event]) --> ACT[Activity added to Event\nwith proof requirements & reward hours]
    ACT --> PUB[Event Published]
    PUB --> STU[Student sees Activity\non Home / Volunteer tab]
    STU --> APPLY[Student taps Apply]
    APPLY --> STATUS1[Status: Applied]
    STATUS1 --> ASSIGN{Event Manager\nreviews applications}
    ASSIGN -->|Assigns student| STATUS2[Status: Assigned]
    ASSIGN -->|Not selected| END1[Application not progressed]
    STATUS2 --> WORK[Student does the work]
    WORK --> SUBMIT[Student submits proof\ndescription · photo / doc · date]
    SUBMIT --> STATUS3[Status: Work Submitted]
    STATUS3 --> EM_REV{Event Manager\nreviews proof}
    EM_REV -->|Approve| STATUS4[Status: EM Approved\nFlagged for Admin]
    EM_REV -->|Reject| REJ[Rejected with reason\nStudent notified]
    STATUS4 --> ADMIN_REV{Admin\nfinal review}
    ADMIN_REV -->|Approve| CERT_ELIG[Student is Certificate-Eligible\nAppears in Ready tab]
    ADMIN_REV -->|Reject| REJ2[Rejected — student notified]
    CERT_ELIG --> GEN[Admin fills certificate details\nvia Ready tab → Generate]
    GEN --> DRAFT_CERT[Certificate created as Draft]
    DRAFT_CERT --> APPROVE[Admin approves certificate]
    APPROVE --> PUB_CERT[Certificate status → Generated\nPublished to student profile]
    PUB_CERT --> STU2([Student previews\ndownloads or shares Certificate])

    style STATUS1 fill:#1565c0,color:#fff
    style STATUS2 fill:#4527a0,color:#fff
    style STATUS3 fill:#f57f17,color:#fff
    style STATUS4 fill:#2e7d32,color:#fff
    style CERT_ELIG fill:#00695c,color:#fff
    style PUB_CERT fill:#1b5e20,color:#fff
```

---

### Content Publishing Flow

```mermaid
flowchart LR
    CC([Content Creator]) -->|1. Creates| COURSE[New Course\ntitle · category · level]
    COURSE -->|2. Adds| LESSON[Lesson\nvideo · PDF notes · text]
    LESSON -->|3. Submits| PENDING[Status: Pending Review]
    PENDING -->|4. Admin reviews| DEC{Decision}
    DEC -->|Approve| LIVE[Status: Published\nVisible to all students]
    DEC -->|Reject| REJ[Rejected with reason]
    REJ -->|Creator edits| LESSON
    LIVE -->|Student opens| LEARN[Student watches video\nreads notes · marks complete]
    LEARN --> XP[Student earns XP\nprogress tracked]

    style PENDING fill:#f57f17,color:#fff
    style LIVE    fill:#2e7d32,color:#fff
    style REJ     fill:#c62828,color:#fff
    style XP      fill:#1565c0,color:#fff
```

---

### Event Pipeline Flow

```mermaid
flowchart LR
    S1([Admin / EM\nCreates Event]) --> S2[DRAFT\nsave & edit freely]
    S2 -->|Publish| S3[PUBLISHED\nvisible to staff]
    S3 -->|Open Registration| S4[REGISTRATION OPEN\nstudents can apply]
    S4 -->|Launch| S5[ONGOING\nwork submissions active]
    S5 -->|Close| S6[COMPLETED\nall work finalized]
    S6 -->|Archive| S7[ARCHIVED\nread-only record]

    S6 --> RP[EM generates\nImpact Report]
    RP --> IP[EM creates\nImpact Post draft]
    IP --> ADM{Admin\nreviews draft}
    ADM -->|Approve| WALL[Published to\nWall of Impact]
    ADM -->|Request changes| IP

    style S2 fill:#546e7a,color:#fff
    style S3 fill:#1565c0,color:#fff
    style S4 fill:#4527a0,color:#fff
    style S5 fill:#f57f17,color:#fff
    style S6 fill:#2e7d32,color:#fff
    style S7 fill:#37474f,color:#fff
    style WALL fill:#1b5e20,color:#fff
```

---

### Counselling Request Status States

```mermaid
stateDiagram-v2
    [*] --> new_request : School Partner submits booking

    new_request --> accepted      : Counsellor accepts (single tap)
    new_request --> rescheduled   : Counsellor suggests new time
    new_request --> declined      : Counsellor declines with reason
    new_request --> cancelled     : School Partner cancels

    rescheduled --> pending_confirmation : School Partner confirms new time
    rescheduled --> cancelled            : School Partner cancels

    pending_confirmation --> confirmed : Event Manager confirms logistics
    pending_confirmation --> cancelled : Cancelled before confirmation

    accepted --> pending_confirmation : EM coordinates and confirms

    confirmed --> scheduled  : Meeting link + details set
    scheduled --> completed  : Counsellor marks session as completed
    completed --> [*]

    declined  --> [*]
    cancelled --> [*]
```

---

### Certificate Lifecycle

```mermaid
stateDiagram-v2
    [*] --> draft : Admin fills details via Ready tab

    draft --> pending        : Admin submits for approval
    pending --> approved     : Admin approves + adds signatory
    pending --> rejected     : Admin rejects with reason

    approved --> generated   : PDF generated
    generated --> issued     : Issued to student
    issued --> downloaded    : Student downloads

    approved --> revoked : Admin revokes
    generated --> revoked : Admin revokes
    issued --> revoked : Admin revokes

    downloaded --> [*]
    revoked --> [*]
    rejected --> [*]
```

> **All certificate statuses (draft, pending, approved, generated, issued) now support:**
> Edit Details · Preview · Download · Revoke · Create Impact Story — buttons are shown on every certificate card and enabled based on the current status.

---

## 2. Student / Youth Member

### Flow Overview

```mermaid
flowchart TD
    REG([Register & Get Approved]) --> HOME[Home Tab]
    HOME --> DAILY[Daily Challenge Quiz\nearn XP]
    HOME --> ASSIGN[My Assignments\nview & submit volunteer work]
    HOME --> SESS[Counselling Session\nquick access]

    HOME --> LEARN[Learn Tab]
    LEARN --> BROWSE[Browse Courses\nby skill category]
    BROWSE --> COURSE[Open Course]
    COURSE --> LESSON[Take Lesson\nvideo · notes · text]
    LESSON --> COMPLETE[Mark Complete\nprogress updated]
    COMPLETE --> XP[Earn XP]

    HOME --> VOL[Volunteer Tab]
    VOL --> APPLY[Apply for Activity]
    APPLY --> SUBMIT_W[Submit Work Proof]
    SUBMIT_W --> CERTIF[Receive Certificate]

    HOME --> SUPPORT[Support Tab]
    SUPPORT --> MENTOR[Browse Mentors]
    MENTOR --> BOOK[Book Session\nselect slot · confirm]
    BOOK --> JOIN[Join Meeting]

    HOME --> PROFILE[Profile Tab]
    PROFILE --> CERTS[View Certificates]
    PROFILE --> REPORTS[View Reports]
    PROFILE --> NOTIFS[View Notifications]
```

### Registration & First Login

**Step 1 — Open the App**
- Launch the CareSkill app on your Android device.
- You will land on the Login / Register screen.

**Step 2 — Create Your Account**
- Tap the **Register** tab at the top.
- Select your access type: **Student** or **School / Volunteer**.
- Fill in the registration form:
  - Full Name, Email Address, Password & Confirm Password
  - Age, Class / Grade, School Name, Location (City), Phone Number, Parent / Guardian Email
- If applying for a non-student role (e.g., Volunteer, Event Support), select it in the **Requested Role** field.
- Tap **Register**.

**Step 3 — Wait for Account Approval**
- After registering, your account will show a **Pending Approval** screen.
- An Admin will review your registration and approve or reject it.
- You will receive an in-app notification once the decision is made.

**Step 4 — Login After Approval**
- Enter your registered email and password → Tap **Sign In**.
- You are now inside the Student dashboard.

---

### Home Screen (Tab 1)

**Step 5 — Explore the Home Screen**
- At the top you see your **Daily Motivation Card** — an inspirational quote refreshed daily.
- Below that is the **Continue Learning** section showing your last accessed course.
- Scroll down to see **Skill Categories** — tap any to open Learn filtered by that skill.

**Step 6 — Daily Challenge (Quiz)**
- Find the **Daily Challenge** card on the Home screen.
- Tap **Start Challenge** to open a quiz tied to today's topic.
- Answer all questions and tap **Submit** to see your score and earn XP points.

**Step 7 — My Assignments**
- Scroll down on Home to find **My Assignments** — volunteer activities you have been assigned to.
- Tap any assignment card to see details and submit your work.

**Step 8 — Open Activities**
- Below assignments is **Open Activities** — upcoming volunteer opportunities you can apply for.
- Tap **Apply** on any activity card to submit your application.
- Application status progresses: Applied → Assigned → Work Submitted → Verified.

**Step 9 — Counselling Session Quick Access**
- The **Counselling Session** card on Home shows your next upcoming session with a mentor.
- Tap **Book** to go directly to the session booking flow.

---

### Learn (Tab 2)

**Step 10 — Browse Courses**
- Tap the **Learn** tab (book icon) at the bottom navigation bar.
- Browse courses organized by skill categories: Defence, Wellness, Career, Safety, etc.

**Step 11 — Open a Course**
- Tap any course card to open the **Course Detail** screen.
- Read the description, see lessons, and check your progress bar.
- Tap **Start Learning** or **Continue**.

**Step 12 — Take a Lesson**
- Inside a course, tap any lesson from the list.
- A lesson can contain: video content, PDF notes / study material, and text explanations.
- After completing a lesson, tap **Mark as Complete** to record your progress.

---

### Volunteer / Internship (Tab 3)






















**Step 13 — View Your Volunteer Dashboard**
- Tap the **Volunteer** tab (heart icon).
- At the top you see your stats: total hours earned, XP, activities completed, certificates issued.

**Step 14 — Apply for an Activity**
- Tap **Browse Activities** to see all open volunteer opportunities.
- Tap any activity card to view full details, then tap **Apply for This Activity**.

**Step 15 — Submit Your Work**
- After being assigned, tap **Submit Work** on the activity card.
- Fill in: description of work done, upload proof (photo / document / link), date of completion.
- Tap **Submit** to send for verification.

**Step 16 — Make a Donation**
- Tap **Donate** on the Volunteer dashboard.
- Select the activity or cause, enter the amount, upload payment proof, tap **Submit Donation Proof**.

**Step 17 — Log Daily Volunteer Hours**
- Tap **Daily Log** → select the date, activity, and hours spent → Tap **Save Log**.

**Step 18 — View My Certificates**
- Tap **My Certificates** to see all certificates you have earned.
- Certificates appear once an admin generates and approves them for your activity.

**Step 19 — Wall of Impact**
- Tap **Wall of Impact** to view published impact stories from the NGO.
- Tap the heart icon on any post to appreciate it.

---

### Helping & Support (Tab 4)

**Step 20 — Browse Mentors**
- Tap the **Support** tab (headset icon).
- View the list of available mentors, filter by specialization or language.

**Step 21 — Book a Counselling Session**
- On a mentor's profile, tap **Book a Session**.
- Select an available time slot → Tap **Confirm Booking**.
- If the mentor has added a Google Meet link, tap **Join Meeting** directly.

**Step 22 — View My Sessions**
- Tap **My Sessions** to view all upcoming and past counselling sessions.

**Step 23 — Wellness & Safety Resources**
- On the Support screen scroll down to access: Safety Awareness, Emergency Contacts, Wellness Exercises.

---

### Profile (Tab 5)

**Step 24 — View Your Profile**
- Tap the **Profile** tab to see your name, level, XP, and profile photo.

**Step 25 — View Certificates & Reports**
- Tap **Certificates** or **Reports** on the Profile screen.

**Step 26 — Notifications**
- Tap the **Bell** icon to view all in-app notifications.

**Step 27 — Settings**
- Tap the **Gear** icon → update profile details, change password, or **Sign Out**.

---

## 3. Admin / Super Admin

### Flow Overview

```mermaid
flowchart TD
    LOGIN([Admin Login]) --> DASH[Admin Dashboard\nHome Tab]

    DASH --> USERS[Users Tab]
    USERS --> PEND[Review Pending Registrations]
    PEND --> DEC{Decision}
    DEC -->|Approve| NOTIF_A[User Approved + Notified]
    DEC -->|Reject| NOTIF_R[User Rejected + Notified]
    USERS --> ROLE[Change User Role]

    DASH --> MANAGE[Manage Tab]
    MANAGE --> EVENTS[Events & Activities\ncreate · publish · pipeline]
    MANAGE --> COUNS[Counsellors\nadd · verify · feature]
    MANAGE --> VOLWORK[Volunteer Work\nfinal approval]
    MANAGE --> DONATE[Donations\nverify payment proof]
    MANAGE --> CERTS[Certificates\nReady · Pending · All tabs\nall actions on every cert]
    MANAGE --> SAFETY[Safety Questions\ncreate awareness content]
    MANAGE --> EMERG[Emergency Contacts\nmanage helplines]

    DASH --> IMPACT[Impact Tab]
    IMPACT --> DRAFT[Review Impact Post Drafts]
    DRAFT --> PUB{Approve?}
    PUB -->|Yes| WALL[Published to Wall of Impact]
    PUB -->|No| BACK[Send back with feedback]

    DASH --> SETTINGS[Settings Tab\nNGO profile · roles · security · audit logs · announcements]

    style NOTIF_A fill:#2e7d32,color:#fff
    style NOTIF_R fill:#c62828,color:#fff
    style WALL    fill:#1b5e20,color:#fff
```

### Login

**Step 1 — Login**
- Open the app and enter your admin credentials on the Login screen → Tap **Sign In**.
- You are taken directly to the **Admin Dashboard**.

---

### Home (Tab 1)

**Step 2 — View Admin Overview**
- The Home screen shows key platform metrics:
  - **Pending Users** — users waiting for account approval.
  - **Active Events** — currently running events.
  - **Platform Analytics** — impact posts published, volunteers active, certificates generated.

**Step 3 — Quick Action Shortcuts from Home**
- Tap any quick action: View Pending, Open Users, Open Events, Open Counselling, Open Safety, Open Emergency, Open Volunteer.

---

### Users (Tab 2)

**Step 4 — Search & Filter Users**
- Tap the **Users** tab → view all registered users.
- Use the search bar or filter by role or status (pending / approved / rejected).

**Step 5 — Approve or Reject a Registration**
- Tap any user with *Pending* status.
- Review their details → Tap **Approve** or **Reject**.
- The user receives an in-app notification immediately.

**Step 6 — Change a User's Role**
- Open a user's detail screen → Tap **Change Role** → Select the new role → Tap **Confirm**.

---

### Manage (Tab 3)

**Step 7 — Access the Manage Hub**
- Tap the **Manage** tab → grid of management tools covering every platform module.

#### Events & Activities

**Step 8 — Create a New Event**
- Tap **Events & Activities** → Tap **+ Create Event**.
- Complete the multi-step event creation wizard:
  - Step 1: Basic info — title, description, category, start and end dates
  - Step 2: Location / mode — online or offline, venue or meeting link
  - Step 3: Activities — add volunteer tasks with reward hours and proof requirements
  - Step 4: Registration settings — open registration, eligibility criteria
  - Step 5: Notifications — set up alerts for participants
- Tap **Publish** to make the event live or **Save as Draft** to review later.

**Step 9 — Manage the Event Pipeline**
- Tap **Event Pipeline** → browse stages: Draft → Published → Registration Open → Ongoing → Completed → Archived.
- Tap any event to open its full pipeline detail with sub-tabs: Overview, Activities, Volunteers, Reports.

#### Counsellors

**Step 10 — Add a New Counsellor**
- Tap **Counsellors** → Tap **Add Counsellor** (+ icon).
- Fill in the counsellor profile form: name, designation, category, bio, expertise areas, session topics, available slots, qualifications, recognitions.
- Toggle **Featured**, **Active**, and **Verified** as appropriate → Tap **Save Counsellor Profile**.

**Step 11 — Manage School Requests**
- Tap **School Requests** to view all incoming school counselling bookings and their current status.

#### Volunteer Work

**Step 12 — Review Volunteer Submissions**
- Tap **Volunteer Work** → see all submitted proof waiting for final admin approval.
- Tap a submission → view description and proof → Tap **Approve** or **Reject**.

#### Donations & Certificates

**Step 13 — Verify a Donation**
- Tap **Donations & Stipends** → view pending donation proofs.
- Tap a donation → view screenshot / receipt → Tap **Verify** or **Reject**.

**Step 14 — Certificate Management (3 Tabs)**

The Certificate Management screen has three tabs:

- **Ready** tab — Shows assignments where the EM has approved work and the student is certificate-eligible.
  - Each card shows student name, activity, hours, and work details.
  - Tap **Fill Details & Generate** to open the certificate detail form, fill in the signatory name/title and any extra information, then generate the certificate.

- **Pending** tab — Shows certificates awaiting admin approval.
  - Available actions on every card: **Edit Details**, **Preview**, **Download**, **Approve**, **Reject**, **Revoke**, **Create Impact Story**.
  - Tap **Approve** → optionally add signatory name and title → Tap **Approve** to confirm.
  - Tap **Reject** → enter a reason → Tap **Reject** (student is notified).

- **All** tab — Shows every certificate across all statuses (Draft, Pending, Approved, Generated, Issued, Rejected, Revoked).
  - Available actions on every card: **Edit Details**, **Preview**, **Download**, **Approve** (if pending), **Reject** (if pending), **Revoke** (unless already revoked/rejected), **Create Impact Story** (if no story exists yet).

> **Note:** All certificate cards — regardless of status (Draft, Pending, Generated, etc.) — now show the full set of action buttons. The buttons are enabled or disabled based on the certificate's current status.

**Step 15 — Revoke a Certificate**
- On any active certificate card, tap **Revoke** → enter a revocation reason → Tap **Revoke**.
- The certificate status changes to *Revoked* and the student is notified.

**Step 16 — Create an Impact Story from a Certificate**
- On any eligible certificate card (no existing story), tap **Create Impact Story**.
- Review or edit the pre-filled impact summary → Tap **Create Story**.
- A draft impact story is created; edit and publish it from the Social Impact section.

---

### Impact (Tab 4)

**Step 17 — Review and Publish Impact Posts**
- Tap the **Impact** tab → view draft posts submitted by Event Managers.
- Tap any draft → Tap **Approve & Publish** or **Request Changes**.

---

### Settings (Tab 5)

**Step 18 — Platform Settings**
- Tap the **Settings** tab → configure:
  - **NGO Profile & Bank Details** — update NGO name, logo, bank account for donations.
  - **Roles & Permissions** — manage role access across the platform.
  - **Security & Audit Logs** — view login history and security events.
  - **Announcements** — broadcast messages to all users.
  - **Application Settings** — general platform configuration.

---

## 4. Event Manager

### Flow Overview

```mermaid
flowchart TD
    LOGIN([Event Manager Login]) --> HOME[Home Tab\ntoday priority · stats · quick actions]

    HOME --> EVENTS[Events Tab]
    EVENTS --> CREATE[Create Event\nmulti-step wizard]
    EVENTS --> PIPE[Event Pipeline\nadvance stages]
    PIPE --> STAGES[Draft → Published\n→ Registration Open\n→ Ongoing → Completed]

    HOME --> STUDENTS[Students Tab]
    STUDENTS --> APPS[View Applications]
    APPS --> REVIEW{Review Submission}
    REVIEW -->|Approve| FLAG[Flagged for Admin Approval]
    REVIEW -->|Reject| NOTIF[Student Notified\nwith reason]
    FLAG --> ADMIN_OK[Admin approves]
    ADMIN_OK --> READY[Appears in Certificate Ready tab]
    READY --> GEN_CERT[Admin generates Certificate]

    HOME --> IMPACT[Impact Tab]
    IMPACT --> AUTO[Generate Impact Post\nfrom event data]
    AUTO --> EDIT[Edit draft text]
    EDIT --> SUBMIT_ADM[Submit for Admin Approval]
    SUBMIT_ADM --> PUBLISH[Published to Wall of Impact]

    IMPACT --> REPORT[Generate Event Report\nparticipants · hours · certs · donations]
    REPORT --> FINALIZE[Finalize Report\nlocks event record]

    style FLAG  fill:#f57f17,color:#fff
    style PUBLISH fill:#1b5e20,color:#fff
    style GEN_CERT fill:#2e7d32,color:#fff
```

### Login

**Step 1 — Login**
- Enter your Event Manager credentials → Tap **Sign In**.
- You are directed to the **Event Manager Dashboard**.

---

### Home (Tab 1)

**Step 2 — View Today's Priority**
- Home shows the **Today's Priority Card** and a **Stats Row**: Total Events, Active Volunteers, Pending Submissions, Impact Drafts.

**Step 3 — Use Quick Actions**
- Tap any Quick Action: Approve Submissions, Create Event, Review Pipeline, Post Impact.

---

### Events (Tab 2)

**Step 4 — View All Your Events**
- Tap the **Events** tab → browse all events across pipeline stages.

**Step 5 — Create a New Event**
- Tap the **+** button → complete the multi-step event creation wizard → Tap **Save as Draft** or **Publish**.

**Step 6 — Advance an Event's Status**
- Open any event → Tap **Advance Status** to move it through the pipeline:
  - Draft → Published → Registration Open → Ongoing → Completed.

---

### Students (Tab 3)

**Step 7 — View All Student Applications**
- Tap the **Students** tab → see all students who have applied for activities.
- Filter by event, activity, or submission status.

**Step 8 — Review and Approve a Work Submission**
- Tap any student entry to open the **Submission Review** screen.
- Read their work description and view uploaded proof.
- Tap **Approve Submission** or **Reject** (with reason).
- The student receives an in-app notification immediately.

**Step 9 — Send for Admin Approval**
- After approving a submission, tap **Mark for Admin Approval** to flag it for final admin review.
- Once admin approves, the student appears in the **Certificate Ready** tab automatically.

---

### Impact (Tab 4)

**Step 10 — Generate an Impact Draft**
- Tap the **Impact** tab → select a completed event → Tap **Generate Impact Draft**.

**Step 11 — Edit and Submit for Admin Approval**
- Review the auto-generated post → edit text if needed → Tap **Submit for Admin Approval**.

**Step 12 — Generate an Event Report**
- Tap **Generate Report** for any completed event.
- The report includes: total participants, hours contributed, work submitted, certificates issued, donation amounts.
- Tap **Finalize Report** to lock the report and close the event record.

---

## 5. Counsellor (Mentor)

### Flow Overview

```mermaid
flowchart TD
    LOGIN([Counsellor Login]) --> HOME[Home Tab\noverview · new requests · reminders]

    HOME --> REQ_TAB[Requests Tab]
    REQ_TAB --> TABS[New · Accepted · Rescheduled · All]
    TABS --> CARD[Request Card]
    CARD --> ACTION{Action on NEW requests only}
    ACTION -->|Single tap| ACCEPT[Status: Accepted\nReminders scheduled\nContact revealed]
    ACTION -->|Pick date/time| RESCHED[Status: Rescheduled\nSchool notified]
    ACTION -->|Select reason| DECLINE[Status: Declined\nSchool notified with reason]

    CARD --> DETAIL[Tap View Full Details\nfor non-new requests]
    DETAIL --> DET_ACT{Detail Screen Actions}
    DET_ACT -->|If NEW| ACCEPT2[Accept or Decline]
    DET_ACT -->|If SCHEDULED/CONFIRMED| COMPLETE[Mark Session as Completed]

    HOME --> SCHED[Schedule Tab\nauto-jumps to nearest session]
    SCHED --> WEEK[Week navigation\nleft / right arrows]
    SCHED --> DAY[Select day to view\nPending · Confirmed · Completed sessions]
    SCHED --> SLOT_ACT[Availability Slots\nBlock / Unblock]
    SCHED --> FAB[Tap Add Slot FAB\nset time · mode · repeat weekly]

    HOME --> SESS_TAB[Sessions Tab]
    SESS_TAB --> UPCOMING[Upcoming sub-tab\nall active sessions]
    SESS_TAB --> COMPLETED_TAB[Completed sub-tab\npast sessions · impact reports]

    HOME --> PROFILE[Profile Tab]
    PROFILE --> PUB_PROF[Update Public Profile\nbio · expertise · session topics · photo]

    style ACCEPT  fill:#2e7d32,color:#fff
    style RESCHED fill:#6a1b9a,color:#fff
    style DECLINE fill:#c62828,color:#fff
    style COMPLETE fill:#00695c,color:#fff
```

### Login

**Step 1 — Login**
- Enter your counsellor credentials → Tap **Sign In**.
- You are directed to the **Counsellor Dashboard**.

---

### Home (Tab 1)

**Step 2 — View Today's Overview**
- Home shows:
  - **Overview Cards** — today's scheduled sessions, new requests count, pending confirmation count, completed this month, average rating, total students guided.
  - **Today's Sessions** — sessions happening today (if any).
  - **New School Requests** — the latest pending requests from schools.
  - **Upcoming Reminders** — the next 3 time-based reminders (24h / 2h / 15min before sessions).
  - **Quick Actions** — shortcuts to Requests, Schedule, Sessions, and Profile.

**Step 3 — Respond to a New Request from Home**
- Tap any request card on the Home screen to open its **Meeting Detail Screen**.
- Use the action buttons at the bottom to Accept or Decline directly from the detail screen.

---

### Requests (Tab 2)

**Step 4 — View All School Requests**
- Tap the **Requests** tab → data is refreshed automatically on every visit.
- Four sub-tabs:
  - **New** — incoming requests awaiting your response (shows count badge).
  - **Accepted** — requests you accepted plus those in pending confirmation, confirmed, and scheduled states.
  - **Rescheduled** — requests where you suggested a new time and are awaiting school response.
  - **All** — complete history of every request.

**Step 5 — Open a Request Detail**
- Tap **View Full Details** on any non-new request card to open the **Meeting Detail Screen** with complete session information, school contact (if revealed), meeting link, reminders, and action buttons.

**Step 6 — Accept a Request**
- On a **New** request card, tap the green **Accept** button.
- The button immediately becomes inactive after one tap — re-tapping is not possible.
- The school receives a "Counsellor accepted" notification.
- Three automatic reminders are scheduled: 24 hours, 2 hours, and 15 minutes before the session.
- The school's coordinator contact details are revealed to you.

**Step 7 — Decline a Request**
- On a **New** request card, tap the red **Decline** button.
- A bottom sheet opens — select a reason from the list (Not available, Outside expertise, Location too far, Scheduling conflict, Other).
- Add an optional additional note.
- Tap **Decline** to confirm. The school is notified with your reason.
- You can also decline from the **Meeting Detail Screen** if viewing a New request.

**Step 8 — Reschedule a Request**
- On a **New** request card, tap the purple **Reschedule** button.
- A date picker appears — choose an alternative date → then a time picker → choose an alternative time.
- Tap **Done** to send the suggestion. The school receives a notification and can confirm or cancel.

---

### Schedule (Tab 3)

**Step 9 — View Your Session Calendar**
- Tap the **Schedule** tab.
- The calendar automatically refreshes and **jumps to the nearest date that has an upcoming session** — so accepted sessions are visible immediately without manual navigation.
- If today has sessions or availability slots, the calendar stays on today.

**Step 10 — Navigate Between Weeks**
- Use the **left (‹)** and **right (›)** chevron buttons to move between weeks.
- The week label at the top shows the date range (e.g., "29 Jun – 5 Jul 2026").
- Tap any day in the week strip to view that day's sessions and slots.
- Days with sessions show a **blue dot**; days with availability slots show a **green dot**.

**Step 11 — View Sessions on a Day**
- Selecting a day shows three sections:
  - **Pending Sessions** (orange icon) — accepted and pending-confirmation requests.
  - **Confirmed Sessions** (blue icon) — confirmed and scheduled sessions.
  - **Completed** (green icon) — past completed sessions.
- Tap any session card to open the **Meeting Detail Screen**.

**Step 12 — Add an Availability Slot**
- Tap the blue **+ Add Slot** floating button (bottom right).
- In the sheet that opens, set:
  - **Start Time** — pick using the time picker.
  - **End Time** — pick using the time picker.
  - **Session Mode** — Online, Offline, or Both.
  - **Repeat Weekly** — toggle on to repeat this slot every week on the same day.
- Tap **Save Slot** to publish the slot to your public calendar.

**Step 13 — Block or Unblock a Slot**
- Scroll to the **Availability Slots** section on the selected day.
- Each slot has a **Block** or **Unblock** button.
- Tap **Block** to mark yourself unavailable for that slot (it remains in your calendar but shows as blocked to schools).
- Tap **Unblock** to make it available again.

**Step 14 — View Repeating Slots**
- Scroll to the **Repeating Slots** section at the bottom.
- This lists all weekly-recurring slots with their day, time range, and mode.

---

### Sessions (Tab 4)

**Step 15 — View Upcoming Sessions**
- Tap the **Sessions** tab → **Upcoming** sub-tab.
- Shows all active sessions (accepted, pending confirmation, confirmed, scheduled) sorted by date ascending.
- Tap **Details** on any session card to open the Meeting Detail Screen.

**Step 16 — View Completed Sessions**
- Tap the **Completed** sub-tab to see all past sessions sorted by most recent first.
- Tap **Details** to view session information.
- Tap **Impact Report** (if available) to view the session impact data.

**Step 17 — Mark a Session as Completed**
- Open the **Meeting Detail Screen** for a session with status *Confirmed* or *Scheduled*.
- Scroll to the bottom → Tap the dark teal **Mark Session as Completed** button.
- The session status changes to *Completed* immediately.

**Step 18 — Submit a Session Report**
- After marking a session complete, tap **Submit Report** from the Session detail.
- Fill in:
  - Counsellor notes (what was covered, outcomes)
  - Number of students who attended
  - School feedback summary
  - Rating (1–5 stars)
- Tap **Submit Report** to save. The report is stored against the session record.

---

### Profile (Tab 5)

**Step 19 — Update Your Public Profile**
- Tap the **Profile** tab.
- Edit: profile photo, display name, designation, bio/service background, category, languages, expertise areas, years of experience, session mode (online/offline/both).
- Tap **Save Profile** to publish changes. Your updated profile is visible to school partners immediately.

---

## 6. Content Creator

### Flow Overview

```mermaid
flowchart TD
    LOGIN([Content Creator Login]) --> HOME[Home Tab\ncontent stats overview]

    HOME --> ANALYTICS[Analytics Tab\nviews · completion · status breakdown]

    HOME --> UPLOAD[Upload Tab]
    UPLOAD --> CREATE_COURSE[Create Free Course\ntitle · category · level]
    CREATE_COURSE --> ADD_LESSON[Add Lesson\nvideo · PDF · text]
    ADD_LESSON --> SUBMIT_REV[Submit for Admin Review]
    SUBMIT_REV --> PENDING[Status: Pending Review]
    PENDING --> ADM_DEC{Admin Decision}
    ADM_DEC -->|Approve| LIVE[Status: Published\nVisible to students]
    ADM_DEC -->|Reject| REJ_NOTE[Rejected with reason]
    REJ_NOTE --> ADD_LESSON

    UPLOAD --> PDF[Upload PDF Notes\ncourse · chapter · file]
    PDF --> SUBMIT_REV

    HOME --> CONTENT[Content Tab\nall courses · lessons · filter by status]
    HOME --> PROFILE[Profile Tab\nupdate display name · photo · stats]

    style PENDING fill:#f57f17,color:#fff
    style LIVE    fill:#2e7d32,color:#fff
    style REJ_NOTE fill:#c62828,color:#fff
```

### Login

**Step 1 — Login**
- Enter your Content Creator credentials → Tap **Sign In**.
- You are directed to the **Content Creator Dashboard**.

---

### Home (Tab 1)

**Step 2 — View Your Content Overview**
- Home shows: total content items uploaded, published items, pending review items, total views.

---

### Analytics (Tab 2)

**Step 3 — View Content Performance Analytics**
- Tap the **Analytics** tab → views per course and lesson, student engagement, completion rates, publication status breakdown.

---

### Upload (Tab 3)

**Step 4 — Create a New Free Course**
- Tap the **Upload** tab → Tap **Create Free Course**.
- Fill in: course title, description, skill category, thumbnail image, difficulty level → Tap **Create Course**.

**Step 5 — Add a Lesson to a Course**
- Tap **Add Lesson** → select which course this lesson belongs to.
- Fill in: lesson title, description, chapter/subject, upload video (mp4) or PDF notes, add text content.
- Tap **Submit for Review** → sent to admin for approval before going live.

**Step 6 — Upload PDF Notes Directly**
- Tap **Upload PDF Notes** → select course and chapter → upload PDF → add title and description → Tap **Submit**.

**Step 7 — Review Your Pending Submissions**
- Tap **Review Pending** → see all lessons and notes awaiting admin approval.
- Tap any item to view its current status: Pending, Approved, or Rejected.

---

### Content (Tab 4)

**Step 8 — Browse All Your Uploaded Content**
- Tap the **Content** tab → view all courses and lessons.
- Filter by status: All, Published, Pending Review, Draft.

---

### Profile (Tab 5)

**Step 9 — Update Your Creator Profile**
- Tap the **Profile** tab → update display name and profile photo → view content contribution statistics.

---

## 7. School Partner

### Flow Overview

```mermaid
flowchart TD
    REG([Register with\nRequested Role: School Partner]) --> PEND[Pending Admin Approval]
    PEND --> APPROVED[Account Approved]
    APPROVED --> PORTAL[School Partner Portal]

    PORTAL --> SERVICES[Service Cards\nBrowse Counsellors · Book Session · Profile]
    PORTAL --> REQUESTS[Recent Requests Section\nlast 5 requests with status]

    SERVICES --> BROWSE[Browse Counsellor Directory]
    BROWSE --> SEARCH[Search by name · expertise · category]
    BROWSE --> FILTER[Filter by mode · language · availability · featured]
    BROWSE --> PROFILE_VIEW[Open Counsellor Profile\nbio · stats · expertise · topics]
    PROFILE_VIEW --> BOOK[Tap Book a Counselling Session\nOR Request Awareness Camp]

    BOOK --> FORM[Fill Booking Form\nschool · topic · date · students · mode]
    FORM --> SUBMIT[Submit Request]
    SUBMIT --> STATUS_NEW[Status: New Request\nCounsellor & Admin notified]

    STATUS_NEW --> COUNSELLOR_RESP{Counsellor responds}
    COUNSELLOR_RESP -->|Accepts| STATUS_ACC[Status: Accepted\nContact details revealed]
    COUNSELLOR_RESP -->|Reschedules| STATUS_RESCH[Status: Rescheduled]
    COUNSELLOR_RESP -->|Declines| STATUS_DEC[Status: Declined\nReason shown]

    STATUS_RESCH --> SP_ACTION{School Partner}
    SP_ACTION -->|Confirm Time| STATUS_PEND[Status: Pending Confirmation]
    SP_ACTION -->|Cancel| STATUS_CANCEL[Status: Cancelled]

    STATUS_ACC --> STATUS_CONF[Status: Confirmed\nMeeting link visible]
    STATUS_CONF --> STATUS_DONE[Status: Completed]

    REQUESTS --> DETAIL[Tap any request → Detail Screen]
    DETAIL --> TIMELINE[View status timeline]
    DETAIL --> ACTIONS[Confirm Time / Cancel Request buttons]

    style STATUS_NEW   fill:#1565c0,color:#fff
    style STATUS_ACC   fill:#2e7d32,color:#fff
    style STATUS_RESCH fill:#6a1b9a,color:#fff
    style STATUS_DEC   fill:#c62828,color:#fff
    style STATUS_PEND  fill:#f57f17,color:#fff
    style STATUS_CONF  fill:#1b5e20,color:#fff
    style STATUS_DONE  fill:#00695c,color:#fff
    style STATUS_CANCEL fill:#546e7a,color:#fff
```

### Registration

**Step 1 — Register as a School Partner**
- Open the app → Tap **Register**.
- Select **School / Volunteer** as your access type.
- Fill in the registration form with your school and personal details.
- In the **Requested Role** dropdown, select **School Partner**.
- Submit and wait for Admin approval.

---

### Accessing the School Partner Portal

**Step 2 — Login After Approval**
- Enter your approved School Partner credentials → Tap **Sign In**.
- You are taken directly to the **School Partner Portal** screen.

---

### Portal Home Screen

**Step 3 — View the Portal Dashboard**
- The Portal home shows:
  - A **welcome banner** with the NGO trust and verification statement.
  - **School Services** cards:
    - **Verified Counsellor Panel** — tap to open the full counsellor directory.
    - **Book a Counselling Session** — tap to open the directory and start a booking.
    - **Profile & Account Settings** — tap to view and update your school partner profile.
  - A **Recent Requests** section showing your last 5 booking requests with current status badges.
- Tap any request card to open its full **Request Detail Screen**.

---

### Browsing the Counsellor Directory

**Step 4 — Open the Counsellor Directory**
- Tap **Verified Counsellor Panel** or **Book a Counselling Session** on the portal home.

**Step 5 — Search for a Counsellor**
- Use the **Search bar** to search by name, designation, or area of expertise.

**Step 6 — Filter the Directory**
- Tap filter chips to filter by:
  - **Category** — Retired Army Officer, Education Counsellor, Mental Wellness, Cyber Safety, etc.
  - **Session Mode** — Online, Offline, or Both
  - **Language** — English, Punjabi, Hindi, etc.
  - **Available This Week** — toggle to show only currently available counsellors
  - **Featured Only** — toggle to show only NGO-recommended counsellors

**Step 7 — Browse Featured Counsellors**
- Scroll down to the **Featured Counsellors** horizontal carousel.
- Tap any featured card to open their full profile.

**Step 8 — Open a Counsellor's Full Profile**
- Tap any counsellor card.
- The **Full Profile Screen** shows: name, photo, category badge, verified status, stats (sessions, students, experience), bio, designation, expertise tags, session topics, qualifications, session details, and privacy policy.

---

### Booking a Counselling Session

**Step 9 — Start a Booking Request**
- On the counsellor's profile screen, scroll to the bottom action buttons.
- Tap **Book a Counselling Session** for a regular session.
- OR tap **Request Awareness Camp** for a large-group program.

**Step 10 — Fill in the Booking Form**
- Complete all fields in the form sheet:
  - **School Name**, **Principal / Coordinator Name**, **School Email**
  - **Session Topic** — select from the counsellor's listed topics
  - **Preferred Date** — at least 3 days in advance
  - **Session Mode** — Online or Offline
  - **Expected Student Count**, **Grade / Class Group**, **Special Requirements**
- Tap **Submit Booking Request**.

**Step 11 — Request Submitted**
- A green success notification appears.
- Both the counsellor and NGO Admin receive in-app notifications of the new request.

---

### After Submitting a Request

**Step 12 — Track Request Status**
- Return to the **School Partner Portal** home screen.
- Tap any request card (or tap a notification) to open the full **Request Detail Screen** showing:
  - **Status Banner** — current status with a plain-language explanation of what it means.
  - **Request Details** — topic, counsellor, school, coordinator contact (revealed once accepted), grade, students, mode, requirements.
  - **Preferred Schedule** card — the date and time you originally requested.
  - **Rescheduled Suggestion** card — appears if the counsellor suggested a new time.
  - **Meeting Link** card — visible once the session is confirmed/scheduled (online sessions only).
  - **Timeline** — key events with timestamps (submitted, accepted, confirmed, completed).
  - **Action Buttons** — conditionally shown based on status (see below).

**Step 13 — Receive Status Notifications**
- When the counsellor accepts, declines, or suggests a new time, you receive an in-app notification.
- Tap the notification to go directly to your request detail.

**Step 14 — Confirm or Cancel a Rescheduled Time**
- If the counsellor suggested a new time, open the request detail.
- Review the suggested date and time in the **Rescheduled Suggestion** card.
- Tap **Confirm New Time** to accept it → status moves to **Pending Confirmation**.
- Tap **Cancel Request** to cancel entirely → status moves to **Cancelled**.

---

## General Notes for All Roles

### In-App Notifications

```mermaid
flowchart LR
    TRIGGER([Action Occurs]) --> NOTIFY[Backend sends notification]
    NOTIFY --> BELL[Bell icon shows badge count]
    BELL --> USER[User taps bell → views notification list]
    USER --> NAV[Taps notification → navigates to relevant screen]
```

- All users receive real-time in-app notifications for actions relevant to their role.
- Tap the **Bell** icon in your profile screen to view all past notifications.
- Unread notifications show a badge count on the icon.

---

### Sign Out
- Go to your **Profile** tab → Tap **Sign Out** at the bottom.
- You are returned to the Login screen.

---

### Password Reset
- On the Login screen, tap **Forgot Password?**
- Enter your registered email address.
- Check your email for a reset link and follow the instructions to set a new password.

---

### Role Upgrade Requests
- A registered user can request a role change (e.g., from Student to Volunteer) during registration by selecting their desired role in the **Requested Role** field.
- The admin reviews and approves or rejects role change requests from the Users management screen.
