using Toybox.Lang;
using Toybox.System;

// Expression state tracking
class ExpressionState {
    var id;                    // Current expression ID
    var eyes;                  // Eye type
    var mouth;                 // Mouth type
    var blinkPattern;          // Blink pattern
    var priority;              // Expression priority
    var minDurationSec;        // Minimum duration in seconds
    var startTimeSec;          // When this expression started (epoch seconds)
    
    function initialize(expressionId, epochSec) {
        var data = ExpressionLibrary.get(expressionId);
        self.id = expressionId;
        self.eyes = data[:eyes];
        self.mouth = data[:mouth];
        self.blinkPattern = data[:blink];
        self.priority = data[:priority];
        self.minDurationSec = data[:minDur];
        self.startTimeSec = epochSec;
    }
    
    // Check if minimum duration has elapsed
    function canTransition(currentEpochSec) {
        var elapsed = currentEpochSec - startTimeSec;
        return elapsed >= minDurationSec;
    }
}

// Configuration constants for health thresholds
module ExprConfig {
    const BODY_BATT_LOW = 20;      // Body battery threshold for tired
    const STRESS_HIGH = 70;        // Stress threshold for stressed expression
    const HR_ZONE_FOCUSED = 4;     // HR zone for focused expression (zones 4-5)
    const MOVE_BAR_ALERT = 4;      // Move bar level for alert expression
    const GOAL_DONE = 100;         // Step goal percentage for happy
}

// Rule engine to evaluate health data and select expressions
class RuleEngine {
    
    var _currentState = null;
    
    function initialize() {
        // Start with REST expression
        _currentState = new ExpressionState(ExpressionId.REST, System.getClockTime().timeZoneOffset + System.getClockTime().dst);
    }
    
    // Main evaluation function
    function evaluate(healthSnapshot) {
        var now = System.getClockTime();
        var epochSec = now.timeZoneOffset + now.dst;
        
        // Find the best expression based on current health data
        var bestExpression = findBestExpression(healthSnapshot);
        
        // Apply hysteresis to prevent flickering
        if (shouldKeepCurrent(bestExpression, epochSec)) {
            return _currentState;
        }
        
        // Transition to new expression
        _currentState = new ExpressionState(bestExpression[:id], epochSec);
        return _currentState;
    }
    
    // Find the highest priority expression that matches current health state
    private function findBestExpression(snapshot) {
        var candidates = [];
        
        // Check each condition and add matching expressions
        
        // FOCUSED: High intensity workout (HR Zone 4-5)
        if (snapshot.hrZone >= ExprConfig.HR_ZONE_FOCUSED) {
            candidates.add({
                :id => ExpressionId.FOCUSED,
                :priority => ExpressionLibrary.get(ExpressionId.FOCUSED)[:priority]
            });
        }
        
        // STRESSED: High stress level
        if (snapshot.stress >= ExprConfig.STRESS_HIGH) {
            candidates.add({
                :id => ExpressionId.STRESSED,
                :priority => ExpressionLibrary.get(ExpressionId.STRESSED)[:priority]
            });
        }
        
        // TIRED: Low body battery
        if (snapshot.bodyBattery >= 0 && snapshot.bodyBattery <= ExprConfig.BODY_BATT_LOW) {
            candidates.add({
                :id => ExpressionId.TIRED,
                :priority => ExpressionLibrary.get(ExpressionId.TIRED)[:priority]
            });
        }
        
        // ALERT: Need to move (high move bar)
        if (snapshot.moveBar >= ExprConfig.MOVE_BAR_ALERT) {
            candidates.add({
                :id => ExpressionId.ALERT,
                :priority => ExpressionLibrary.get(ExpressionId.ALERT)[:priority]
            });
        }
        
        // HAPPY: Goal achieved
        if (snapshot.stepGoalPercent >= ExprConfig.GOAL_DONE) {
            candidates.add({
                :id => ExpressionId.HAPPY,
                :priority => ExpressionLibrary.get(ExpressionId.HAPPY)[:priority]
            });
        }
        
        // If no special conditions, use REST
        if (candidates.size() == 0) {
            return {
                :id => ExpressionId.REST,
                :priority => ExpressionLibrary.get(ExpressionId.REST)[:priority]
            };
        }
        
        // Find highest priority expression
        var best = candidates[0];
        for (var i = 1; i < candidates.size(); i++) {
            if (candidates[i][:priority] > best[:priority]) {
                best = candidates[i];
            }
        }
        
        return best;
    }
    
    // Determine if we should keep the current expression (hysteresis)
    private function shouldKeepCurrent(newCandidate, epochSec) {
        if (_currentState == null) {
            return false;
        }
        
        // Check if minimum duration has elapsed
        if (!_currentState.canTransition(epochSec)) {
            // Only override if new expression is critically important (20+ priority jump)
            var priorityJump = newCandidate[:priority] - _currentState.priority;
            return priorityJump < 20;
        }
        
        // Minimum duration elapsed, allow transition
        return false;
    }
    
    // Get current expression state
    function getCurrentState() {
        return _currentState;
    }
    
    // Get debug string for current state
    function getDebugString() {
        if (_currentState == null) {
            return "No expression";
        }
        return ExpressionLibrary.getName(_currentState.id) + " (P:" + _currentState.priority + ")";
    }
}