# CLAUDE.md - Jailbot Watch Face Project

## 🚨 CRITICAL: Anti-Hallucination Protocol

### MANDATORY VERIFICATION WORKFLOW
```bash
# BEFORE claiming ANY fix works:
1. pkill -f simulator                    # Kill ALL old instances
2. monkeyc -d fenix7 -f monkey.jungle -o build/test.prg -y developer_key.der
3. monkeydo build/test.prg fenix7        # Run fresh build
4. sleep 3                                # Wait for UI
5. screencapture -x /tmp/verify.png      # Capture proof
6. VISUALLY VERIFY the fix in screenshot
7. Only THEN claim success
```

**RED FLAGS OF HALLUCINATION:**
- Pointing to old screenshots as "proof"
- Not rebuilding after changes
- Assuming simulator is showing latest code
- Claiming "it should work" without verification

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

## 📋 Testing Protocols

### Simulator Testing Checklist
- [ ] Kill all existing simulators
- [ ] Build with latest code
- [ ] Launch fresh simulator instance
- [ ] Test at critical minutes: :00, :15, :30, :45
- [ ] Verify text stays within bounds at all positions
- [ ] Screenshot evidence of working state
- [ ] Test mood transitions (Victory, Drowsy, etc.)
- [ ] Verify AOD mode functionality

### Device Testing (FR965)
```bash
# Deployment workflow
pkill -f "Garmin Express"  # MUST close first
monkeyc -d fenix7 -f monkey.jungle -o deploy.prg -y developer_key.der
/opt/homebrew/bin/mtp-sendfile deploy.prg 16777231

# Verify deployment
/opt/homebrew/bin/mtp-files | grep -i jailbot
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

### Issue: Simulator Shows Old Code
**Symptoms**: Changes don't appear in simulator
**Root Cause**: Simulator caching old build
**Solution**: Kill all simulators, rebuild, launch fresh

## 🔧 Development Commands

### Quick Reference
```bash
# Build & test cycle
pkill -f simulator && \
monkeyc -d fenix7 -f monkey.jungle -o build/test.prg -y developer_key.der && \
monkeydo build/test.prg fenix7

# Screenshot for verification
screencapture -x /tmp/test_$(date +%s).png

# Check simulator output
ps aux | grep -i simulator

# Git workflow
git add -A && git commit -m "fix: [description]"
```

## 📝 Commit Standards
- Use conventional commits: `fix:`, `feat:`, `docs:`, `refactor:`
- Test BEFORE committing
- Include verification evidence in PR descriptions
- Add "🤖 Generated with Claude Code" footer

## ⚠️ DO NOT
- Change the hour-circles-rim time display concept
- Deploy without testing in simulator first
- Claim fixes work without screenshot proof
- Modify AOD blink schedule without battery testing
- Ignore bounds checking on circular displays