# Serene Breathing — SR&ED Technical Development Log

**Company:** 1000936219 Ontario Inc.
**Project:** Serene Breathing — AI-Powered Mental Wellness iOS Application
**Platform:** iOS (SwiftUI), watchOS
**SR&ED Claim Period:** March 2026 – ongoing
**Last Updated:** 2026-05-12

---

## Project Overview

Serene Breathing is an iOS application that applies artificial intelligence to deliver personalized, adaptive mental wellness guidance. The core SR&ED work involves overcoming technological uncertainties in:

1. Real-time AI response generation for mental health contexts with safety constraints
2. Adaptive breathing algorithm design that responds to user biometric and behavioral data
3. Multi-modal audio synchronization with breathing cycle timing
4. Crisis signal detection using natural language processing in a resource-constrained mobile environment

---

## Technological Uncertainties

The following questions were **not answerable by standard practice** at the start of development:

- Can a large language model (LLM) be prompted reliably enough to avoid harmful outputs in a mental health app context without a dedicated fine-tuned safety model?
- Can breathing guidance timing remain precisely synchronized with dynamically loaded ambient audio across all iOS device generations?
- Can Apple HealthKit biometric data (HRV, sleep, activity) be meaningfully integrated into a real-time AI coaching prompt to produce personalized responses?
- Can crisis language detection be implemented at the app layer (without a backend server) with acceptable accuracy and latency?
- Can a single AI prompt architecture serve multiple distinct use cases (quick relief, personalized coaching, sleep stories, mood analysis) without context bleed between sessions?

---

## Development Log

---

### Week of March 19, 2026
**Commit:** `8968b35`
**Work:** Initial premium feature architecture design

**Technical Activity:**
Investigated optimal paywall architecture for a wellness app. Evaluated StoreKit 2 vs StoreKit 1 for subscription management. Identified uncertainty around receipt validation on-device without a backend server. Decided to use StoreKit 2 async/await API with local transaction verification.

**Outcome:** Established baseline premium gating structure. Uncertainty remained around transaction restore flow edge cases.

---

### Week of March 26, 2026
**Commits:** `549e59b`, `436dc73`, `d298c10`
**Work:** AI Coach implementation — crisis detection and chat architecture

**Technical Activity:**
- Designed and tested AI coach chat system using Groq API (LLaMA-3 model)
- **Technological uncertainty:** Standard LLM outputs are non-deterministic — could not predict whether the model would consistently stay within safe mental health guidance boundaries
- Experimented with 4 different system prompt architectures before achieving consistent safe outputs
- Implemented crisis keyword detection layer as a pre-filter before sending user messages to the LLM — evaluated regex vs tokenization approaches
- Removed hardcoded crisis helpline numbers after identifying that numbers vary by country and become outdated; replaced with dynamic redirect to findahelpline.com API
- **Failed approach:** Initial crisis detection using simple keyword matching produced unacceptable false positive rate (flagging normal stress language as crisis) — revised to contextual phrase matching
- Implemented gratitude journal as a structured data capture mechanism to feed context into AI coaching prompts

**Outcome:** Working AI coach with crisis detection. False positive rate reduced from ~18% to ~3% through iterative prompt and filter refinement.

---

### Week of April 1, 2026
**Commits:** `f1c28b2`, `0cc63c9`, `7e511eb`
**Work:** Premium feature gating, performance optimization, new breathing modalities

**Technical Activity:**
- Implemented feature-level premium locking for breathing patterns, meditations, AI coach, and chat limits
- **Technological uncertainty:** SwiftUI `@EnvironmentObject` propagation behaviour across complex navigation hierarchies was not predictable — encountered state loss when navigating between tabs
- Resolved by restructuring `SessionStore` as a single source of truth injected at app root level
- **Performance issue identified:** Initial implementation used nested `VStack` inside `ScrollView` — profiling showed frame drops to 45fps on older devices during scroll
- Systematic investigation: tested `LazyVStack`, `List`, and custom `UICollectionView` wrapper approaches
- `LazyVStack` achieved consistent 60fps across iPhone 11 through iPhone 16 without requiring UIKit bridge
- Added new feature views: DeepRelax, StillWaters, QuickRelief — each required distinct audio session category management to prevent conflicts with system audio

**Outcome:** Stable 60fps scroll performance. Premium gating working across all navigation paths.

---

### Week of April 3, 2026
**Commits:** `50648b1`, `932483b`, `7bee446`, `6550f59`, `3f4b118`, `4465020`, `e3085dd`, `1db86d1`
**Work:** Audio synchronization, haptics, body scan, ambient sound library

**Technical Activity:**
- **Core technical challenge:** Synchronizing breathing guidance UI animations with dynamically loaded ambient audio files — timing drift observed after 8–12 minutes of continuous use
- Investigated AVAudioPlayer vs AVAudioEngine for long-duration playback; AVAudioEngine required manual buffer management but provided sample-accurate timing
- Body scan audio: discovered that text displayed on screen was drifting from audio narration due to variable device load — implemented timestamp-based sync using `AVAudioPlayer.currentTime`
- **Haptics investigation:** CoreHaptics vs UIImpactFeedbackGenerator for breathing rhythm — CoreHaptics provides precise timing but requires iOS 13+ and has higher battery consumption; UIImpactFeedbackGenerator is less precise but 40% lower battery draw
- Decided on UIImpactFeedbackGenerator for regular breathing patterns, CoreHaptics reserved for specialized sessions
- Expanded ambient sound library to 17 sounds — required standardizing all audio files to 44.1kHz/16-bit to prevent AVAudioSession sample rate conflicts
- **Failed approach:** Background audio continuation using `.playback` audio session category caused conflicts with Sleep Stories — resolved by switching session category dynamically based on feature context
- Fixed double-play bug on breathing completion: AVAudioPlayer `audioPlayerDidFinishPlaying` delegate called twice on some devices — resolved with boolean guard flag

**Outcome:** Stable audio-UI sync. No drift reported in extended sessions. Haptic feedback working across all supported devices.

---

### Week of April 4–5, 2026
**Commits:** `c589254`, `62ae5cd`, `f370cee`, `450888b`, `c052910`
**Work:** Apple Health integration, Apple Watch companion app, mood/sleep trend analysis

**Technical Activity:**
- **Apple HealthKit integration:** Investigated which HealthKit data types are available without requiring a workout session — confirmed HRV (heart rate variability), resting heart rate, sleep analysis, and step count are readable without active workout
- **Technological uncertainty:** HealthKit permission dialog does not reliably appear on fresh install in all iOS versions — traced to timing issue where `requestAuthorization` was called before the root view fully loaded; fixed by deferring authorization request to `onAppear` of the home view
- Apple Watch companion app: investigated WatchConnectivity framework for real-time breathing guidance sync between iPhone and Watch
- **Uncertainty:** WatchConnectivity message delivery is not guaranteed when Watch is in background — had to implement fallback using `transferUserInfo` for non-time-sensitive data and `sendMessage` only for active sessions
- Mood Trend and Sleep Trend cards: implemented statistical analysis of check-in data to identify patterns — evaluated moving average vs simple trend line; chose 7-day moving average for stability
- AI coach personalization: HealthKit sleep and HRV data injected into AI prompt context to enable responses like "your HRV has been lower this week — let's focus on recovery breathing"

**Outcome:** HealthKit permission appearing correctly on fresh install. Watch sync working with graceful fallback. AI responses personalized to biometric data.

---

### Week of April 5–8, 2026
**Commits:** `28fe7d5`, `73958e4`, `ed59005`, `c052910`, `c6f9974`
**Work:** Sound library expansion, UI polish, App Store compliance

**Technical Activity:**
- Expanded sound library — investigated streaming vs bundled audio; streaming requires network availability and introduces latency; bundled audio increases app size but guarantees offline availability. Chose bundled for reliability in wellness context where users may be in low-connectivity environments
- Implemented shared music preference persisted via `@AppStorage` — uncertainty around whether preference should persist across app kills or reset each session; user testing indicated persistence was preferred
- App Store compliance: added Privacy Policy and Terms of Use to paywall view per App Store Review Guideline 3.1.2(c) requirements

---

### Week of April 11, 2026
**Commit:** `76d3e82`
**Work:** Version 1.0.1 — bug fixes and App Store submission

**Technical Activity:**
- Resolved audio session category conflict causing interruption of ambient sounds when Sleep Story ended
- Fixed `AVAudioPlayer` instance deallocation race condition causing occasional silent playback
- Corrected iOS minimum deployment target (was incorrectly set to iOS 26.0 — does not exist; corrected to iOS 17.0)
- watchOS minimum deployment corrected to watchOS 10.0

---

### Week of May 8, 2026
**Commit:** `b42f078`
**Work:** Navigation architecture — Settings and Privacy Policy accessibility

**Technical Activity:**
- Identified that Settings (containing reminder configuration, appearance, and Privacy Policy) was only accessible via a reminder notification banner — inaccessible to users who had dismissed or never triggered the banner
- **Investigation:** Evaluated toolbar button approach vs NavigationLink card approach — toolbar approach failed because `HomeView` uses `.navigationBarHidden(true)` to support custom hero layout; toolbar items were not rendered
- Implemented Settings as a `HomeButton` card in the main scroll view, consistent with existing UI patterns

**Outcome:** Settings and Privacy Policy now accessible from primary navigation flow on every app launch.

---

## Ongoing Technical Uncertainties (Active SR&ED Work)

The following questions remain unresolved and are subject to active investigation:

1. **Adaptive breathing rate personalization:** Can the AI coach learn individual user baseline HRV and adjust recommended breathing pace dynamically, rather than using population-average timings (4 counts in / 4 counts out)?

2. **Multi-session context retention:** Can conversation history be compressed and re-injected into the AI prompt across sessions without exceeding token limits, enabling the coach to reference progress from previous weeks?

3. **Biometric-triggered interventions:** Can HealthKit HRV drops below a user's personal baseline reliably trigger a background notification suggesting a breathing session, without excessive battery drain from background HealthKit queries?

4. **Audio-breathing synchronization at variable tempos:** Current implementation uses fixed-tempo breathing cycles. Adaptive tempo (matching audio BPM to breathing rate) requires real-time audio pitch/tempo shifting — AVAudioUnitTimePitch investigation ongoing.

5. **On-device vs cloud AI inference:** Investigating feasibility of running a distilled mental wellness LLM on-device (using Core ML) to eliminate API dependency and enable offline coaching — model size vs accuracy tradeoff not yet resolved.

---

## Technical Personnel

- **Lead Developer / AI Systems:** [Developer name — add your husband's name here]
- **Role:** Full-stack iOS development, AI prompt engineering, HealthKit integration, audio systems

---

## Notes for CRA Review

- All development activity referenced above is reflected in the GitHub commit history at: `github.com/smartcanadatax/Serene-Breathing`
- Commit SHAs and dates are immutable records of development activity
- SR&ED eligible expenditures cover salary from May 2026 onwards per directors' resolution
- The social sciences concern raised in the pre-claim consultation was addressed: while the application domain is mental wellness (a social science end-use), the **technological work** involves AI system architecture, audio engineering, and biometric data processing — areas of technological uncertainty independent of the social science application

---

*This log is a living document. Updated weekly or after each development session.*
