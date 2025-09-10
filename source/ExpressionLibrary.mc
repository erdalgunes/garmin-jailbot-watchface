using Toybox.Lang;

// Expression IDs
module ExpressionId {
    const REST = 0;
    const HAPPY = 1;
    const STRESSED = 2;
    const TIRED = 3;
    const FOCUSED = 4;
    const ALERT = 5;
}

// Eye types for expressions
module EyeType {
    const NORMAL = 0;    // O O
    const TIRED = 1;     // - -
    const ALERT = 2;     // O O (wider)
    const HAPPY = 3;     // ^ ^
    const STRESSED = 4;  // > <
    const FOCUSED = 5;   // o o
    const CLOSED = 6;    // _ _ (for blinking)
}

// Mouth types for expressions
module MouthType {
    const NEUTRAL = 0;     // ___
    const SMILE = 1;       // \___/
    const FROWN = 2;       // /---\
    const OPEN = 3;        // O
    const DETERMINED = 4;  // ===
}

// Blink patterns
module BlinkPattern {
    const NORMAL = 0;    // 3-6 sec interval, 120ms duration
    const TIRED = 1;     // 2-4 sec interval, 200ms duration  
    const STRESSED = 2;  // 0.8-1.6 sec interval, 80ms duration
    const RESTING = 3;   // 6-10 sec interval, 120ms duration
}

// Single source of truth for all expression definitions
class ExpressionLibrary {
    
    // Get expression data by ID
    static function get(id) {
        switch(id) {
            case ExpressionId.REST:
                return {
                    :eyes => EyeType.NORMAL,
                    :mouth => MouthType.NEUTRAL,
                    :blink => BlinkPattern.NORMAL,
                    :minDur => 5,      // minimum duration in seconds
                    :priority => 10    // lowest priority
                };
                
            case ExpressionId.HAPPY:
                return {
                    :eyes => EyeType.HAPPY,
                    :mouth => MouthType.SMILE,
                    :blink => BlinkPattern.NORMAL,
                    :minDur => 8,
                    :priority => 50
                };
                
            case ExpressionId.STRESSED:
                return {
                    :eyes => EyeType.STRESSED,
                    :mouth => MouthType.FROWN,
                    :blink => BlinkPattern.STRESSED,
                    :minDur => 10,
                    :priority => 80
                };
                
            case ExpressionId.TIRED:
                return {
                    :eyes => EyeType.TIRED,
                    :mouth => MouthType.NEUTRAL,
                    :blink => BlinkPattern.TIRED,
                    :minDur => 10,
                    :priority => 70
                };
                
            case ExpressionId.FOCUSED:
                return {
                    :eyes => EyeType.FOCUSED,
                    :mouth => MouthType.DETERMINED,
                    :blink => BlinkPattern.RESTING,
                    :minDur => 15,
                    :priority => 90    // highest priority
                };
                
            case ExpressionId.ALERT:
                return {
                    :eyes => EyeType.ALERT,
                    :mouth => MouthType.NEUTRAL,
                    :blink => BlinkPattern.NORMAL,
                    :minDur => 6,
                    :priority => 60
                };
                
            default:
                // Default to REST expression
                return get(ExpressionId.REST);
        }
    }
    
    // Get blink timing parameters for a pattern
    static function getBlinkTiming(pattern) {
        switch(pattern) {
            case BlinkPattern.NORMAL:
                return {
                    :minInterval => 3000,   // 3 seconds
                    :maxInterval => 6000,   // 6 seconds
                    :duration => 120        // 120ms blink
                };
                
            case BlinkPattern.TIRED:
                return {
                    :minInterval => 2000,   // 2 seconds
                    :maxInterval => 4000,   // 4 seconds
                    :duration => 200        // 200ms slower blink
                };
                
            case BlinkPattern.STRESSED:
                return {
                    :minInterval => 800,    // 0.8 seconds
                    :maxInterval => 1600,   // 1.6 seconds
                    :duration => 80         // 80ms quick blink
                };
                
            case BlinkPattern.RESTING:
                return {
                    :minInterval => 6000,   // 6 seconds
                    :maxInterval => 10000,  // 10 seconds
                    :duration => 120        // 120ms blink
                };
                
            default:
                return getBlinkTiming(BlinkPattern.NORMAL);
        }
    }
    
    // Get expression name for debugging
    static function getName(id) {
        switch(id) {
            case ExpressionId.REST: return "Rest";
            case ExpressionId.HAPPY: return "Happy";
            case ExpressionId.STRESSED: return "Stressed";
            case ExpressionId.TIRED: return "Tired";
            case ExpressionId.FOCUSED: return "Focused";
            case ExpressionId.ALERT: return "Alert";
            default: return "Unknown";
        }
    }
}