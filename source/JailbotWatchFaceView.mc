using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Math;

class JailbotWatchFaceView extends WatchUi.WatchFace {
    
    var inAOD = false;
    var updateTimer;
    
    // Simple blink state (kept for AOD mode)
    var isBlinking = false;
    var nextBlinkTime = 0;
    var blinkStartTime = 0;
    var blinkDuration = 150; // milliseconds
    
    // Expression system
    var expressionEngine = null;
    
    function initialize() {
        WatchFace.initialize();
        updateTimer = new Timer.Timer();
        scheduleNextBlink();
        
        // Initialize expression system
        try {
            expressionEngine = new ExpressionEngine();
        } catch (e) {
            // Graceful fallback if expression system fails
            System.println("Expression system init failed: " + e.getErrorMessage());
            expressionEngine = null;
        }
    }

    function onLayout(dc) {
        // Simple layout - no complex components needed
    }

    function onShow() {
        // Update every second for blinking
        updateTimer.start(method(:requestUpdate), 1000, true);
    }

    function onUpdate(dc) {
        inAOD = false;
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Update blink state
        updateBlinkState();
        
        // Draw the watch face
        drawSimpleJailbot(dc, width, height);
    }
    
    function onPartialUpdate(dc) {
        inAOD = true;
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Simple AOD - just time, no face
        drawSimpleAOD(dc, width, height);
    }

    function onHide() {
        updateTimer.stop();
    }
    
    function requestUpdate() {
        WatchUi.requestUpdate();
    }

    function onExitSleep() {}
    function onEnterSleep() {}
    
    // Simple blink logic
    function updateBlinkState() {
        var now = System.getTimer();
        
        // Check if we should start blinking
        if (!isBlinking && now >= nextBlinkTime) {
            isBlinking = true;
            blinkStartTime = now;
            scheduleNextBlink();
        }
        
        // Check if blink should end
        if (isBlinking && (now - blinkStartTime) >= blinkDuration) {
            isBlinking = false;
        }
    }
    
    function scheduleNextBlink() {
        // Random interval between 2-6 seconds
        var interval = 2000 + (Math.rand() % 4000);
        nextBlinkTime = System.getTimer() + interval;
    }
    
    function drawSimpleJailbot(dc, width, height) {
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get time
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var minutes = clockTime.min;
        
        // Device rim radius
        var rimRadius = (width < height ? width : height) / 2 - 8;
        
        // 1. Draw minute markers on rim
        drawMinuteMarkers(dc, centerX, centerY, rimRadius);
        
        // 2. Draw simple Jailbot face with blinking
        drawJailbotFace(dc, centerX, centerY, width * 0.7);
        
        // 3. Draw hour number at minute position
        drawHourAtMinutePosition(dc, centerX, centerY, rimRadius, hours, minutes);
    }
    
    function drawMinuteMarkers(dc, centerX, centerY, rimRadius) {
        for (var i = 0; i < 60; i++) {
            var angle = i * Math.PI / 30.0;
            var markerX = centerX + Math.sin(angle) * rimRadius;
            var markerY = centerY - Math.cos(angle) * rimRadius;
            
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            
            if (i % 5 == 0) {
                // Major markers (hours)
                if (i == 0) {
                    // 12 o'clock marker - slightly larger
                    dc.fillCircle(markerX, markerY, 3);
                } else {
                    dc.fillCircle(markerX, markerY, 2);
                }
            } else {
                // Minor markers (minutes)
                dc.fillCircle(markerX, markerY, 1);
            }
        }
    }
    
    function drawJailbotFace(dc, centerX, centerY, faceSize) {
        // If expression engine is available, use it for expressions
        if (expressionEngine != null) {
            var displayState = expressionEngine.update(!inAOD);
            
            // Draw expression face
            drawExpressionFace(dc, centerX, centerY, faceSize, displayState);
            
            // Debug info (can be removed later)
            //dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            //dc.drawText(centerX, centerY + faceSize/2, Graphics.FONT_XTINY, expressionEngine.getDebugInfo(), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Fallback to simple face
            drawSimpleFace(dc, centerX, centerY, faceSize);
        }
    }
    
    function drawExpressionFace(dc, centerX, centerY, faceSize, displayState) {
        if (displayState == null || displayState[:expression] == null) {
            drawSimpleFace(dc, centerX, centerY, faceSize);
            return;
        }
        
        var expr = displayState[:expression];
        var eyesClosed = displayState[:eyesClosed];
        
        // Eyes position
        var eyeWidth = faceSize / 5;
        var eyeHeight = faceSize / 10;
        var eyeY = centerY - faceSize / 8;
        var leftEyeX = centerX - faceSize / 6;
        var rightEyeX = centerX + faceSize / 6;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        // Draw eyes based on expression and blink state
        if (eyesClosed) {
            // Closed eyes (blinking)
            var lineThickness = 3;
            var lineY = eyeY + eyeHeight / 2;
            dc.fillRectangle(leftEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
            dc.fillRectangle(rightEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
        } else {
            // Draw expression-specific eyes
            drawExpressionEyes(dc, expr.eyes, leftEyeX, rightEyeX, eyeY, eyeWidth, eyeHeight);
        }
        
        // Draw expression-specific mouth
        var mouthY = centerY + faceSize / 12;
        drawExpressionMouth(dc, expr.mouth, centerX, mouthY, faceSize);
    }
    
    function drawExpressionEyes(dc, eyeType, leftX, rightX, y, width, height) {
        switch(eyeType) {
            case EyeType.NORMAL:
            case EyeType.ALERT:
                // Normal round eyes
                dc.fillRoundedRectangle(leftX - width/2, y, width, height, 4);
                dc.fillRoundedRectangle(rightX - width/2, y, width, height, 4);
                break;
                
            case EyeType.TIRED:
                // Half-closed eyes
                dc.fillRectangle(leftX - width/2, y + height/2, width, height/2);
                dc.fillRectangle(rightX - width/2, y + height/2, width, height/2);
                break;
                
            case EyeType.HAPPY:
                // Arc eyes (^ ^)
                dc.drawArc(leftX, y + height/2, width/2, 0, 180);
                dc.drawArc(rightX, y + height/2, width/2, 0, 180);
                break;
                
            case EyeType.STRESSED:
                // Angled eyes (> <)
                for (var i = 0; i < 3; i++) {
                    dc.drawLine(leftX - width/2 + i, y, leftX + width/2 - i, y + height);
                    dc.drawLine(rightX - width/2 + i, y + height, rightX + width/2 - i, y);
                }
                break;
                
            case EyeType.FOCUSED:
                // Small round eyes
                dc.fillCircle(leftX, y + height/2, width/3);
                dc.fillCircle(rightX, y + height/2, width/3);
                break;
                
            default:
                // Default to normal eyes
                dc.fillRoundedRectangle(leftX - width/2, y, width, height, 4);
                dc.fillRoundedRectangle(rightX - width/2, y, width, height, 4);
        }
    }
    
    function drawExpressionMouth(dc, mouthType, centerX, mouthY, faceSize) {
        var mouthWidth = faceSize / 2.5;
        var mouthHeight = faceSize / 12;
        
        switch(mouthType) {
            case MouthType.NEUTRAL:
                // Straight line
                dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, 4);
                break;
                
            case MouthType.SMILE:
                // Curved smile
                dc.drawArc(centerX, mouthY - mouthHeight, mouthWidth/2, 20, 160);
                dc.drawArc(centerX, mouthY - mouthHeight + 1, mouthWidth/2, 20, 160);
                dc.drawArc(centerX, mouthY - mouthHeight + 2, mouthWidth/2, 20, 160);
                break;
                
            case MouthType.FROWN:
                // Curved frown
                dc.drawArc(centerX, mouthY + mouthHeight*2, mouthWidth/2, 200, 340);
                dc.drawArc(centerX, mouthY + mouthHeight*2 - 1, mouthWidth/2, 200, 340);
                dc.drawArc(centerX, mouthY + mouthHeight*2 - 2, mouthWidth/2, 200, 340);
                break;
                
            case MouthType.OPEN:
                // Open circle
                dc.fillCircle(centerX, mouthY + mouthHeight/2, mouthHeight);
                break;
                
            case MouthType.DETERMINED:
                // Thick straight line
                dc.fillRectangle(centerX - mouthWidth/2, mouthY - 1, mouthWidth, mouthHeight + 2);
                break;
                
            default:
                // Default to neutral
                dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, 4);
        }
    }
    
    function drawSimpleFace(dc, centerX, centerY, faceSize) {
        // Original simple face code (fallback)
        var eyeWidth = faceSize / 5;
        var eyeHeight = faceSize / 10;
        var eyeY = centerY - faceSize / 8;
        var leftEyeX = centerX - faceSize / 6;
        var rightEyeX = centerX + faceSize / 6;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        if (isBlinking) {
            var lineThickness = 3;
            var lineY = eyeY + eyeHeight / 2;
            dc.fillRectangle(leftEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
            dc.fillRectangle(rightEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
        } else {
            dc.fillRoundedRectangle(leftEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, 4);
            dc.fillRoundedRectangle(rightEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, 4);
        }
        
        var mouthWidth = faceSize / 2.5;
        var mouthHeight = faceSize / 12;
        var mouthY = centerY + faceSize / 12;
        
        dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, 4);
    }
    
    function drawHourAtMinutePosition(dc, centerX, centerY, rimRadius, hours, minutes) {
        var minuteAngle = minutes * Math.PI / 30.0;
        // Fine-tuned positioning for better alignment with rim
        var handRadius = rimRadius - 30;  // Adjusted for better centering
        var numberX = centerX + Math.sin(minuteAngle) * handRadius;
        var numberY = centerY - Math.cos(minuteAngle) * handRadius;
        
        // Format hour for display
        var displayHour = hours;
        var is24Hour = System.getDeviceSettings().is24Hour;
        
        if (!is24Hour) {
            if (hours == 0) {
                displayHour = 12;
            } else if (hours > 12) {
                displayHour = hours - 12;
            }
        }
        
        var hourStr = displayHour.format("%d");
        
        // Subtle shadow for depth
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numberX + 1, numberY + 1, Graphics.FONT_LARGE, hourStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Main number in green
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numberX, numberY, Graphics.FONT_LARGE, hourStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    
    function drawSimpleAOD(dc, width, height) {
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get time
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var minutes = clockTime.min;
        var seconds = clockTime.sec;
        
        // Device rim radius
        var rimRadius = (width < height ? width : height) / 2 - 8;
        
        // 1. Draw minute markers on rim (dimmer for AOD)
        drawMinuteMarkersAOD(dc, centerX, centerY, rimRadius);
        
        // 2. Draw Jailbot face - blink at start of each minute
        var shouldBlink = (seconds < 1); // Blink for first second of each minute
        drawJailbotFaceAOD(dc, centerX, centerY, width * 0.7, shouldBlink);
        
        // 3. Draw hour number at minute position (same logic, dimmer color)
        drawHourAtMinutePositionAOD(dc, centerX, centerY, rimRadius, hours, minutes);
    }
    
    function drawMinuteMarkersAOD(dc, centerX, centerY, rimRadius) {
        for (var i = 0; i < 60; i += 5) { // Only major markers for AOD
            var angle = i * Math.PI / 30.0;
            var markerX = centerX + rimRadius * Math.sin(angle);
            var markerY = centerY - rimRadius * Math.cos(angle);
            
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            
            if (i == 0) {
                // 12 o'clock marker
                dc.fillRectangle(markerX - 1, markerY - 2, 2, 4);
            } else {
                dc.fillRectangle(markerX - 1, markerY - 1, 2, 2);
            }
        }
    }
    
    function drawJailbotFaceAOD(dc, centerX, centerY, faceSize, shouldBlink) {
        // Eyes
        var eyeWidth = faceSize / 5;
        var eyeHeight = faceSize / 10;
        var eyeY = centerY - faceSize / 8;
        var leftEyeX = centerX - faceSize / 6;
        var rightEyeX = centerX + faceSize / 6;
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        
        if (shouldBlink) {
            // Draw as horizontal lines when blinking
            var lineThickness = 2;
            var lineY = eyeY + eyeHeight / 2;
            dc.fillRectangle(leftEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
            dc.fillRectangle(rightEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
        } else {
            // Draw normal open eyes (outlines only for AOD)
            dc.drawRectangle(leftEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight);
            dc.drawRectangle(rightEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight);
        }
        
        // Mouth (outline only for AOD)
        var mouthWidth = faceSize / 2.5;
        var mouthHeight = faceSize / 12;
        var mouthY = centerY + faceSize / 12;
        
        dc.drawRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight);
    }
    
    function drawHourAtMinutePositionAOD(dc, centerX, centerY, rimRadius, hours, minutes) {
        var minuteAngle = minutes * Math.PI / 30.0;
        var handRadius = rimRadius - 30;  // Match normal mode positioning
        var numberX = centerX + Math.sin(minuteAngle) * handRadius;
        var numberY = centerY - Math.cos(minuteAngle) * handRadius;
        
        // Format hour for display
        var displayHour = hours;
        var is24Hour = System.getDeviceSettings().is24Hour;
        
        if (!is24Hour) {
            if (hours == 0) {
                displayHour = 12;
            } else if (hours > 12) {
                displayHour = hours - 12;
            }
        }
        
        var hourStr = displayHour.format("%d");
        
        // Just the number in dim gray (no shadow for AOD)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numberX, numberY, Graphics.FONT_SMALL, hourStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}