# Just Reps — Style Guide & Implementation Tracker

> A minimalist fitness streak app. Not a gym app. A discipline app.

---

## Design System

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `colorBlack` | `#000000` | Primary text, backgrounds (dark) |
| `colorOffWhite` | `#F7F7F5` | Background (light) |
| `colorSuccessGreen` | `#5FD38D` | Streak active, goal complete, positive feedback |
| `colorStreakDanger` | `#FF6B6B` | Streak at risk, 0-day warning |
| `colorCoolBlue` | `#6BA8FF` | Secondary actions, cool accents |
| `colorDarkBackground` | `#111111` | Dark mode background |

### Typography

**Font:** SF Pro Display (system default — use `.rounded` design where available)

| Style | Weight | Size | Usage |
|---|---|---|---|
| Display | Heavy | 64pt | Streak count |
| Title | Bold | 32pt | Screen headings |
| Headline | Semibold | 18pt | Section labels, card titles |
| Body | Regular | 16pt | List items, descriptions |
| Caption | Regular | 13pt | Timestamps, metadata |

### Spacing

| Token | Value |
|---|---|
| `spacingXS` | 4pt |
| `spacingSM` | 8pt |
| `spacingMD` | 16pt |
| `spacingLG` | 24pt |
| `spacingXL` | 40pt |
| `spacingXXL` | 64pt |

### Corner Radii

| Token | Value |
|---|---|
| `radiusPill` | 999pt (full pill) |
| `radiusCard` | 16pt |
| `radiusSmall` | 8pt |

### Haptics

| Event | Feedback Type |
|---|---|
| Rep logged | `.soft` (UIImpactFeedbackGenerator) |
| Goal completed | `.medium` |
| Streak milestone | `.heavy` |
| Destructive action | `.warning` |

---

## Component Library

### RepButton
- Large pill-shaped tap target (min height 64pt)
- Shows exercise name and +N increment
- Scales down on press (scaleEffect 0.96)
- Triggers `.soft` haptic on tap
- Background: `colorBlack` / text: `colorOffWhite`

### StreakCounter
- Full-width display — large bold number
- Subtitle: "DAY STREAK" in caption weight with letter spacing
- Animates number with `.contentTransition(.numericText())`
- Color: green when active, red when 0

### ProgressRing
- Circular progress indicator for daily goal
- Stroke width: 8pt, color: `colorSuccessGreen`
- Background ring: 20% opacity

### HeatmapCalendar
- GitHub-style contribution grid
- 7 columns × N rows (weeks)
- Cell size: 10×10pt, gap: 2pt
- 4 intensity levels: empty → light green → medium green → `colorSuccessGreen`

### ExerciseCard
- Rounded card (radiusCard)
- Shows exercise name, today's reps, goal progress bar
- Subtle shadow: 0.05 opacity, 4pt blur

---

## Architecture

```
JustReps/
├── JustRepsApp.swift          # App entry point, @main
├── Models/
│   ├── WorkoutEntry.swift     # SwiftData model
│   ├── ExerciseType.swift     # Enum + custom exercises
│   └── Achievement.swift      # Achievement definitions
├── ViewModels/
│   ├── HomeViewModel.swift    # Today's reps, goals, streak
│   ├── StreakViewModel.swift  # Heatmap data, stats
│   └── HistoryViewModel.swift # Timeline entries
├── Views/
│   ├── HomeView.swift         # Main landing screen
│   ├── StreakView.swift       # Heatmap + stats
│   ├── HistoryView.swift      # Workout timeline
│   └── SettingsView.swift     # Notifications, dark mode, exercises
├── Components/
│   ├── RepButton.swift        # +N tap button
│   ├── StreakCounter.swift    # Large streak display
│   ├── ProgressRing.swift     # Circular goal progress
│   └── HeatmapCalendar.swift  # Calendar heatmap grid
├── Services/
│   ├── StreakEngine.swift     # Streak calculation logic
│   └── NotificationManager.swift # Local notifications
└── Themes/
    └── AppTheme.swift         # Color/spacing constants
```

### Data Persistence
SwiftData (iOS 17+) — local-first. Firebase sync is a V2 feature.

### Navigation
`TabView` with 3 tabs: Home, Streak, History. Settings via sheet from Home.

---

## Screens

### Home Screen (`HomeView`)
- Streak counter at top
- Progress ring + today's total reps
- Exercise cards (pushups, squats, custom)
- Rep buttons (+5, +10, +25) per exercise
- Completion banner: "Nice work. Now go live your life."

### Streak Screen (`StreakView`)
- Heatmap calendar (full width)
- Stat row: Current Streak / Longest Streak / This Month %
- Achievement badges

### History Screen (`HistoryView`)
- Grouped timeline by day
- Each entry: exercise name, rep count, time

### Settings (`SettingsView`)
- Notification toggle + time picker
- Dark mode toggle
- Exercise customization (add/remove/reorder)
- Daily goal per exercise

---

## Implementation Progress

### Foundation
- [ ] Xcode project created (SwiftUI, iOS 17+, SwiftData)
- [x] Folder structure — `JustReps/{Themes,Models,Services,ViewModels,Components,Views}`
- [x] [`AppTheme.swift`](JustReps/Themes/AppTheme.swift) — colors, spacing, typography, hex Color init
- [x] [`ExerciseType.swift`](JustReps/Models/ExerciseType.swift) — enum with built-ins + `.custom(name:)`
- [x] [`WorkoutEntry.swift`](JustReps/Models/WorkoutEntry.swift) — SwiftData `@Model`, predicate helpers
- [x] [`Achievement.swift`](JustReps/Models/Achievement.swift) — 7 achievements with typed conditions

### Services
- [x] [`StreakEngine.swift`](JustReps/Services/StreakEngine.swift) — streak calc, 3AM grace window, heatmap data, monthly %
- [x] [`NotificationManager.swift`](JustReps/Services/NotificationManager.swift) — permission, daily schedule, cancel

### ViewModels
- [x] [`HomeViewModel.swift`](JustReps/ViewModels/HomeViewModel.swift) — today's reps, goals, progress, completion banner
- [x] [`StreakViewModel.swift`](JustReps/ViewModels/StreakViewModel.swift) — streak stats, heatmap, earned achievements
- [x] [`HistoryViewModel.swift`](JustReps/ViewModels/HistoryViewModel.swift) — grouped timeline, all-time totals

### Components
- [x] [`RepButton.swift`](JustReps/Components/RepButton.swift) — pill button with haptic + scale animation
- [x] [`StreakCounter.swift`](JustReps/Components/StreakCounter.swift) — large display with numericText transition
- [x] [`ProgressRing.swift`](JustReps/Components/ProgressRing.swift) — circular ring + horizontal bar variant
- [x] [`HeatmapCalendar.swift`](JustReps/Components/HeatmapCalendar.swift) — GitHub-style contribution grid

### Views
- [x] [`HomeView.swift`](JustReps/Views/HomeView.swift) — streak counter, progress ring, exercise cards, completion banner
- [x] [`StreakView.swift`](JustReps/Views/StreakView.swift) — stats row, heatmap, achievement badges
- [x] [`HistoryView.swift`](JustReps/Views/HistoryView.swift) — grouped timeline, empty state
- [x] [`SettingsView.swift`](JustReps/Views/SettingsView.swift) — notifications, dark mode, exercises, goals
- [x] [`ContentView.swift`](JustReps/Views/ContentView.swift) — TabView (Today / Streak / History)
- [x] [`JustRepsApp.swift`](JustReps/JustRepsApp.swift) — `@main`, SwiftData `modelContainer`

### Polish (Next Steps)
- [ ] Xcode project file (`.xcodeproj`) — create in Xcode: File → New → Project → iOS App
- [ ] Add all Swift files to the Xcode project target
- [x] [`OnboardingView.swift`](JustReps/Views/OnboardingView.swift) — welcome page + exercise picker (pushups/squats only)
- [x] `@Query` in all three views — tabs now auto-refresh when reps are logged
- [x] `SettingsView` — simplified to pushups/squats toggles + goals + notifications
- [x] `DayState` enum in `HomeViewModel` — fresh / alive / complete
- [x] `streakAtRisk` — detects streak danger after 8PM with no reps logged
- [x] Dynamic home screen message — changes per state ("Show up. Even 5 reps counts." / "Streak alive. Keep going." / at-risk warning)
- [x] `StreakCounter` — shows danger color when `atRisk`
- [x] [`ExerciseRing.swift`](JustReps/Components/ExerciseRing.swift) — `DragGesture` for consistent press feedback; `…` opens `CustomRepEntry` sheet
- [x] `HomeView` ring grid — 2-column `LazyVGrid` of `ExerciseRing`, replaces exercise cards
- [x] `HomeViewModel` — goals + active exercises persisted to `UserDefaults`; survive app restarts
- [x] `SettingsView` — cleaned up dead code; notification time picker initialises from saved values
- [x] `HeatmapCalendar` — month labels row + day-of-week labels beside grid
- [x] `HistoryViewModel` — removed orphaned code fragment (compile error)
- [x] Custom rep entry — `CustomRepEntry` sheet with number pad, via `…` on each ring
- [x] App icon (added by user)
- [ ] Dark mode tested end-to-end on device
- [ ] Push notifications tested on physical device (won't fire in Simulator)

### V2 Backlog
- [ ] iCloud sync
- [ ] Apple Watch companion app
- [ ] Home screen widget
- [ ] Friend streaks / challenges
- [ ] AI adaptive goals
