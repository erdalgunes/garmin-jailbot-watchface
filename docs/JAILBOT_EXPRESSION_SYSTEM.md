# Jailbot 2.0 Expression System Technical Specification

*Making Jailbot more expressive through health-driven facial animations*

Version: 1.0  
SDK: Garmin Connect IQ 3.2+  
Language: MonkeyC  
Last Updated: January 2025

---

## Executive Summary

The Jailbot 2.0 Expression System enhances the existing Jailbot watch face character with dynamic facial expressions driven by real-time health metrics. This system **does not replace** the Jailbot character design but makes it more engaging and personalized by reflecting the user's current physical and activity state through eye and mouth animations.

### Key Principles
- **DRY**: Single source of truth for all expressions (ExpressionLibrary)
- **KISS**: Simple state machine with clear health-to-expression mappings
- **YAGNI**: Only implements expressions for currently available health data
- **SOLID**: Modular architecture with clear interfaces and responsibilities

---

## 1. Architecture Overview

### System Flow
```
Health Sensors → HealthDataSource → RuleEngine → ExpressionState → BlinkController → Renderer
                                           ↓
                                    ExpressionLibrary
                                    (Single Source of Truth)
```

### Class Architecture
```
JailbotWatchFaceView
    └── ExpressionEngine
        ├── HealthDataSource (Sensor/Activity API wrapper)
        ├── RuleEngine
        │   └── IExpressionProvider[] (Strategy Pattern)
        │       ├── WorkoutProvider
        │       ├── StressProvider
        │       ├── EnergyProvider
        │       ├── GoalProvider
        │       ├── MoveBarProvider
        │       └── DefaultProvider
        ├── BlinkController
        ├── ExpressionLibrary (Expression definitions)
        └── ExpressionRenderer
            ├── EyeRenderer
            ├── MouthRenderer
            └── AssetManager
```

---

## 2. Core Components

### 2.1 ExpressionEngine
**Responsibility**: Orchestrates the entire expression system

```monkeyc
class ExpressionEngine {
    var _source as HealthDataSource;
    var _rules as RuleEngine;
    var _blink as BlinkController;
    var _renderer as ExpressionRenderer;
    var _state as ExpressionState;
    
    function updateAndRender(dc, nowSec, nowMs, isAwake) {
        var snapshot = _source.getSnapshot();
        _state = _rules.evaluate(snapshot, _state, nowSec);
        var blinkClosed = _blink.update(nowMs, _state.blinkPattern, isAwake);
        _renderer.draw(dc, _state, blinkClosed);
    }
}
```

### 2.2 HealthDataSource
**Responsibility**: Abstracts health sensor access with null-safe fallbacks

```monkeyc
class HealthSnapshot {
    var heartRate;        // BPM or null
    var hrZone;          // 0-5
    var bodyBattery;     // 0-100
    var stress;          // 0-100
    var stepGoalPercent; // 0-200+
    var moveBar;         // 0-5
}

class HealthDataSource {
    function getSnapshot() as HealthSnapshot {
        // Efficient single-read pattern with fallbacks
        var snapshot = new HealthSnapshot();
        snapshot.heartRate = Sensor.getHeartRate() ?: null;
        snapshot.hrZone = Activity.getInfo()?.currentHRZone ?: 0;
        snapshot.bodyBattery = Sensor.getBodyBattery() ?: -1;
        snapshot.stress = Sensor.getStressLevel() ?: -1;
        // ... etc
        return snapshot;
    }
}
```

### 2.3 ExpressionLibrary (DRY Principle)
**Responsibility**: Single source of truth for all expression definitions

```monkeyc
module ExpressionId {
    const REST = 0;
    const HAPPY = 1;
    const STRESSED = 2;
    const TIRED = 3;
    const FOCUSED = 4;
    const ALERT = 5;
}

class ExpressionLibrary {
    static function get(id) {
        if (id == ExpressionId.HAPPY) {
            return {
                :eyes => EyeType.HAPPY,
                :mouth => MouthType.SMILE,
                :blink => BlinkPattern.NORMAL,
                :minDur => 8,      // seconds
                :priority => 50
            };
        }
        // ... other expressions
    }
}
```

### 2.4 RuleEngine
**Responsibility**: Evaluates health data and selects appropriate expression

```monkeyc
class RuleEngine {
    var _providers;  // Array of IExpressionProvider
    
    function evaluate(snapshot, prevState, nowSec) {
        // Find highest priority expression
        var best = findBestExpression(snapshot);
        
        // Apply hysteresis to prevent flickering
        if (shouldKeepCurrent(prevState, best, nowSec)) {
            return prevState;
        }
        
        // Create new state from library
        var data = ExpressionLibrary.get(best[:id]);
        return new ExpressionState(data, best[:id], nowSec);
    }
}
```

### 2.5 Expression Providers (Strategy Pattern)
**Responsibility**: Each provider evaluates one health aspect

```monkeyc
class ExpressionProvider {
    function propose(snapshot, prevState) {
        // Abstract - override in subclasses
        throw "Abstract method";
    }
}

class WorkoutProvider extends ExpressionProvider {
    function propose(snapshot, prevState) {
        if (snapshot.hrZone >= 4) {  // Zone 4-5 = intense workout
            return { :id => ExpressionId.FOCUSED };
        }
        return null;
    }
}

class StressProvider extends ExpressionProvider {
    function propose(snapshot, prevState) {
        if (snapshot.stress >= 70) {  // High stress
            return { :id => ExpressionId.STRESSED };
        }
        return null;
    }
}
```

---

## 3. Expression Definitions

### 3.1 Expression States

| Expression ID | Eyes | Mouth | Blink Pattern | Priority | Min Duration | Trigger |
|--------------|------|-------|---------------|----------|--------------|---------|
| REST | Normal (O O) | Neutral (___) | Normal | 10 | 5s | Default state |
| HAPPY | Happy (^ ^) | Smile (\\___/) | Normal | 50 | 8s | Goal achieved |
| STRESSED | Stressed (> <) | Frown (/---\\) | Rapid | 80 | 10s | Stress ≥ 70 |
| TIRED | Tired (- -) | Neutral (---) | Slow | 70 | 10s | Body Battery ≤ 20 |
| FOCUSED | Focused (o o) | Determined (===) | Slow | 90 | 15s | HR Zone ≥ 4 |
| ALERT | Alert (O O) | Neutral (---) | Normal | 60 | 6s | Move Bar ≥ 4 |

### 3.2 Eye Types

```monkeyc
module EyeType {
    const NORMAL = 0;    // O O
    const TIRED = 1;     // - -
    const ALERT = 2;     // O O (wider)
    const HAPPY = 3;     // ^ ^
    const STRESSED = 4;  // > <
    const FOCUSED = 5;   // o o
    const WINK = 6;      // O - (future)
}
```

### 3.3 Mouth Types

```monkeyc
module MouthType {
    const NEUTRAL = 0;     // ___
    const SMILE = 1;       // \___/
    const FROWN = 2;       // /---\
    const OPEN = 3;        // O
    const DETERMINED = 4;  // ===
}
```

### 3.4 Blink Patterns

```monkeyc
module BlinkPattern {
    const NORMAL = 0;    // 3-6 sec interval, 120ms duration
    const TIRED = 1;     // 2-4 sec interval, 200ms duration
    const STRESSED = 2;  // 0.8-1.6 sec interval, 80ms duration
    const RESTING = 3;   // 6-10 sec interval, 120ms duration
}
```

---

## 4. State Management

### 4.1 Hysteresis Rules
Prevents expression flickering:

```monkeyc
function shouldKeepCurrent(prevState, newCandidate, nowSec) {
    if (prevState == null) return false;
    
    var elapsed = nowSec - prevState.sinceEpochSec;
    var isCriticalJump = (newCandidate.priority >= prevState.priority + 20);
    
    // Keep current unless:
    // 1. Min duration exceeded, OR
    // 2. New expression is critically important
    return (elapsed < prevState.minDurationSec && !isCriticalJump);
}
```

### 4.2 Priority System

Expressions are prioritized to ensure important states override less important ones:

1. **FOCUSED** (90) - Intense workout
2. **STRESSED** (80) - High stress alert
3. **TIRED** (70) - Low energy warning
4. **ALERT** (60) - Move reminder
5. **HAPPY** (50) - Goal celebration
6. **REST** (10) - Default state

---

## 5. Health Data Mappings

### 5.1 Configuration Constants

```monkeyc
module ExprConfig {
    // Health thresholds
    const BODY_BATT_LOW = 20;      // 0-100 scale
    const STRESS_HIGH = 70;        // 0-100 scale
    const HR_ZONE_FOCUSED = 4;     // Zones 4-5
    const MOVE_BAR_ALERT = 4;      // Level 4-5
    const GOAL_DONE = 100;         // 100% of step goal
}
```

### 5.2 Mapping Logic

| Health Metric | Range/Value | Expression | Rationale |
|--------------|-------------|------------|-----------|
| HR Zone | ≥ 4 | FOCUSED | Intense workout requires focus |
| Stress | ≥ 70 | STRESSED | High stress needs attention |
| Body Battery | ≤ 20 | TIRED | Low energy warning |
| Move Bar | ≥ 4 | ALERT | Reminder to move |
| Step Goal | ≥ 100% | HAPPY | Celebrate achievement |
| All Normal | - | REST | Default relaxed state |

---

## 6. Rendering System

### 6.1 Asset Management

```monkeyc
class AssetManager {
    var _cache;  // Dictionary of loaded bitmaps
    
    function getBitmap(key) {
        if (!_cache.hasKey(key)) {
            _cache[key] = Graphics.createBitmapResource(key);
        }
        return _cache[key];
    }
}
```

### 6.2 Expression Renderer

```monkeyc
class ExpressionRenderer {
    function draw(dc, state, blinkClosed) {
        // Draw eyes (with blink state)
        _eyeRenderer.draw(dc, state.eyes, blinkClosed);
        
        // Draw mouth (unaffected by blink)
        _mouthRenderer.draw(dc, state.mouth);
    }
}
```

---

## 7. Performance Optimizations

### 7.1 Memory Management
- Single instance of each expression state
- Bitmap caching in AssetManager
- Reuse HealthSnapshot object
- No allocations in draw loop

### 7.2 CPU Optimization
- Single sensor read per frame
- Lazy evaluation of expressions
- Early exit from rule evaluation
- Minimal floating-point operations

### 7.3 Battery Optimization
- Disable blinking in sleep mode
- Reduce update frequency in AOD
- Cache sensor values for 1 second
- Use partial updates when possible

### 7.4 Update Frequencies

| Mode | Update Rate | Blink Animation | Sensor Reads |
|------|-------------|-----------------|--------------|
| Active | 1 Hz | Enabled | Every update |
| AOD | 1/60 Hz | Disabled | Cached |
| Sleep | None | Disabled | None |

---

## 8. Implementation Guide

### 8.1 Integration with Existing Watch Face

```monkeyc
class JailbotWatchFaceView extends WatchFace {
    var _expressionEngine;
    
    function onLayout(dc) {
        WatchFace.onLayout(dc);
        _expressionEngine = buildExpressionSystem();
    }
    
    function onUpdate(dc) {
        // Draw time and base Jailbot
        drawJailbotBase(dc);
        drawTime(dc);
        
        // Add expressions
        var now = System.getClockTime();
        var nowMs = System.getTimer();
        _expressionEngine.updateAndRender(dc, now, nowMs, !inSleepMode);
    }
}
```

### 8.2 Building the Expression System

```monkeyc
function buildExpressionSystem() {
    // Data source
    var source = new HealthDataSource();
    
    // Providers (order doesn't matter - priority handles precedence)
    var providers = [
        new WorkoutProvider(),
        new StressProvider(),
        new EnergyProvider(),
        new MoveBarProvider(),
        new GoalProvider(),
        new DefaultProvider()
    ];
    
    // Rule engine
    var rules = new RuleEngine(providers);
    
    // Animation
    var blink = new BlinkController();
    
    // Rendering
    var assets = new AssetManager();
    var eyes = new EyeRenderer(assets, eyePositions);
    var mouth = new MouthRenderer(assets, mouthPosition);
    var renderer = new ExpressionRenderer(eyes, mouth);
    
    // Engine
    return new ExpressionEngine(source, rules, blink, renderer);
}
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

```monkeyc
// Test expression selection
function testStressOverridesHappy() {
    var snapshot = new HealthSnapshot();
    snapshot.stress = 75;
    snapshot.stepGoalPercent = 150;
    
    var result = ruleEngine.evaluate(snapshot, null, 0);
    assert(result.id == ExpressionId.STRESSED);  // Stress has higher priority
}

// Test hysteresis
function testMinDurationRespected() {
    var prevState = createState(ExpressionId.HAPPY, 0);
    var snapshot = createNormalSnapshot();
    
    var result = ruleEngine.evaluate(snapshot, prevState, 5);
    assert(result.id == ExpressionId.HAPPY);  // Still happy (min 8s)
}
```

### 9.2 Integration Tests

1. **State Transitions**: Verify smooth transitions between expressions
2. **Sensor Failures**: Test graceful handling of null sensor data
3. **Performance**: Ensure < 20ms update time
4. **Battery Impact**: Monitor power consumption in different modes

### 9.3 Visual QA Checklist

- [ ] All eye expressions render correctly
- [ ] All mouth expressions render correctly
- [ ] Blink animations are smooth
- [ ] Expressions align with Jailbot's face
- [ ] No flickering between states
- [ ] AOD mode shows static expression

---

## 10. Extension Points

### 10.1 Adding New Expressions

1. Add new constant to `ExpressionId`
2. Add definition to `ExpressionLibrary`
3. Create new provider class
4. Register provider in `buildExpressionSystem()`

Example: Adding a "Celebrating" expression for personal records:

```monkeyc
// 1. Add ID
module ExpressionId {
    const CELEBRATING = 6;
}

// 2. Define expression
class ExpressionLibrary {
    static function get(id) {
        if (id == ExpressionId.CELEBRATING) {
            return {
                :eyes => EyeType.WINK,
                :mouth => MouthType.SMILE,
                :blink => BlinkPattern.NORMAL,
                :minDur => 10,
                :priority => 95  // Highest priority
            };
        }
    }
}

// 3. Create provider
class PersonalRecordProvider extends ExpressionProvider {
    function propose(snapshot, prevState) {
        if (detectPersonalRecord()) {
            return { :id => ExpressionId.CELEBRATING };
        }
        return null;
    }
}
```

### 10.2 Future Enhancements

- **Contextual Expressions**: Time-of-day awareness (sleepy at night)
- **Micro-expressions**: Brief emotional reactions
- **Compound States**: Combining multiple health factors
- **User Customization**: Expression sensitivity settings
- **Seasonal Themes**: Holiday-specific expressions

---

## 11. Resource Requirements

### 11.1 Bitmap Assets

Each expression component requires bitmap resources:

```xml
<!-- resources/bitmaps.xml -->
<bitmap id="eyes_normal" filename="eyes/normal.png"/>
<bitmap id="eyes_tired" filename="eyes/tired.png"/>
<bitmap id="eyes_happy" filename="eyes/happy.png"/>
<bitmap id="eyes_stressed" filename="eyes/stressed.png"/>
<bitmap id="eyes_focused" filename="eyes/focused.png"/>
<bitmap id="eyes_closed" filename="eyes/closed.png"/>

<bitmap id="mouth_neutral" filename="mouth/neutral.png"/>
<bitmap id="mouth_smile" filename="mouth/smile.png"/>
<bitmap id="mouth_frown" filename="mouth/frown.png"/>
<bitmap id="mouth_open" filename="mouth/open.png"/>
<bitmap id="mouth_determined" filename="mouth/determined.png"/>
```

### 11.2 Memory Budget

| Component | Estimated Memory |
|-----------|-----------------|
| Expression Engine | ~2 KB |
| Bitmap Cache (11 assets) | ~8 KB |
| Health Snapshot | ~100 bytes |
| State Objects | ~200 bytes |
| **Total** | **~10.3 KB** |

---

## 12. Privacy & Ethics

### 12.1 Data Usage
- All health data processing happens on-device
- No health data is transmitted or stored
- Expressions are ephemeral (not logged)

### 12.2 User Control
- Respects system health permissions
- Falls back to REST expression if sensors disabled
- No judgment implied by expressions (just reflection of metrics)

---

## Summary

The Jailbot 2.0 Expression System transforms the static Jailbot character into a dynamic, health-aware companion that reflects the user's physical and activity state through subtle facial animations. By following SOLID principles and maintaining a clean architecture, the system is both performant and extensible, allowing for future enhancements without modifying core components.

Key achievements:
- **DRY**: Single ExpressionLibrary maintains all expression definitions
- **KISS**: Simple provider pattern for health evaluation
- **YAGNI**: Only implements expressions for available sensors
- **SOLID**: Clean interfaces, single responsibilities, open for extension

The system integrates seamlessly with the existing Jailbot watch face, adding personality without changing the fundamental character design that users love.

---

*End of Technical Specification v1.0*