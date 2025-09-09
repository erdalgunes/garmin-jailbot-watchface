using Toybox.System;
using Toybox.Lang;
using Toybox.Math;

// Central mood orchestration - SOLID Single Responsibility
class MoodEngine {
    private var states;
    private var currentState;
    private var stateMemory;
    private var blinkScheduler;
    private var expressionRenderer;
    private var emoticonRenderer;
    private var lastUpdateTime;
    private var stateCooldowns;
    
    function initialize() {
        // Initialize all mood states
        self.states = [
            new VictoryState(),      // Highest priority
            new OverheatState(), 
            new DrowsyState(),
            new RecoveringState(),
            new FocusedState(),
            new ChargedState(),
            new StandbyState()       // Lowest priority (fallback)
        ];
        
        self.currentState = self.states[self.states.size() - 1]; // Start with Standby
        self.stateMemory = new MoodMemory();
        self.blinkScheduler = new BlinkScheduler();
        self.expressionRenderer = new ExpressionRenderer();
        self.emoticonRenderer = new EmoticonRenderer();
        self.lastUpdateTime = System.getTimer();
        self.stateCooldowns = {};
        
        // Initialize cooldowns
        for (var i = 0; i < self.states.size(); i++) {
            self.stateCooldowns[self.states[i].id()] = 0;
        }
    }
    
    function update(rawSensors) {
        var ctx = new MoodContext(rawSensors);
        var now = System.getTimer();
        var deltaMs = now - self.lastUpdateTime;
        self.lastUpdateTime = now;
        
        // Update cooldowns
        self.updateCooldowns(deltaMs);
        
        // Select new state based on scores and priorities
        var newState = self.selectState(ctx);
        
        // Handle state transitions
        if (newState.id() != self.currentState.id()) {
            self.transitionToState(newState, ctx);
        }
        
        // Update blink scheduler
        self.blinkScheduler.update(self.currentState.blinkProfile(ctx), deltaMs);
        
        // Update memory
        self.stateMemory.update(ctx, deltaMs);
        
        return self.getRenderData(ctx);
    }
    
    private function selectState(ctx) {
        var bestState = null;
        var bestScore = -1.0;
        
        // Priority-based selection with hysteresis
        for (var i = 0; i < self.states.size(); i++) {
            var state = self.states[i];
            var stateId = state.id();
            
            // Skip if in cooldown
            if (self.stateCooldowns[stateId] > 0) {
                continue;
            }
            
            var score = state.score(ctx);
            
            // Apply hysteresis - current state gets small bonus to avoid flipping
            if (stateId.equals(self.currentState.id())) {
                score += 0.1;
            }
            
            // Priority order - earlier states in array have priority at equal scores
            if (score > bestScore || (score == bestScore && bestState == null)) {
                bestState = state;
                bestScore = score;
            }
        }
        
        return bestState != null ? bestState : self.states[self.states.size() - 1]; // Fallback to Standby
    }
    
    private function transitionToState(newState, ctx) {
        // Exit current state
        self.currentState.exit(ctx);
        
        // Enter new state
        newState.enter(ctx);
        
        // Set cooldown for previous state to prevent flip-flopping
        var prevStateId = self.currentState.id();
        if (!prevStateId.equals("victory")) { // Victory can be interrupted
            self.stateCooldowns[prevStateId] = self.getCooldownForState(prevStateId);
        }
        
        // Update current state
        self.currentState = newState;
        
        // Trigger transition blink
        self.blinkScheduler.triggerEventBlink();
        
        // Log transition for debugging
        System.println("Mood: " + prevStateId + " -> " + newState.id());
    }
    
    private function getCooldownForState(stateId) {
        // Different cooldown periods to prevent rapid state changes
        if (stateId.equals("victory")) { return 45000; }      // 45s
        if (stateId.equals("overheat")) { return 120000; }    // 2min
        if (stateId.equals("drowsy")) { return 180000; }      // 3min
        if (stateId.equals("recovering")) { return 150000; }  // 2.5min
        if (stateId.equals("focused")) { return 120000; }     // 2min
        if (stateId.equals("charged")) { return 90000; }      // 1.5min
        return 60000; // 1min default
    }
    
    private function updateCooldowns(deltaMs) {
        var keys = self.stateCooldowns.keys();
        for (var i = 0; i < keys.size(); i++) {
            var key = keys[i];
            if (self.stateCooldowns[key] > 0) {
                self.stateCooldowns[key] -= deltaMs;
                if (self.stateCooldowns[key] < 0) {
                    self.stateCooldowns[key] = 0;
                }
            }
        }
    }
    
    private function getRenderData(ctx) {
        // Select expression variant
        var allowedVariants = self.currentState.allowedVariants(ctx);
        var variant = self.stateMemory.selectVariant(allowedVariants, ctx);
        
        // Get expression parameters
        var expression = ctx.aod ? 
            self.currentState.aodExpression(ctx) : 
            self.currentState.getExpression(ctx, variant);
        
        // Add blink state
        var blinkPhase = self.blinkScheduler.getBlinkPhase();
        
        return {
            :state => self.currentState.id(),
            :variant => variant,
            :expression => expression,
            :blinkPhase => blinkPhase,
            :emoticon => self.currentState.getEmoticon(),
            :aod => ctx.aod
        };
    }
}

// Memory system for state persistence and variant selection
class MoodMemory {
    private var stateHistory;
    private var lastVariantTime;
    private var currentVariant;
    private var achievementEventTime;
    
    function initialize() {
        self.stateHistory = [];
        self.lastVariantTime = 0;
        self.currentVariant = "base";
        self.achievementEventTime = 0;
    }
    
    function update(ctx, deltaMs) {
        // Track achievement events
        if (ctx.achievementEvent) {
            self.achievementEventTime = System.getTimer();
        }
    }
    
    function selectVariant(allowedVariants, ctx) {
        // Simple variant selection - could be more sophisticated
        if (allowedVariants.size() == 1) {
            return allowedVariants[0];
        }
        
        // For drowsy state, occasionally show yawn
        if (allowedVariants.indexOf("yawn") != -1) {
            var now = System.getTimer();
            if (now - self.lastVariantTime > 60000) { // Once per minute max
                if (Math.rand() % 100 < 30) { // 30% chance
                    self.lastVariantTime = now;
                    return "yawn";
                }
            }
        }
        
        return allowedVariants[0]; // Default to first variant
    }
    
    function isAchievementEventRecent() {
        return (System.getTimer() - self.achievementEventTime) < 90000; // 90 seconds
    }
}

// Natural blinking system with realistic timing
class BlinkScheduler {
    private var nextBlinkTime;
    private var blinkStartTime;
    private var blinkDuration;
    private var isBlinking;
    private var currentProfile;
    private var eventBlinkPending;
    
    function initialize() {
        self.nextBlinkTime = 0;
        self.blinkStartTime = 0;
        self.blinkDuration = 100;
        self.isBlinking = false;
        self.currentProfile = null;
        self.eventBlinkPending = false;
        
        self.scheduleNextBlink(self.getDefaultProfile());
    }
    
    function update(profile, deltaMs) {
        self.currentProfile = profile;
        var now = System.getTimer();
        
        // Handle event blink (state transitions, wrist raise, etc.)
        if (self.eventBlinkPending) {
            self.startBlink(profile.get(:closureMs));
            self.eventBlinkPending = false;
            return;
        }
        
        // Check if it's time to blink
        if (!self.isBlinking && now >= self.nextBlinkTime) {
            self.startBlink(profile.get(:closureMs));
            
            // Check for double blink
            if (Math.rand() % 1000 < (profile.get(:doubleProb) * 1000)) {
                // Schedule second blink shortly after first completes
                self.nextBlinkTime = now + profile.get(:closureMs) + 80; // 80ms gap
            } else {
                self.scheduleNextBlink(profile);
            }
        }
        
        // Update current blink
        if (self.isBlinking && (now - self.blinkStartTime) >= self.blinkDuration) {
            self.isBlinking = false;
            // If we weren't doing a double blink, schedule the next normal blink
            if (self.nextBlinkTime <= now) {
                self.scheduleNextBlink(profile);
            }
        }
    }
    
    private function startBlink(duration) {
        self.isBlinking = true;
        self.blinkStartTime = System.getTimer();
        self.blinkDuration = duration;
    }
    
    private function scheduleNextBlink(profile) {
        // Generate natural blink interval using simplified log-normal distribution
        var min = profile.get(:min) * 1000;
        var max = profile.get(:max) * 1000;
        var mean = profile.get(:mean) * 1000;
        
        // Simple approximation of log-normal using uniform distribution
        var interval = self.generateBlinkInterval(min, max, mean);
        
        self.nextBlinkTime = System.getTimer() + interval;
    }
    
    private function generateBlinkInterval(min, max, mean) {
        // Simple weighted random between min and max, biased toward mean
        var range = max - min;
        var meanOffset = (mean - min) / range; // 0-1 position of mean in range
        
        var rand1 = Math.rand() % 1000 / 1000.0; // 0-1
        var rand2 = Math.rand() % 1000 / 1000.0; // 0-1
        
        // Bias toward mean using triangle distribution approximation
        var biased = rand1 < meanOffset ? 
            (Math.sqrt(rand1 * meanOffset) * meanOffset) :
            (1.0 - Math.sqrt((1.0 - rand1) * (1.0 - meanOffset)) * (1.0 - meanOffset));
        
        return min + (biased * range);
    }
    
    function triggerEventBlink() {
        self.eventBlinkPending = true;
    }
    
    function getBlinkPhase() {
        if (!self.isBlinking) {
            return 0.0; // Eyes fully open
        }
        
        var elapsed = System.getTimer() - self.blinkStartTime;
        var progress = elapsed.toFloat() / self.blinkDuration;
        
        if (progress >= 1.0) {
            return 0.0; // Blink complete
        }
        
        // Sine curve for natural eyelid motion - fast close, slower open
        return Math.sin(progress * Math.PI);
    }
    
    private function getDefaultProfile() {
        return {
            :min => 3.0,
            :max => 6.5,
            :mean => 4.2,
            :doubleProb => 0.0,
            :closureMs => 100
        };
    }
}

// Expression rendering with rounded rectangles
class ExpressionRenderer {
    function initialize() {
        // Constructor
    }
    
    function render(dc, renderData, faceSize, centerX, centerY) {
        var emoticon = renderData.get(:emoticon);
        var blinkPhase = renderData.get(:blinkPhase);
        var aod = renderData.get(:aod);
        
        // Use emoticon system if available
        if (emoticon != null) {
            self.renderWithEmoticon(dc, renderData, faceSize, centerX, centerY);
        } else {
            // Fallback to legacy expression system
            self.renderLegacy(dc, renderData, faceSize, centerX, centerY);
        }
    }
    
    function renderWithEmoticon(dc, renderData, faceSize, centerX, centerY) {
        var emoticon = renderData.get(:emoticon);
        var blinkPhase = renderData.get(:blinkPhase);
        
        // Create emoticon renderer and render the expression
        var emoticonRenderer = new EmoticonRenderer();
        emoticonRenderer.renderEmoticon(dc, emoticon, centerX, centerY, faceSize);
        
        // Apply blinking overlay if needed
        if (blinkPhase > 0.1) {
            self.applyBlinkOverlay(dc, centerX, centerY, faceSize, blinkPhase);
        }
    }
    
    function renderLegacy(dc, renderData, faceSize, centerX, centerY) {
        var expression = renderData.get(:expression);
        var blinkPhase = renderData.get(:blinkPhase);
        var aod = renderData.get(:aod);
        
        // Calculate sizes based on face size and expression parameters
        var eyeWidth = (faceSize / 5) * expression.get(:eyeWidth);
        var eyeHeight = (faceSize / 10) * expression.get(:eyeHeight);
        var eyeRadius = eyeHeight * expression.get(:eyeRadius);
        
        // Apply blinking - modify eye height
        var currentEyeHeight = eyeHeight * (1.0 - blinkPhase);
        
        // Eye positions
        var eyeY = centerY - faceSize / 8;
        var leftEyeX = centerX - faceSize / 6;
        var rightEyeX = centerX + faceSize / 6;
        
        // Draw eyes
        if (currentEyeHeight > 2) { // Don't draw if too small (fully blinked)
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(leftEyeX - eyeWidth/2, eyeY, eyeWidth, currentEyeHeight, eyeRadius);
            dc.fillRoundedRectangle(rightEyeX - eyeWidth/2, eyeY, eyeWidth, currentEyeHeight, eyeRadius);
        }
        
        // Draw mouth
        var mouthWidth = (faceSize / 2.5) * expression.get(:mouthWidth);
        var mouthHeight = (faceSize / 12) * expression.get(:mouthHeight);
        var mouthY = centerY + faceSize / 12;
        var mouthRadius = mouthHeight * 0.5;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, mouthRadius);
        
        // Add accent effects for special states
        if (expression.get(:accent) && !aod) {
            self.drawAccentEffects(dc, renderData.get(:state), centerX, centerY, faceSize);
        }
    }
    
    private function applyBlinkOverlay(dc, centerX, centerY, faceSize, blinkPhase) {
        // Apply blinking by drawing eyelids over existing eyes
        var eyeY = centerY - faceSize / 8;
        var leftEyeX = centerX - faceSize / 6;
        var rightEyeX = centerX + faceSize / 6;
        var eyeWidth = faceSize / 5;
        var eyeHeight = faceSize / 10;
        
        // Calculate eyelid height based on blink phase
        var eyelidHeight = eyeHeight * blinkPhase;
        
        if (eyelidHeight > 1) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(leftEyeX - eyeWidth/2, eyeY, eyeWidth, eyelidHeight);
            dc.fillRectangle(rightEyeX - eyeWidth/2, eyeY, eyeWidth, eyelidHeight);
        }
    }
    
    private function drawAccentEffects(dc, state, centerX, centerY, faceSize) {
        // Remove purple circle - clean design
        // No accent effects for now
    }
}