# Smart Aid UI/UX Design System (V1 Edition)

**Official Implementation:** `mobile/lib/core/theme/app_theme.dart` & `mobile/lib/shared/widgets/`  
**Standard:** Material 3 Healthcare & Emergency Coordination Standard  
**Accessibility:** WCAG 2.1 Level AA/AAA compliant color contrast, scalable typography, screen-reader semantics, 52px+ touch targets, dual-language RTL/LTR layout.

---

## 1. Visual Language & Color Palette

The Smart Aid palette communicates clinical authority, rapid emergency clarity, and calming reliability:

| Color Token | Hex Code | Semantic Role & Usage |
| :--- | :--- | :--- |
| **Navy Blue** (`AppTheme.navyBlue`) | `#0A192F` | Primary text, deep headers, top app bars, brand authority. |
| **Emergency Red** (`AppTheme.emergencyRed`) | `#D32F2F` | Critical SOS actions, severe triage alerts (`P1_CRITICAL`), stop commands. Used purposefully to prevent visual fatigue. |
| **Primary Blue** (`AppTheme.blue`) | `#1769AA` | Navigation accents, active tab indicators, links, info chips. |
| **Sky Surface** (`AppTheme.sky`) | `#EAF5FF` | Informational callout containers, subtle banner backgrounds. |
| **Success Green** (`AppTheme.success`) | `#12B76A` | Available units, completed tasks, verified status pills, passing quizzes. |
| **Warning Amber** (`AppTheme.warning`) | `#F79009` | In-progress incidents, en route units, medium triage priority (`P2_URGENT`). |
| **Background Neutral** (`AppTheme.background`) | `#F8FAFC` | Calm off-white application canvas. |
| **Card Surface** (`AppTheme.cardSurface`) | `#FFFFFF` | Elevated cards with `#DDE5EF` hairline border and subtle 8px blur shadow. |

---

## 2. Typography & Spatial System

- **Scale:**
  - Display: 32px / Bold (Hero stats, emergency confirmations)
  - Heading 1: 28px / SemiBold (Page titles)
  - Title: 20–22px / Medium (Card headers, modal titles)
  - Section Title: 16–18px / SemiBold (Section divides, group headers)
  - Body: 14–16px / Regular (Content, incident descriptions)
  - Caption / Small: 12–13px / Regular (Timestamps, metadata coordinates)
- **Grid & Spacing Scale:** Multiples of 4 and 8: `4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `32px`.
- **Responsive Frame:** `QaPageFrame` centers content with a maximum reading width of 720px on tablets/desktops and fluid padding on mobile viewports.

---

## 3. Signature V1 Interactive Components

### 3.1 Pulsing SOS Button (`PulsingSosButton`)
- **Visual Design:** Centered circular core with a tactile radial red gradient (`#E53935` to `#B71C1C`) and an emergency shield emblem.
- **Dual Concentric Radar Rings:** Two continuous expanding breathing waves animated via `SingleTickerProviderStateMixin`, giving visual vitality to the emergency screen.
- **Micro-Interactions:** Subtle scale depression on tap (`0.95` downscale) and tactile feedback.
- **Accessibility:** Labeled with explicit `Semantics` tags (`label: "Emergency SOS"`, `hint: "Double tap to initiate emergency dispatch"`).

### 3.2 Quick Role & Demo Persona Switcher (`QuickRoleSwitcher`)
- **Visual Design:** Modern iOS/Material 3 style bottom modal sheet with rounded 24px top corners, draggable handle pill, and clean user-persona tiles.
- **Personas Offered:**
  - Citizen (Reporter) — `demo.user@smartaid.local`
  - Field Volunteer — `demo.volunteer@smartaid.local`
  - EMS Dispatcher — `demo.ems@smartaid.local`
  - System Administrator — `demo.admin@smartaid.local`
- **Features:** One-tap login switching with loading spinners and error fallbacks. Present in the AppBar of every dashboard and in Settings.

### 3.3 Onboarding & Splash Experience
- **Splash Screen:** Smooth animated branding mark with subtle subtitle transitions and direct session-aware routing.
- **Onboarding Carousel (`OnboardingPage`):** 3 visual slides covering (1) One-tap SOS, (2) Smart ER Multi-Factor Guidance, (3) Encrypted Medical Profiles. Includes explicit GPS and Notification permission rationale, skip action, and persisted completion flag.

### 3.4 Smart ER Decision Support & Destination Action Card
- **Hero Recommendation:** Displays the highest-scoring candidate hospital with transparent score breakdown (Travel Time, Capability, Specialty Match, Congestion).
- **Interactive Dispatch Action:** Prominent **"Confirm Destination & Dispatch"** button immediately updates incident status to `HOSPITAL_SELECTED` via server API.
- **Alternative Comparison List:** Secondary hospitals display individual score progress bars (`QaScoreBar`) and manual **"Select Hospital"** override buttons.

### 3.5 Fleet & Resource Explorer
- **Segmented Control:** 3-state segmented switcher between **Hospitals**, **AED Devices**, and **Ambulances**.
- **Live Fleet Telemetry:** Shows ambulance call signs, availability badges (`AVAILABLE`, `DISPATCHED`, `EN_ROUTE`), and location coordinates.

---

## 4. Accessibility & Dual-Language Standards

1. **Bilingual RTL/LTR:** Complete string mappings in English and Arabic (`AppLocalizations`). Arabic layouts automatically mirror navigation controls, card paddings, and alignment via Flutter's `Directionality` system.
2. **Accessible Form Controls:** All inputs in `login_page.dart`, `register_page.dart`, `medical_profile_page.dart`, and `emergency_contacts_page.dart` include high-contrast helper texts, clear field labels, and password visibility toggles.
3. **No Color-Only State Indicators:** All status badges (`StatusPill`) combine semantic color with explicit descriptive text (e.g., Green + "AVAILABLE", Amber + "EN ROUTE", Red + "CRITICAL").
