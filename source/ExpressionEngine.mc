using Toybox.Lang;
using Toybox.System;
using Toybox.Graphics;

// Main orchestrator for the expression system
class ExpressionEngine {
    
    var _healthSource;
    var _ruleEngine;
    var _blinkController;
    var _currentState = null;
    var _lastUpdateSec = 0;
    
    function initialize() {
        _healthSource = new HealthDataSource();
        _ruleEngine = new RuleEngine();
        _blinkController = new BlinkController();
    }
    
    // Main update function - returns current expression state
    function update(isAwake) {
        var now = System.getClockTime();
        var currentSec = now.timeZoneOffset + now.dst;
        
        // Only update expression evaluation once per second
        if (currentSec != _lastUpdateSec) {
            _lastUpdateSec = currentSec;
            
            // Get current health snapshot
            var healthSnapshot = _healthSource.getSnapshot();
            
            // Evaluate and get expression state
            _currentState = _ruleEngine.evaluate(healthSnapshot);
        }
        
        // Always update blink state
        var currentMs = System.getTimer();
        var blinkPattern = _currentState != null ? _currentState.blinkPattern : BlinkPattern.NORMAL;
        var eyesClosed = _blinkController.update(currentMs, blinkPattern, isAwake);
        
        // Return current display state
        return {
            :expression => _currentState,
            :eyesClosed => eyesClosed
        };
    }
    
    // Draw the expression (simplified for now - just draws text)
    function drawExpression(dc, x, y, displayState) {
        if (displayState == null || displayState[:expression] == null) {
            return;
        }
        
        var expr = displayState[:expression];
        var eyesClosed = displayState[:eyesClosed];
        
        // For now, just draw the expression name and eye state
        // This will be replaced with actual eye/mouth rendering later
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var eyeChar = eyesClosed ? "- -" : getEyeCharacter(expr.eyes);
        var mouthChar = getMouthCharacter(expr.mouth);
        
        // Draw eyes
        dc.drawText(x, y - 20, Graphics.FONT_TINY, eyeChar, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw mouth
        dc.drawText(x, y + 10, Graphics.FONT_TINY, mouthChar, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Debug: Draw expression name
        dc.drawText(x, y + 30, Graphics.FONT_XTINY, ExpressionLibrary.getName(expr.id), Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Get simple text representation of eyes
    private function getEyeCharacter(eyeType) {
        switch(eyeType) {
            case EyeType.NORMAL: return "O O";
            case EyeType.TIRED: return "- -";
            case EyeType.ALERT: return "O O";
            case EyeType.HAPPY: return "^ ^";
            case EyeType.STRESSED: return "> <";
            case EyeType.FOCUSED: return "o o";
            default: return "O O";
        }
    }
    
    // Get simple text representation of mouth
    private function getMouthCharacter(mouthType) {
        switch(mouthType) {
            case MouthType.NEUTRAL: return "___";
            case MouthType.SMILE: return "\\__/";
            case MouthType.FROWN: return "/--\\";
            case MouthType.OPEN: return "O";
            case MouthType.DETERMINED: return "===";
            default: return "___";
        }
    }
    
    // Get debug information
    function getDebugInfo() {
        var healthDebug = _healthSource.getDebugString();
        var ruleDebug = _ruleEngine.getDebugString();
        return healthDebug + "\n" + ruleDebug;
    }
}