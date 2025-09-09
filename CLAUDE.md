# CLAUDE.md - Jailbot Watch Face Project

## 🔴 MANDATORY: Ustad Cognitive Scaffolding Protocol

### CRITICAL: Use Ustad BEFORE Making Claims or Decisions
**USTAD IS YOUR COGNITIVE SCAFFOLDING** - Prevents hallucinations and overcomplexity

#### Universal 3-Stage Verification Workflow
```bash
# Stage 1: CHECK WITH USTAD (primary verification)
ustad check hallucination "claim" --facts "known fact"
ustad check complexity --components 10 --requirements 3

# Stage 2: GATHER EVIDENCE if needed (supporting tools)
tavily search "Garmin Connect IQ best practices"  # Current info
llm "analyze this MonkeyC approach" -m gpt-3.5-turbo  # Reasoning

# Stage 3: VERIFY SUCCESS (always through Ustad)
ustad check success --claimed --evidence "simulator shows working" --expected "hour circles rim"
```

### Before ANY Fix or Implementation
```bash
# 1. Check complexity FIRST
ustad check complexity --components 5 --requirements 1
# If ratio > 2.0, STOP and simplify

# 2. Verify approach
ustad check hallucination "this fix will work" --facts "MonkeyC documentation"

# 3. After implementation, verify success
pkill -f simulator
monkeyc -d fenix7 -f monkey.jungle -o build/test.prg -y developer_key.der
monkeydo build/test.prg fenix7
screencapture -x /tmp/verify.png
ustad check success --claimed --evidence "/tmp/verify.png shows fix" --expected "hour displays correctly"
```

## 🚨 CRITICAL: Anti-Hallucination Protocol

### MANDATORY VERIFICATION WORKFLOW
```bash
# BEFORE claiming ANY fix works:
1. ustad check hallucination "fix works" --facts "need visual proof"
2. pkill -f simulator                    # Kill ALL old instances
3. monkeyc -d fenix7 -f monkey.jungle -o build/test.prg -y developer_key.der
4. monkeydo build/test.prg fenix7        # Run fresh build
5. sleep 3                                # Wait for UI
6. screencapture -x /tmp/verify.png      # Capture proof
7. VISUALLY VERIFY the fix in screenshot
8. ustad check success --claimed --evidence "screenshot shows fix" --expected "requirement met"
9. Only THEN claim success
```

**RED FLAGS OF HALLUCINATION:**
- Pointing to old screenshots as "proof"
- Not rebuilding after changes
- Assuming simulator is showing latest code
- Claiming "it should work" without verification
- Not using ustad verification before claims

## 🎯 Project Core Design (NEVER CHANGE)

### Novel Time Display Concept
**HOUR**: Displayed as TEXT number
**MINUTE**: Shown by TEXT POSITION around rim
- Hour number circles the watch rim
- Position indicates current minute (12 o'clock = :00, 3 o'clock = :15, etc.)
- This is the unique selling point - DO NOT ALTER

### Technical Implementation
```mc
// Critical positioning code in JailbotWatchFaceView.mc
var minuteAngle = minutes * Math.PI / 30.0;  // 6 degrees per minute
var handRadius = rimRadius - 35;  // MUST be 35+ to prevent bounds overflow
var numberX = centerX + handRadius * Math.sin(minuteAngle);
var numberY = centerY - handRadius * Math.cos(minuteAngle);
```

## 🧠 Ustad-Driven Development Workflow

### For Bug Fixes
```bash
# 1. Verify the bug exists
ustad check hallucination "bug exists" --facts "screenshot evidence"

# 2. Check fix complexity
ustad check complexity --components 3 --requirements 1

# 3. Research if needed
tavily search "Garmin Connect IQ [specific error]"
llm "analyze MonkeyC error: [error]" -m gpt-3.5-turbo

# 4. Implement fix
# ... make changes ...

# 5. Verify fix works
pkill -f simulator && monkeyc -d fenix7 -f monkey.jungle -o build/test.prg -y developer_key.der
monkeydo build/test.prg fenix7
screencapture -x /tmp/fixed.png
ustad check success --claimed --evidence "/tmp/fixed.png" --expected "bug resolved"
```

### For New Features
```bash
# 1. Check complexity before starting
ustad check complexity --components 10 --requirements 3

# 2. Research best practices
tavily search "Garmin watch face [feature] implementation"
llm "design approach for [feature]" -m gpt-3.5-turbo

# 3. Implement incrementally with verification
# After each component:
ustad check hallucination "component works" --facts "tested in simulator"

# 4. Capture learnings
gh-learn add --kind success_pattern --body '{"feature": "jailbot", "pattern": "circular time"}' --tags garmin watchface
```

## 📋 Testing Protocols

### Simulator Testing Checklist with Ustad
- [ ] `ustad check hallucination "ready to test" --facts "code compiled"`
- [ ] Kill all existing simulators
- [ ] Build with latest code
- [ ] Launch fresh simulator instance
- [ ] Test at critical minutes: :00, :15, :30, :45
- [ ] Verify text stays within bounds at all positions
- [ ] Screenshot evidence of working state
- [ ] `ustad check success --claimed --evidence "screenshots" --expected "all positions work"`
- [ ] Test mood transitions (Victory, Drowsy, etc.)
- [ ] Verify AOD mode functionality

### Device Testing (FR965)
```bash
# Pre-deployment verification
ustad check hallucination "ready to deploy" --facts "simulator tests pass"

# Deployment workflow
pkill -f "Garmin Express"  # MUST close first
monkeyc -d fenix7 -f monkey.jungle -o deploy.prg -y developer_key.der
/opt/homebrew/bin/mtp-sendfile deploy.prg 16777231

# Verify deployment
/opt/homebrew/bin/mtp-files | grep -i jailbot
ustad check success --claimed --evidence "file on device" --expected "deployed successfully"
```

## 🏗️ Project Architecture

### File Structure
```
/source/
├── JailbotWatchFaceView.mc    # Main watch face, hour positioning logic
├── AODComponents.mc            # Always-On Display with Ghost Jailbot
├── MoodSystem.mc              # Mood states (Victory, Drowsy, Focused, etc.)
├── MoodEngine.mc              # Mood orchestration, blinking scheduler
├── EmoticonSystem.mc          # ASCII emoticon rendering (":D", "-_-", etc.)
├── PixelResolution.mc         # Pixel art rendering system
└── HealthDataProvider.mc      # Sensor data aggregation
```

### Key Components

#### Mood System
- **States**: Victory, Overheat, Drowsy, Recovering, Focused, Charged, Standby
- **Triggers**: Based on body battery, stress, steps, heart rate
- **Blinking**: Natural blink patterns per mood (2-8 second intervals)

#### AOD Implementation
- Ghost Jailbot: Hollow outline (70% fewer pixels)
- Blinking schedule: Minutes 0,13,17,26,30,34,39,43,51,52
- Minimal redraws for battery efficiency

## 🐛 Known Issues & Solutions

### Issue: Hour Text Out of Bounds
**Symptoms**: Hour number cut off at screen edges (especially 15-45 minutes)
**Root Cause**: Insufficient inset from rim for text dimensions
**Solution**: 
```mc
// BEFORE (broken): rimRadius - 15
// AFTER (fixed):   rimRadius - 35
var handRadius = rimRadius - 35;  // Accounts for text width
```
**Verification**:
```bash
ustad check success --claimed --evidence "text visible at all positions" --expected "no cutoff"
```

### Issue: Simulator Shows Old Code
**Symptoms**: Changes don't appear in simulator
**Root Cause**: Simulator caching old build
**Solution**: Kill all simulators, rebuild, launch fresh
**Verification**:
```bash
ustad check hallucination "simulator shows latest" --facts "rebuilt after changes"
```

## 📚 GH-LEARN Integration for Knowledge Capture

### Capture Patterns That Work
```bash
# After successful implementation
echo '{"pattern": "circular-time-display", "device": "fenix7", "works": true}' > pattern.json
gh-learn add --kind success_pattern --body @pattern.json --tags garmin monkeyc watchface

# After fixing a bug
echo '{"bug": "text-cutoff", "fix": "increase rim inset to 35"}' > fix.json
gh-learn add --kind bug_fix --body @fix.json --tags garmin display bounds

# After optimization
echo '{"optimization": "AOD ghost mode", "battery_saving": "70%"}' > opt.json
gh-learn add --kind performance --body @opt.json --tags garmin battery AOD
```

### Before Starting New Work
```bash
# Check for existing patterns
gh-learn scaffold --plan "implement Garmin watch face feature" --provider claude

# Apply proven patterns
gh-learn scaffold --apply "garmin mood system" --branch feat/mood

# Sync learnings
gh-learn sync --once
```

## 🔧 Development Commands

### Quick Reference with Verification
```bash
# Build & test cycle WITH VERIFICATION
ustad check hallucination "changes ready" --facts "code saved" && \
pkill -f simulator && \
monkeyc -d fenix7 -f monkey.jungle -o build/test.prg -y developer_key.der && \
monkeydo build/test.prg fenix7 && \
sleep 3 && \
screencapture -x /tmp/test_$(date +%s).png && \
ustad check success --claimed --evidence "screenshot captured" --expected "feature works"

# Check simulator output
ps aux | grep -i simulator

# Git workflow with atomic commits
git add -A && \
ustad check hallucination "ready to commit" --facts "tests pass" && \
git commit -m "fix: [description]"
```

## 💰 Cost-Effective CLI Usage

### For MonkeyC Development
```bash
# Quick syntax check (low cost)
llm "Is this MonkeyC syntax correct: [code]" -m gpt-3.5-turbo

# Research Garmin APIs (free search)
tavily search "Garmin Connect IQ [API name] documentation"

# Complex debugging (only when needed)
llm "Debug this MonkeyC error with full analysis" -m gpt-5
```

## 📝 Commit Standards
- Use conventional commits: `fix:`, `feat:`, `docs:`, `refactor:`
- Test BEFORE committing
- Verify with ustad before claiming success
- Include verification evidence in PR descriptions
- Add "🤖 Generated with Claude Code" footer
- Capture learnings with gh-learn after significant changes

## ⚠️ DO NOT
- Change the hour-circles-rim time display concept
- Deploy without testing in simulator first
- Claim fixes work without screenshot proof AND ustad verification
- Modify AOD blink schedule without battery testing
- Ignore bounds checking on circular displays
- Skip ustad verification before making claims
- Implement complex features without checking complexity ratio
- Forget to capture successful patterns with gh-learn