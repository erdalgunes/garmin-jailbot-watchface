using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Math;

class JailbotWatchFaceView extends WatchUi.WatchFace {
    
    var inAOD = false;
    var updateTimer;
    
    // Simple blink state
    var isBlinking = false;
    var nextBlinkTime = 0;
    var blinkStartTime = 0;
    var blinkDuration = 150; // milliseconds
    
    function initialize() {
        WatchFace.initialize();
        updateTimer = new Timer.Timer();
        scheduleNextBlink();
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
            var markerX = centerX + rimRadius * Math.sin(angle);
            var markerY = centerY - rimRadius * Math.cos(angle);
            
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            
            if (i % 5 == 0) {
                // Major markers
                if (i == 0) {
                    dc.fillRoundedRectangle(markerX - 2, markerY - 4, 4, 6, 2);
                } else {
                    dc.fillRoundedRectangle(markerX - 1, markerY - 2, 2, 4, 1);
                }
            } else {
                // Minor markers
                dc.fillRoundedRectangle(markerX - 1, markerY - 1, 2, 2, 1);
            }
        }
    }
    
    function drawJailbotFace(dc, centerX, centerY, faceSize) {
        // Eyes
        var eyeWidth = faceSize / 5;
        var eyeHeight = faceSize / 10;
        var eyeY = centerY - faceSize / 8;
        var leftEyeX = centerX - faceSize / 6;
        var rightEyeX = centerX + faceSize / 6;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        // Draw eyes based on blink state
        if (isBlinking) {
            // Draw as horizontal lines when blinking (- -)
            var lineThickness = 3;
            var lineY = eyeY + eyeHeight / 2;
            dc.fillRectangle(leftEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
            dc.fillRectangle(rightEyeX - eyeWidth/2, lineY - lineThickness/2, eyeWidth, lineThickness);
        } else {
            // Draw normal open eyes
            dc.fillRoundedRectangle(leftEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, 4);
            dc.fillRoundedRectangle(rightEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, 4);
        }
        
        // Mouth (always visible)
        var mouthWidth = faceSize / 2.5;
        var mouthHeight = faceSize / 12;
        var mouthY = centerY + faceSize / 12;
        
        dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, 4);
    }
    
    function drawHourAtMinutePosition(dc, centerX, centerY, rimRadius, hours, minutes) {
        var minuteAngle = minutes * Math.PI / 30.0;
        var handRadius = rimRadius - 35;
        var numberX = centerX + handRadius * Math.sin(minuteAngle);
        var numberY = centerY - handRadius * Math.cos(minuteAngle);
        
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
        
        // Shadow
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numberX + 1, numberY + 1, Graphics.FONT_LARGE, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Main number
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numberX, numberY, Graphics.FONT_LARGE, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
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
        var handRadius = rimRadius - 35;
        var numberX = centerX + handRadius * Math.sin(minuteAngle);
        var numberY = centerY - handRadius * Math.cos(minuteAngle);
        
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
        dc.drawText(numberX, numberY, Graphics.FONT_MEDIUM, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}