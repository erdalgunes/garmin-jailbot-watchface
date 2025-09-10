using Toybox.Lang;
using Toybox.System;
using Toybox.Math;

// Controls blinking animations based on expression patterns
class BlinkController {
    
    var _isBlinking = false;
    var _nextBlinkMs = 0;
    var _blinkStartMs = 0;
    var _currentPattern = BlinkPattern.NORMAL;
    var _blinkDuration = 120;  // Current blink duration in ms
    
    function initialize() {
        scheduleNextBlink(BlinkPattern.NORMAL);
    }
    
    // Update blink state and return whether eyes should be closed
    function update(currentTimeMs, newPattern, isAwake) {
        // Don't blink if not awake (AOD mode)
        if (!isAwake) {
            _isBlinking = false;
            return false;
        }
        
        // Update pattern if changed
        if (newPattern != _currentPattern) {
            _currentPattern = newPattern;
            var timing = ExpressionLibrary.getBlinkTiming(newPattern);
            _blinkDuration = timing[:duration];
            // Schedule next blink with new pattern
            scheduleNextBlink(newPattern);
        }
        
        // Check if we should start blinking
        if (!_isBlinking && currentTimeMs >= _nextBlinkMs) {
            _isBlinking = true;
            _blinkStartMs = currentTimeMs;
        }
        
        // Check if blink should end
        if (_isBlinking) {
            var blinkElapsed = currentTimeMs - _blinkStartMs;
            if (blinkElapsed >= _blinkDuration) {
                _isBlinking = false;
                scheduleNextBlink(_currentPattern);
            }
        }
        
        return _isBlinking;
    }
    
    // Schedule the next blink based on pattern
    private function scheduleNextBlink(pattern) {
        var timing = ExpressionLibrary.getBlinkTiming(pattern);
        var minInterval = timing[:minInterval];
        var maxInterval = timing[:maxInterval];
        
        // Random interval between min and max
        var interval = minInterval + Math.rand() % (maxInterval - minInterval);
        _nextBlinkMs = System.getTimer() + interval;
    }
    
    // Force a blink (useful for transitions or special events)
    function forceBlink() {
        _isBlinking = true;
        _blinkStartMs = System.getTimer();
    }
    
    // Reset blink state
    function reset() {
        _isBlinking = false;
        scheduleNextBlink(_currentPattern);
    }
    
    // Check if currently blinking
    function isBlinking() {
        return _isBlinking;
    }
}