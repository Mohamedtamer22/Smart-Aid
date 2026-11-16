# Smart Aid — Science Fair Display Board Layout Template

**Project Title:** Smart Aid — AI-Powered Emergency Medical Response Platform  
**Team Name:** FirstLine  
**Local Category:** Software Systems (SOFT)  
**Board Dimensions:** 140 cm (width) × 120 cm (height) — verify with your local organizer  
**Last Updated:** 2026-11-16  

> **IMPORTANT:** Adjust dimensions, font sizes, and section proportions to match your local fair's official display board rules before printing.

---

## Board Layout — Recommended Grid (140 cm × 120 cm)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           HEADER BANNER (Full Width, ~15 cm tall)                   │
│                                                                                     │
│   SMART AID — AI-Powered Emergency Medical Response Platform                        │
│   Team: FirstLine  |  Category: Software Systems (SOFT)  |  Year: 2026             │
└─────────────────────────────────────────────────────────────────────────────────────┘
│                                                                                     │
│  ┌─────────────────┐  ┌──────────────────────────────┐  ┌──────────────────────┐  │
│  │  LEFT COLUMN    │  │       CENTER COLUMN           │  │   RIGHT COLUMN       │  │
│  │  (~42 cm wide)  │  │       (~50 cm wide)           │  │   (~40 cm wide)      │  │
│  │                 │  │                               │  │                      │  │
│  │ [1] BACKGROUND  │  │ [4] RESULTS & FINDINGS        │  │ [7] FUTURE PLAN      │  │
│  │ & MOTIVATION    │  │                               │  │                      │  │
│  │                 │  │  Smart ER Algorithm Results:  │  │  Smart Fall &        │  │
│  │ Emergency resp. │  │  • Smart Aid Score: 88.6/100  │  │  Accident Detection  │  │
│  │ delays, lack of │  │  • Nearest-Only:   54.2/100  │  │  (Planned – not      │  │
│  │ coordination in │  │  • Random:         48.7/100  │  │   yet implemented)   │  │
│  │ medical crisis  │  │                               │  │                      │  │
│  │                 │  │  Test Suite Results:          │  │  Wearable sensor     │  │
│  │                 │  │  • Backend: 20/20 PASS        │  │  integration         │  │
│  │                 │  │  • Mobile:  54/54 PASS        │  │  Auto-alert trigger  │  │
│  │                 │  │  • E2E:     14/14 PASS        │  │                      │  │
│  │ [2] RESEARCH    │  │                               │  │ [8] CONCLUSIONS      │  │
│  │ QUESTION        │  │ [5] SYSTEM ARCHITECTURE       │  │                      │  │
│  │                 │  │       DIAGRAM                 │  │  Smart ER approach   │  │
│  │ Does multi-     │  │                               │  │  significantly       │  │
│  │ factor hospital │  │  [Architecture Mermaid or     │  │  outperforms         │  │
│  │ selection       │  │   Printed Diagram Image]      │  │  nearest-only and    │  │
│  │ outperform      │  │                               │  │  random selection    │  │
│  │ nearest-only    │  │   Patient → SOS → Triage      │  │  under defined       │  │
│  │ selection?      │  │   → Dispatch → ECC            │  │  scenario parameters │  │
│  │                 │  │   → Hospital Recommendation   │  │                      │  │
│  │                 │  │                               │  │ [9] ACKNOWLEDGMENTS  │  │
│  │ [3] METHODOLOGY │  │ [6] APP SCREENSHOTS           │  │                      │  │
│  │                 │  │                               │  │  Adult Sponsor:      │  │
│  │ 3-way algorithm │  │  [3–4 key app screenshots     │  │  _________________   │  │
│  │ comparison:     │  │   printed and mounted]        │  │                      │  │
│  │ Smart / Nearest │  │   • SOS Screen                │  │  School/Institution: │  │
│  │ / Random        │  │   • ECC Dashboard             │  │  _________________   │  │
│  │                 │  │   • Hospital Rec. Screen      │  │                      │  │
│  │ 50 weighted     │  │   • Triage Interface          │  │                      │  │
│  │ scenario runs   │  │                               │  │                      │  │
│  └─────────────────┘  └──────────────────────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Section Content Guides

### [1] Background & Motivation (~25 cm tall)
- State the problem: emergency response coordination failures, hospital selection errors
- Cite 1–2 real statistics about EMS response times or dispatch inefficiency (cite sources)
- Keep to 3–4 bullet points or short sentences
- Font size: **18–22 pt** body, **24 pt** header

### [2] Research Question (~15 cm tall)
- State the research question verbatim:
  > *"Does Smart Aid's multi-factor hospital recommendation algorithm select a significantly more suitable hospital than nearest-hospital-only or random selection under controlled scenario conditions?"*
- Bold the question; keep surrounding text minimal

### [3] Methodology (~25 cm tall)
- 3-way comparison: Smart ER vs. Nearest-Hospital vs. Random
- 50 weighted simulated scenario runs
- Pre-filter criteria: verified=true, specialty match, resources available
- Scoring formula: `0.30×Travel + 0.30×Capability + 0.25×Specialty + 0.15×Congestion`
- Display as a simple table or flowchart

### [4] Results & Findings (~30 cm tall)
- Results bar chart (hand-drawn or printed):

| Strategy | Mean Score | Rank |
|---|---|---|
| Smart ER (Smart Aid) | **88.6 / 100** | 🥇 1st |
| Nearest Hospital | 54.2 / 100 | 🥈 2nd |
| Random Selection | 48.7 / 100 | 🥉 3rd |

- Note: Scores from simulated scenarios using weighted parameters; not from clinical patient outcomes
- Include test counts: 20/20 backend + 54/54 mobile + 14/14 E2E

### [5] System Architecture Diagram (~35 cm tall)
- Print the system architecture Mermaid diagram from `System_Architecture_Audit.md`
- Show: Patient App → SOS Intake → Triage Engine → Dispatch → ECC → Hospital Recommendation
- Annotate the Smart ER module clearly

### [6] App Screenshots (~30 cm tall)
- Print 3–4 key screenshots:
  1. **SOS Intake screen** — pulsing SOS button
  2. **ECC Dashboard** — incident queue with STOMP WebSocket updates
  3. **Hospital Recommendation** — Smart ER score display
  4. **Triage Interface** — symptom assessment
- Label each screenshot with the feature name and test status (e.g., "VERIFIED — E2E Stage 10")

### [7] Future Plan (~20 cm tall)
- **Smart Fall & Accident Detection** only (do not list unimplemented V1 features here)
- Keep concise: wearable sensor integration, auto-fall detection, automatic SOS trigger
- Mark explicitly: *"Planned Future Development — Not Yet Implemented in V1"*

### [8] Conclusions (~20 cm tall)
- 3–4 bullet conclusion statements aligned to research question
- Example:
  - Smart ER algorithm scored 88.6/100 vs. 54.2 (nearest) under controlled simulation
  - Multi-factor approach is more suitable than proximity-only selection
  - System is functional, tested, and open-source ready
  - Future work: offline sync, multi-volunteer coordination, fall detection

### [9] Acknowledgments (~10 cm tall)
- Adult Sponsor name and institution (fill in manually)
- School/institution name
- Any datasets or tools credited (PostGIS, OpenStreetMap if used, etc.)

---

## Typography & Design Rules

| Element | Recommended Size | Style |
|---|---|---|
| Board Header / Title | 48–60 pt | Bold, high-contrast (white on dark, or dark on white) |
| Section Headers | 28–32 pt | Bold |
| Body Text | 18–22 pt | Regular, sans-serif (Arial, Roboto, Open Sans) |
| Data / Table Content | 16–18 pt | Regular |
| Caption / Label Text | 14–16 pt | Italic or regular |
| Footnotes / Sources | 12–14 pt | Regular |

**Color Palette (match the app/slides):**

| Color | Hex | Usage |
|---|---|---|
| Emergency Red | `#D32F2F` | SOS, alert headers |
| Trust Blue | `#1565C0` | Section headers, Smart Aid branding |
| Background White | `#FFFFFF` | Panel backgrounds |
| Neutral Gray | `#F5F5F5` | Alternating row fills |
| Verified Green | `#2E7D32` | Verified claim indicators |
| Accent Teal | `#00695C` | Algorithm / data highlights |

---

## Compliance Checklist Before Printing

- [ ] All text is readable from 1 meter distance (minimum 18pt body)
- [ ] No claim states "AI diagnoses patients" — use "AI-assisted decision support" or "rule-based triage"
- [ ] No claim states "40% faster" or "85% accuracy" (purged per audit)
- [ ] Smart Fall Detection is in Future Plan ONLY — not listed as a current feature
- [ ] Research scores (88.6, 54.2, 48.7) are attributed to simulated scenarios, not clinical outcomes
- [ ] Team names, school, and adult sponsor are filled in
- [ ] Board dimensions confirmed with local fair organizers
- [ ] No copyrighted images used without permission
- [ ] QR code (optional) links to project repo or demo video

---

## Optional: QR Code Section

If you include a QR code, link it to one of:
- Project repository (if public)
- Demo video or screen recording
- Project one-pager PDF

Place QR code in the lower-right corner of the board with a brief label such as:  
*"Scan to view live demo / source code"*

---

*Template prepared by Master Technical Auditor — 2026-11-16*  
*Based on Smart Aid Project Audit `D:/hamo/Projects/SmartAid/Smart_Aid_ISEF_Submission/`*
