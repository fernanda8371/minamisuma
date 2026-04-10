# MinamisumaCapitalOne

A senior-focused iOS banking app built for the Capital One hackathon. Designed to protect elderly users from financial scams and unusual account activity, while giving caregivers visibility and control — always with the senior's consent.

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 26.2+) |
| Data persistence | SwiftData |
| Backend | Supabase (Postgres + Realtime) |
| SMS filtering | ILMessageFilterExtension |
| Extension ↔ App communication | App Groups (shared UserDefaults) |
| Testing | Swift Testing framework (`@Test`) |
| Language | Swift 6 |

No external package managers — dependencies are managed via Swift Package Manager directly in Xcode.

## Key Features

### Safety Mode (Modo de Apoyo)
A consent-based protection layer the senior controls. When activated:
- Sets configurable transfer and daily withdrawal limits
- Requires approval for large transactions
- Notifies a trusted family contact of account activity
- Caregivers can *request* activation, but the senior must explicitly approve it

### Caregiver Dashboard
A dedicated role for family members or caregivers:
- Real-time view of the senior's transaction history (only when Safety Mode is active)
- Behavior event timeline — flags unusual patterns like rapid successive withdrawals or large unexpected purchases
- Request/deactivate Safety Mode with a single tap

### ScamProtect
SMS and message filtering using Apple's `ILMessageFilterExtension`:
- Intercepts suspicious messages from unknown senders
- Classifies threats by category with a confidence score (Alto / Medio / Bajo)
- Syncs flagged messages to Supabase for review
- Results surface in-app under "Movimientos sospechosos"

### Senior-Friendly UX
Built with accessibility as a first-class requirement:
- Large touch targets and font sizes throughout
- Simplified home screen — all key actions visible without scrolling
- Voice guide feature for audio-assisted navigation
- Spanish-language UI (targeting Spanish-speaking seniors)

### Role Selection
On first launch, users pick their role — **Senior** or **Caregiver** — which determines the app experience. Role is persisted and can be changed from settings.

### Trusted Contacts (Familia)
Manage a list of trusted family contacts who can be notified or granted caregiver access.

## Project Structure

```
MinamisumaCapitalOne/
├── Models/           # SwiftData @Model classes
├── Views/            # SwiftUI view files
├── Controlers/       # Controller logic (SafetyModeController, TrustedContactController)
├── Helpers/          # Shared utilities (SupabaseManager, SeniorCardStyle)
├── Services/         # SupabaseService for remote sync
├── Config/           # SupabaseConfig
├── ContentView.swift
└── MinamisumaCapitalOneApp.swift  # App entry point + ModelContainer setup

ScamFilterExtension/  # ILMessageFilterExtension target
Shared/               # Code shared between app and extension via App Groups
```

## Build & Run

Open `MinamisumaCapitalOne.xcodeproj` in Xcode and run on an iPhone 16 simulator or device (iOS 26.2+).

```bash
xcodebuild -project MinamisumaCapitalOne.xcodeproj \
  -scheme MinamisumaCapitalOne \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

## Development
Claude Code helped us ship features faster by handling boilerplate, suggesting SwiftUI patterns, debugging data flow, and keeping code consistent across multiple contributors.
