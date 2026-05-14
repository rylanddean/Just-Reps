Brand Identity & Application Implementation Guide

“Just Reps”

⸻

1. Brand Foundation

App Name

Just Reps

Simple. Focused. Memorable.

The name communicates:

* low friction
* daily consistency
* minimalism
* “just do the reps”

It fits perfectly beside apps like:

* BeReal
* Offsuit
* Headspace
* JustWatch

⸻

2. Brand Positioning

Core Idea

A minimalist fitness streak app focused on consistency over perfection.

Not:

* bodybuilding
* influencer culture
* calorie obsession
* complex workout plans

Instead:

* daily movement
* tiny wins
* sustainable habits
* discipline through simplicity

⸻

3. Brand Personality

Trait	Description
Minimal	No clutter
Honest	No fake hype
Calm	Encouraging, not aggressive
Disciplined	Focused on routine
Modern	Clean Apple-like UX
Slightly Playful	Tiny bits of humor

⸻

4. Target Audience

Primary

* Ages 13–35
* People trying to build habits
* Students
* Busy parents
* Office workers
* Gamers/developers
* “I need to start exercising” users

Secondary

* Athletes using it as a streak tracker
* Fitness beginners intimidated by gym apps

⸻

5. Core Product Philosophy

Rule #1

The app should never feel overwhelming.

Rule #2

Opening the app should take less mental energy than skipping the workout.

Rule #3

One completed rep session should feel rewarding.

⸻

6. Visual Identity

Color Palette

Primary

* Pure Black: #000000
* Off White: #F7F7F5

Accent Colors

* Success Green: #5FD38D
* Soft Red (streak danger): #FF6B6B
* Cool Blue: #6BA8FF

Optional Dark Theme Background

* #111111

⸻

7. Typography

Primary Font

SF Pro Display

(iOS-native aesthetic)

Alternative:

* Inter

⸻

8. Logo Concepts

Option A — Minimal Wordmark

JUST REPS

with:

* wide spacing
* bold weight
* lowercase variant:
    just reps

⸻

Option B — JR Monogram

Stylized:

* J becomes a checkmark
* R formed from a curved rep counter line

⸻

Option C — Streak Icon

A vertical line stack:

|||||||||

Representing consecutive days.

⸻

9. App Store Positioning

App Store Subtitle

“Build your daily workout streak.”

Alternative:

* “Tiny workouts. Real consistency.”
* “Never miss your reps.”
* “One workout. Every day.”

⸻

10. Taglines

Core Tagline

“Show up daily.”

Other options:

* “Don’t break the chain.”
* “Small reps. Big results.”
* “Consistency wins.”
* “One set is enough.”
* “Built daily.”

⸻

11. Core Features (V1)

Daily Rep Logging

Users complete:

* pushups
* squats
* optional custom exercises

⸻

Streak Tracking

Core mechanic:

* streak count
* longest streak
* calendar visualization

⸻

Daily Goal System

Examples:

* 25 pushups
* 50 squats
* 1 minute plank

⸻

“Minimum Mode”

Encourages tiny effort:

“Even 5 reps keeps the streak alive.”

This is psychologically huge.

⸻

Anti-Doomscroll Philosophy

After workout completion:

* app gently encourages leaving

Example:

“Nice work. Now go live your life.”

⸻

12. Core UX Principles

Fast Open

App should launch directly into:
TODAY’S REPS

No dashboards first.

⸻

One-Tap Completion

Example:
[ +10 Pushups ]

Not:

* lengthy forms
* editing menus
* friction

⸻

Celebrations Should Be Subtle

Avoid:

* casino animations
* loud confetti

Use:

* soft haptics
* number ticking upward
* clean transitions

⸻

13. Main Screens

Home Screen

Displays:

* current streak
* today’s reps
* quick-add buttons
* completion progress

⸻

Streak Screen

* heatmap calendar
* longest streak
* monthly consistency %

Inspired by:
GitHub contribution graph.

⸻

History Screen

Timeline:

* “50 pushups”
* “100 squats”
* timestamps

⸻

Settings

Minimal:

* notifications
* dark mode
* exercise customization

⸻

14. Gamification Strategy

DO:

* streaks
* milestones
* subtle achievements
* progression

DON’T:

* loot boxes
* fake currencies
* manipulative timers

⸻

15. Achievement Ideas

* First Week
* 30 Days
* 1000 Pushups
* Never Missed Monday
* Consistency > Motivation
* Tiny Gains

⸻

16. Notification Philosophy

Should feel like:
a disciplined friend.

NOT:
an annoying coach.

Examples:

* “Quick set?”
* “Keep the streak alive.”
* “5 reps still counts.”
* “Today’s a good day to show up.”

⸻

17. Monetization Strategy

Best Option

Freemium.

Free

* streak tracking
* core exercises
* history

Premium

* advanced analytics
* widgets
* custom themes
* Apple Watch support
* social accountability
* AI workout adaptation

⸻

18. Technical Stack Recommendation

iOS First

SwiftUI

Reasons:

* fastest iteration
* beautiful animations
* native feel
* excellent typography

⸻

Backend

Firebase

Use for:

* auth
* sync
* streak persistence
* analytics
* notifications

⸻

19. Recommended Architecture

Frontend

SwiftUI + MVVM

Core Modules

* Auth
* Workout
* Streak Engine
* Notifications
* Analytics

⸻

20. Data Model

Workout Entry

struct WorkoutEntry {
    let id: UUID
    let exercise: ExerciseType
    let reps: Int
    let timestamp: Date
}

⸻

Streak Model

struct Streak {
    let current: Int
    let longest: Int
    let lastCompletedDate: Date
}

⸻

21. Streak Logic

Key Rule

One completed workout per calendar day maintains streak.

Pseudo:

if completedToday {
    streak += 1
}

Grace window:

* optional 3AM rollover

⸻

22. Suggested Folder Structure

/App
    /Views
    /Components
    /Models
    /Services
    /Managers
    /Utilities
    /Themes

⸻

23. UI Component Ideas

Rep Button

Large pill-shaped buttons:
+10 Pushups

Use:

* haptics
* smooth scaling animation

⸻

Streak Counter

Large typography:

127 DAYS

Feels meaningful.

⸻

24. Future Features

V2

* Apple Watch app
* widgets
* friend streaks
* challenges

V3

* AI adaptive goals
* posture detection
* camera rep counting

⸻

25. Competitive Advantage

Most fitness apps:

* overwhelm users
* feel like work
* require planning

Just Reps:

* feels achievable
* removes excuses
* rewards consistency

⸻

26. Launch Strategy

TikTok/Reels Content

Examples:

* “POV: your only goal is 5 pushups.”
* “This app helped me exercise daily.”
* streak heatmap transformations

⸻

Reddit Communities

Use:

* r/selfimprovement
* r/getdisciplined
* r/bodyweightfitness

(avoid spammy marketing)

⸻

27. MVP Scope (Very Important)

MUST HAVE

* streaks
* quick logging
* notifications
* history
* persistence

DO NOT BUILD YET

* social feed
* messaging
* complicated workouts
* calorie tracking
* macro systems

⸻

28. Final Product Vision

The app becomes:

the easiest possible way to build lifelong exercise consistency.

Not a gym app.

A discipline app.

⸻

29. Ideal Emotional Outcome

When users open the app, they should think:

“I can at least do a few reps.”

That feeling is the product.