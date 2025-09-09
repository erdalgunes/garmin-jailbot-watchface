# Jailbot Watch Face — Technical Specification
Version: 1.1 (Simplified)  
SDK: Garmin Connect IQ 8.2.3  
Language: MonkeyC  
Targets: fenix 7 family (MIP), Forerunner 965 (AMOLED with AOD)

---

## 1. Architecture Overview

### Goal
- Unique time presentation where the current hour numeral orbits the watch rim based on the current minute (e.g., 12:15 → "12" is at 3 o'clock).
- Simple "Jailbot" character with natural blinking animations without compromising battery life.
- Robust AOD with a "Ghost Jailbot" outline rendering and curated blink schedule.

### High-Level Modules
- **JailbotWatchFaceView** (main UI, update loop, hour-on-rim logic)
- **AODComponents** (AOD rendering, ghost mode, AOD scheduling)
- **PixelResolution** (device scaling, crisp pixel art primitives)
- **JailbotWatchFaceApp** (application entry point and lifecycle)

### Primary Toybox APIs
- WatchUi, Graphics, System, Time, Time.Gregorian
- Lang, Math, Application

### Time Positioning Model
- `minuteAngle = minutes * Math.PI / 30.0`
- Position = `center + (rimRadius - 35) × [sin(angle), -cos(angle)]`
- 0 minutes at 12 o'clock; 15 minutes at 3 o'clock; always upright (no text rotation)

### Update Policy
- Normal: 1000 ms (per-second update for blinking)
- AOD: minimal redraws (once per minute), with a curated blink schedule

---

## 2. Component Specifications

### 2.1 JailbotWatchFaceView
#### Responsibilities
- Initialize view, fonts, colors, and scaling via PixelResolution.
- Compute hour rim position each update tick.
- Render main scene: hour on rim, Jailbot face with blinking.
- Route to AODComponents when AOD or sleep mode is active.

#### Inputs
- Time: current hour/minute/second, 12/24h setting
- Blink state (simple timer-based)
- PixelResolution metrics (scale, center, radius)

#### Outputs
- Calls Graphics API to draw primitives and text
- Delegates AOD operations to AODComponents

#### Key Behaviors
- Hour number = 12/24h-respecting display hour; positioned by minute angle.
- Hour text remains upright; centered at computed (x, y).
- Simple blinking: 2-8 second intervals, 150ms duration.

### 2.2 AODComponents
#### Responsibilities
- Detect AOD mode, switch to low-change drawing.
- Render "Ghost Jailbot" outline with ~70% fewer pixels vs. normal.
- Apply curated blink schedule to create minimal, battery-safe motion.

#### AOD Blink Schedule
- Minutes: 0, 13, 17, 26, 30, 34, 39, 43, 51, 52
- Blink duration: 150 ms

#### Techniques
- Use outline-only rendering (no fill) + reduced stroke count
- Avoid anti-aliased operations; prefer single-color lines
- Reduce per-frame drawing calls (compose a minimal scene)

#### Update Rate
- Once per minute in AOD; trigger one additional on-demand partial update for the blink event in the scheduled minute.

### 2.3 PixelResolution
#### Responsibilities
- Normalize pixel art appearance across resolutions (fenix7: 218/260/280; fr965: 454).
- Provide a consistent logical grid (e.g., baseGrid = 228 units) and an integer scale factor:
  - `scale = floor(min(deviceW, deviceH) / baseGrid)`
- Provide drawing helpers
  - drawPixel, drawLine, drawRect, drawCircle
  - text metrics wrapper and centered text draw
- Provide geometric info
  - centerX, centerY, rimRadius (min dimension / 2 - margin)

#### AOD Optimization
- Expose simplified draw methods for outline-only mode.

### 2.4 JailbotWatchFaceApp
#### Responsibilities
- Application lifecycle management
- Initialize watch face view
- Handle settings and configurations

---

## 3. API Documentation

*Note: Signatures are representative MonkeyC; exact return types may vary slightly per SDK.*

### 3.1 JailbotWatchFaceView

```monkeyc
function onLayout(dc as Graphics.Dc)
```
- Compute center, rimRadius, scale via PixelResolution.
- Precompute sin/cos tables for 60 minute positions.

```monkeyc
function onUpdate(dc as Graphics.Dc)
```
- if AODComponents.isInAOD(): AODComponents.draw(dc); return
- time = Time.now()
- drawBackground(dc)
- drawHourOnRim(dc, time)
- drawJailbotCharacter(dc)
- updateBlinkState()
- scheduleNextUpdate(1000)

```monkeyc
function onPartialUpdate(dc as Graphics.Dc)
```
- Used for blink frames (normal and AOD curated schedule).

```monkeyc
function drawHourOnRim(dc, time as Time.Gregorian.Info)
```
- minutes = time.min
- minuteAngle = minutes * Math.PI / 30.0
- r = rimRadius - 35
- x = centerX + r * Math.sin(minuteAngle)
- y = centerY - r * Math.cos(minuteAngle)
- hourText = getDisplayHour(time.hour, is24hSetting())
- drawCenteredText(dc, hourText, x, y)

```monkeyc
function getDisplayHour(hour24 as Number, use24h as Boolean) as String
```
- If use24h → "00".."23"
- Else → "12" for 0 or 12; otherwise hour % 12

### 3.2 AODComponents

```monkeyc
function isInAOD() as Boolean
```
- Detect via WatchUi.getDisplayMode() or sleep state callbacks.

```monkeyc
function draw(dc as Graphics.Dc)
```
- drawBackgroundMinimal(dc)
- drawGhostJailbotOutline(dc)  // ~70% fewer pixels vs. filled
- drawHourOnRimAOD(dc)         // no anti-alias, limited colors
- maybeBlink(dc)               // only if current minute is in schedule

```monkeyc
function maybeBlink(dc)
```
- if currentMinute in [0,13,17,26,30,34,39,43,51,52]:
  - toggle small outline stroke or eye highlight
  - use onPartialUpdate to revert after 150 ms

### 3.3 PixelResolution

```monkeyc
function init(dc as Graphics.Dc)
```
- Determine deviceW, deviceH; compute center, rimRadius, scale.

```monkeyc
function getScale() as Number
function getCenter() as {x:Number, y:Number}
function getRimRadius() as Number
```

```monkeyc
function drawPixel/drawLine/drawRect/drawCircle(...)
```
- Respect integer snapping for crispness
- outlineOnly flag for AOD

```monkeyc
function drawCenteredText(dc, text, x, y, font?, color?)
```

---

## 4. Performance Considerations

### Update Budgets
- Active mode target: < 20 ms per onUpdate on MIP; < 12 ms on AMOLED if possible.
- AOD: Prefer single onUpdate per minute; one extra short partial update for blink in scheduled minutes.

### Drawing
- Precompute 60 sin/cos pairs for minute angles at startup.
- Cache text widths for "00".."23" (or "1".."12") to avoid repeated metrics calls.
- Avoid anti-aliased gradients; use solid fills and minimal strokes.

### Memory
- Avoid large bitmaps; use vector/pixel primitives.
- Forerunner 965 shows higher resolution; prefer procedural drawing, not scaled bitmaps.

### Garbage Collection
- Reuse buffers/objects; avoid string concatenations inside onUpdate.
- Preallocate colors and pens.

### Power
- AOD: do not animate continuously; follow blink schedule.
- Minimize color changes and state switches; batch draw operations where possible.

---

## 5. Testing Guidelines

### Devices/Resolutions
- fenix 7S (218x218), 7 (260x260), 7X (280x280)
- Forerunner 965 (454x454, AMOLED with AOD)
- Simulator + on-device tests for both MIP and AMOLED.

### Functional Test Cases

#### Time Rim Placement
- 12:00 → "12" at 12 o'clock
- 12:15 → "12" at 3 o'clock
- 12:30 → "12" at 6 o'clock
- 12:45 → "12" at 9 o'clock
- 23:59 → hour "23" at 11:59 position; at 00:00 → "00" at 12 o'clock

#### 12/24h Toggle
- Respect device setting; midnight/noon edge cases

#### Blink Timing (Active)
- Random intervals 2–8 s; blink lasts ~150 ms; ensure no CPU spikes

#### AOD Schedule
- Verify blink only at minutes [0,13,17,26,30,34,39,43,51,52]
- Confirm only brief partial updates occur in those minutes

#### Jailbot Rendering
- Character centered and properly scaled
- No clipping at various resolutions

#### Battery
- Low battery → ensure AOD remains minimal; no heavy redraws

### Visual QA
- Verify text legibility on MIP vs AMOLED
- Hour text not overlapping Jailbot character
- Ghost outline visible but sparse in AOD

### Performance QA
- Measure onUpdate time with System.getTimer()
- Observe GC frequency in logs
- AOD current draw sanity check (compare with baseline watch face)

### Regression
- DST changes, month rollover, leap year unaffected
- Locale changes (numerals) — if using default numerals, verify unchanged

---

## 6. Deployment Process

### Project Structure
```
source/
├── JailbotWatchFaceView.mc
├── AODComponents.mc
├── PixelResolution.mc
└── JailbotWatchFaceApp.mc

resources/
├── strings/strings.xml
└── fonts/ (optional pixel font assets)

manifest.xml
monkey.jungle
/docs/
├── TECHNICAL_SPEC.md
└── README.md
```

### Manifest Configuration
- **minSdkVersion**: 8.2.3
- **products**:
  - fenix7 family variants (7S, 7, 7X)
  - forerunner965
- **permissions**: None required (simplified version)
- **AOD**: true (for AMOLED devices)

### Build Process
1. Using Connect IQ SDK Manager 8.2.3
2. Build with MonkeyC compiler via VS Code extension or command line
3. Validate no warnings; size within limits

### Signing
- Debug keys for simulator
- Production signing keys for store release

### Versioning
- Semantic versioning (major.minor.patch)
- Increment for any UI change affecting users; patch for internal fixes

### Distribution
- **Garmin Connect IQ Store**
- Provide description, screenshots (MIP + AMOLED), and AOD previews

### Post-Release Monitoring
- Capture crash logs (if any)
- Gather user feedback on AOD battery performance and readability
- Plan updates for new device resolutions

---

## Appendix A: Pseudocode Snippets

### Hour Rim Position
```monkeyc
function drawHourOnRim(dc) {
    var now = Time.now();
    var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
    var min = info.min;
    var use24h = System.getDeviceSettings().is24Hour;
    var hourText = getDisplayHour(info.hour, use24h);

    var angle = min * Math.PI / 30.0; // 0..2π
    var r = PixelResolution.getRimRadius() - 35.0;

    var cx = PixelResolution.getCenter().x;
    var cy = PixelResolution.getCenter().y;

    var x = cx + r * Math.sin(angle);
    var y = cy - r * Math.cos(angle);

    PixelResolution.drawCenteredText(dc, hourText, x, y);
}
```

### Natural Blink Scheduler (Active)
```monkeyc
if (now >= nextBlinkAt) {
    blinkOn = true;
    WatchUi.requestUpdate();
    // schedule auto-off after 150 ms
    System.setTimer(150, method(:turnBlinkOff));
    // schedule next blink in 2..8 seconds
    nextBlinkAt = now + (2 + rand() * 6) * 1000;
}
```

### AOD Curated Blink
```monkeyc
var schedule = {0,13,17,26,30,34,39,43,51,52};

if (isAOD && schedule.contains(currentMinute)) {
    blinkOn = true;
    WatchUi.requestUpdate(); // partial
    System.setTimer(150, method(:turnBlinkOff));
}
```

---

## Appendix B: AOD Rendering Rules

- **Colors**: 1–2 colors max; prefer white/green on black for AMOLED
- **Primitives**: outlines only; no gradients or complex fills
- **Updates**: one per minute; one brief partial update for scheduled blink
- **Hour Rim**: draw hour text and minute tick marks sparsely or skip ticks for minimalism
- **Ghost Jailbot**: stroke weight 1 px; reduce feature details by ~70%

---

*End of Technical Specification v1.1*