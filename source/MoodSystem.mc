using Toybox.System;
using Toybox.Lang;

// SOLID Architecture for Jailbot Mood System
// Interface segregation - separate concerns

// Core mood state interface
class IMoodState {
    function id() {
        return "base";
    }
    
    function score(ctx) {
        return 0.0;
    }
    
    function enter(ctx) {
        // Override in subclasses
    }
    
    function exit(ctx) {
        // Override in subclasses  
    }
    
    function allowedVariants(ctx) {
        return ["base"];
    }
    
    function blinkProfile(ctx) {
        return {
            :min => 1.5,
            :max => 4.0, 
            :mean => 2.5,
            :doubleProb => 0.1,
            :closureMs => 120
        };
    }
    
    function aodExpression(ctx) {
        return {
            :eyeWidth => 1.0,
            :eyeHeight => 0.5, // Half-closed for AOD
            :mouthWidth => 1.0,
            :mouthCurve => 0.0
        };
    }
    
    function getExpression(ctx, variant) {
        return {
            :eyeWidth => 1.0,
            :eyeHeight => 1.0,
            :eyeRadius => 0.3,
            :mouthWidth => 1.0,
            :mouthHeight => 0.3,
            :mouthCurve => 0.0,
            :color => Graphics.COLOR_GREEN,
            :accent => false
        };
    }
    
    function getEmoticon() {
        return ":|"; // Default neutral emoticon
    }
}

// Health data context container
class MoodContext {
    var energy;      // 0-1 (Body Battery normalized)
    var stressLevel; // 0-1 (Stress normalized)
    var stepProgress; // 0-1+ (steps today / goal, time-adjusted)
    var hrAnomaly;   // HR above resting baseline
    var inActivity; // boolean
    var postActivity30; // boolean - within 30 min of activity
    var achievementEvent; // boolean - goal reached or activity completed
    var sleepQuality; // 0-1 
    var recoveryNeed; // boolean
    var focusContext; // boolean
    var overloadRisk; // boolean
    var aod; // boolean - always on display mode
    
    function initialize(sensors) {
        self.energy = clamp01(sensors[:bodyBattery] / 100.0);
        self.stressLevel = clamp01(sensors[:stress] / 100.0);
        
        var stepGoal = sensors[:stepGoal] > 0 ? sensors[:stepGoal] : 10000;
        var timeAdjustedGoal = getTimeAdjustedGoal(stepGoal);
        self.stepProgress = sensors[:steps].toFloat() / timeAdjustedGoal;
        
        self.hrAnomaly = sensors[:heartRate] - sensors[:restingHR];
        self.inActivity = sensors[:inActivity];
        self.postActivity30 = sensors[:postActivity30];
        self.achievementEvent = sensors[:achievementEvent];
        self.sleepQuality = sensors[:sleepQuality];
        self.aod = sensors[:aod];
        
        // Derived states
        self.recoveryNeed = (self.energy < 0.35) && self.postActivity30;
        self.focusContext = self.inActivity || 
            ((self.stressLevel >= 0.35 && self.stressLevel <= 0.6) && self.hrAnomaly > 8);
        self.overloadRisk = (self.stressLevel > 0.7) && (self.hrAnomaly > 12) && !self.inActivity;
    }
    
    private function clamp01(value) {
        if (value < 0) { return 0.0; }
        if (value > 1) { return 1.0; }
        return value.toFloat();
    }
    
    private function getTimeAdjustedGoal(goal) {
        var now = System.getClockTime();
        var hour = now.hour;
        
        // Before noon: expect 50% of daily goal
        if (hour < 12) {
            return goal * 0.5;
        }
        return goal; // Full goal after noon
    }
}

// 6 Core Emotional States
class VictoryState extends IMoodState {
    function id() { return "victory"; }
    
    function score(ctx) {
        return ctx.achievementEvent ? 1.0 : 0.0;
    }
    
    function blinkProfile(ctx) {
        return {
            :min => 2.0,
            :max => 4.0,
            :mean => 3.0,
            :doubleProb => 0.1,
            :closureMs => 80
        };
    }
    
    function getExpression(ctx, variant) {
        return {
            :eyeWidth => 1.2, // Wider excited eyes
            :eyeHeight => 1.3, 
            :eyeRadius => 0.4,
            :mouthWidth => 1.4, // Big grin
            :mouthHeight => 0.4,
            :mouthCurve => 0.3, // Upward curve
            :color => Graphics.COLOR_GREEN,
            :accent => true // Pulse effect
        };
    }
    
    function getEmoticon() {
        return ":D"; // Victory grin emoticon
    }
}

class OverheatState extends IMoodState {
    function id() { return "overheat"; }
    
    function score(ctx) {
        if (ctx.overloadRisk) { return 0.9; }
        if (ctx.stressLevel > 0.8) { return 0.8; }
        return 0.0;
    }
    
    function blinkProfile(ctx) {
        return {
            :min => 1.2,
            :max => 3.0,
            :mean => 2.0,
            :doubleProb => 0.15, // Frequent double blinks when stressed
            :closureMs => 120
        };
    }
    
    function getExpression(ctx, variant) {
        return {
            :eyeWidth => 0.8, // Narrowed tense eyes
            :eyeHeight => 1.2, // Taller
            :eyeRadius => 0.2, // More angular
            :mouthWidth => 0.8,
            :mouthHeight => 0.4,
            :mouthCurve => -0.2, // Slight frown
            :color => Graphics.COLOR_GREEN,
            :accent => false
        };
    }
    
    function getEmoticon() {
        return ">:("; // Angry/stressed emoticon
    }
}

class DrowsyState extends IMoodState {
    function id() { return "drowsy"; }
    
    function score(ctx) {
        if (ctx.energy < 0.3) { return 0.7; }
        if (ctx.sleepQuality < 0.4 && ctx.energy < 0.5) { return 0.6; }
        return 0.0;
    }
    
    function blinkProfile(ctx) {
        return {
            :min => 4.5,
            :max => 8.0,
            :mean => 6.0,
            :doubleProb => 0.0,
            :closureMs => 150 // Longer, slower blinks
        };
    }
    
    function allowedVariants(ctx) {
        var variants = ["base"];
        if (ctx.energy < 0.25) {
            variants.add("yawn");
        }
        return variants;
    }
    
    function getExpression(ctx, variant) {
        if (variant.equals("yawn")) {
            return {
                :eyeWidth => 1.0,
                :eyeHeight => 0.6, // Droopy
                :eyeRadius => 0.4,
                :mouthWidth => 0.6,
                :mouthHeight => 0.8, // Tall O for yawn
                :mouthCurve => 0.0,
                :color => Graphics.COLOR_GREEN,
                :accent => false
            };
        }
        
        return {
            :eyeWidth => 1.1, // Slightly wider but droopy
            :eyeHeight => 0.7, // Half-closed sleepy look
            :eyeRadius => 0.4,
            :mouthWidth => 0.8,
            :mouthHeight => 0.2, // Small flat mouth
            :mouthCurve => 0.0,
            :color => Graphics.COLOR_GREEN,
            :accent => false
        };
    }
    
    function getEmoticon() {
        return "-_-"; // Sleepy/drowsy emoticon
    }
}

class RecoveringState extends IMoodState {
    function id() { return "recovering"; }
    
    function score(ctx) {
        if (ctx.recoveryNeed) { return 0.8; }
        if (ctx.postActivity30 && ctx.energy < 0.55) { return 0.7; }
        return 0.0;
    }
    
    function blinkProfile(ctx) {
        return {
            :min => 3.5,
            :max => 7.0,
            :mean => 4.8,
            :doubleProb => 0.0,
            :closureMs => 100
        };
    }
    
    function getExpression(ctx, variant) {
        return {
            :eyeWidth => 1.0,
            :eyeHeight => 0.8, // Relaxed, slightly closed
            :eyeRadius => 0.3,
            :mouthWidth => 1.0,
            :mouthHeight => 0.3,
            :mouthCurve => 0.1, // Gentle smile
            :color => Graphics.COLOR_GREEN,
            :accent => false
        };
    }
    
    function getEmoticon() {
        return ":)"; // Gentle recovery smile
    }
}

class FocusedState extends IMoodState {
    function id() { return "focused"; }
    
    function score(ctx) {
        if (ctx.focusContext && ctx.energy > 0.35) { return 0.7; }
        return 0.0;
    }
    
    function blinkProfile(ctx) {
        return {
            :min => 2.5,
            :max => 6.0,
            :mean => 3.8,
            :doubleProb => 0.0,
            :closureMs => 90
        };
    }
    
    function getExpression(ctx, variant) {
        return {
            :eyeWidth => 0.8, // Narrowed, concentrated
            :eyeHeight => 0.9,
            :eyeRadius => 0.2,
            :mouthWidth => 1.0,
            :mouthHeight => 0.2, // Firm, determined line
            :mouthCurve => 0.0,
            :color => Graphics.COLOR_GREEN,
            :accent => false
        };
    }
    
    function getEmoticon() {
        return ":|)"; // Focused/determined expression
    }
}

class ChargedState extends IMoodState {
    function id() { return "charged"; }
    
    function score(ctx) {
        if (ctx.energy > 0.65 && ctx.stressLevel < 0.45 && ctx.stepProgress > 0.5) {
            return 0.6;
        }
        return 0.0;
    }
    
    function blinkProfile(ctx) {
        return {
            :min => 2.0,
            :max => 5.0,
            :mean => 3.0,
            :doubleProb => 0.1, // Playful double blinks
            :closureMs => 85
        };
    }
    
    function getExpression(ctx, variant) {
        return {
            :eyeWidth => 1.1, // Bright, alert
            :eyeHeight => 1.1,
            :eyeRadius => 0.4,
            :mouthWidth => 1.2, // Happy smile
            :mouthHeight => 0.3,
            :mouthCurve => 0.2,
            :color => Graphics.COLOR_GREEN,
            :accent => false
        };
    }
    
    function getEmoticon() {
        return "^_^"; // Happy energetic emoticon
    }
}

class StandbyState extends IMoodState {
    function id() { return "standby"; }
    
    function score(ctx) {
        return 0.1; // Default/fallback state
    }
    
    // Uses default blinkProfile and getExpression from IMoodState
}