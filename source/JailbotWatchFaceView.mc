using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time.Gregorian;
using Toybox.Timer;

class JailbotWatchFaceView extends WatchUi.WatchFace {
    
    var analogFace;
    var aodDisplay;
    var inAOD = false;
    var updateTimer;
    var moodEngine;
    var healthDataProvider;

    function initialize() {
        WatchFace.initialize();
        
        // Initialize analog face (will be positioned in onLayout)
        analogFace = null;
        aodDisplay = new AOD.MinimalTimeDisplay();
        
        // Initialize mood system
        moodEngine = new MoodEngine();
        healthDataProvider = new HealthDataProvider();
        
        // Create a timer to update every second for mood system and animations
        updateTimer = new Timer.Timer();
    }

    function onLayout(dc) {
        // SOLID: Use device screen size, not DC clip size to avoid scaling issues
        var deviceSettings = System.getDeviceSettings();
        var width = deviceSettings.screenWidth;
        var height = deviceSettings.screenHeight;
        var centerX = width / 2;
        var centerY = height / 2;
        var radius = (width < height ? width : height) / 2 - 20; // Leave 20px margin
        
        try {
            analogFace = new JailbotAnalog.JailbotAnalogFace(centerX, centerY, radius);
            analogFace.initialize(centerX, centerY, radius);
        } catch (ex) {
            // DEBUG: Analog face creation failed
            System.println("Analog face creation failed: " + ex.getErrorMessage());
            analogFace = null;
        }
    }

    function onShow() {
        // Start the timer when the watch face is shown
        updateTimer.start(method(:requestUpdate), 1000, true);
    }

    function onUpdate(dc) {
        inAOD = false;  // We're in normal mode
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // DIRECT IMPLEMENTATION - bypass all other components
        drawDirectAnalogJailbot(dc, width, height);
    }
    
    function onPartialUpdate(dc) {
        inAOD = true;   // We're in Always On Display mode
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        aodDisplay.drawAOD(dc, width, height);
    }

    function onHide() {
        // Stop the timer when the watch face is hidden
        updateTimer.stop();
    }
    
    function requestUpdate() {
        // Request a screen update for animation
        WatchUi.requestUpdate();
    }

    function onExitSleep() {
    }

    function onEnterSleep() {
    }
    
    function drawPixelatedAOD(dc, screenWidth, screenHeight) {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var min = clockTime.min;
        
        var is24Hour = System.getDeviceSettings().is24Hour;
        if (!is24Hour) {
            if (hour == 0) {
                hour = 12;
            } else if (hour > 12) {
                hour = hour - 12;
            }
        }
        
        // Use same patterns as timeDisplay but draw as hollow blocks
        var digitPatterns = [
            [[1,1,1],[1,0,1],[1,0,1],[1,0,1],[1,1,1]], // 0
            [[0,1,0],[0,1,0],[0,1,0],[0,1,0],[0,1,0]], // 1
            [[1,1,1],[0,0,1],[1,1,1],[1,0,0],[1,1,1]], // 2
            [[1,1,1],[0,0,1],[1,1,1],[0,0,1],[1,1,1]], // 3
            [[1,0,1],[1,0,1],[1,1,1],[0,0,1],[0,0,1]], // 4
            [[1,1,1],[1,0,0],[1,1,1],[0,0,1],[1,1,1]], // 5
            [[1,1,1],[1,0,0],[1,1,1],[1,0,1],[1,1,1]], // 6
            [[1,1,1],[0,0,1],[0,0,1],[0,0,1],[0,0,1]], // 7
            [[1,1,1],[1,0,1],[1,1,1],[1,0,1],[1,1,1]], // 8
            [[1,1,1],[1,0,1],[1,1,1],[0,0,1],[1,1,1]]  // 9
        ];
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        var blockSize = 15; // Larger blocks for AOD
        var digitWidth = 3 * blockSize;
        var digitSpacing = blockSize;
        var colonWidth = blockSize;
        
        var totalWidth = digitWidth * 4 + digitSpacing * 3 + colonWidth;
        var startX = (screenWidth - totalWidth) / 2;
        var startY = (screenHeight - 5 * blockSize) / 2;
        
        // Draw hour tens
        var hourTens = hour / 10;
        drawHollowDigit(dc, digitPatterns[hourTens], startX, startY, blockSize);
        
        // Draw hour ones
        var hourOnes = hour % 10;
        drawHollowDigit(dc, digitPatterns[hourOnes], startX + digitWidth + digitSpacing, startY, blockSize);
        
        // Draw colon as hollow blocks
        var colonX = startX + digitWidth * 2 + digitSpacing * 2;
        drawHollowBlock(dc, colonX, startY + blockSize, blockSize);
        drawHollowBlock(dc, colonX, startY + blockSize * 3, blockSize);
        
        // Draw minute tens
        var minTens = min / 10;
        drawHollowDigit(dc, digitPatterns[minTens], colonX + colonWidth + digitSpacing, startY, blockSize);
        
        // Draw minute ones
        var minOnes = min % 10;
        drawHollowDigit(dc, digitPatterns[minOnes], colonX + colonWidth + digitSpacing + digitWidth + digitSpacing, startY, blockSize);
    }
    
    function drawHollowDigit(dc, pattern, x, y, blockSize) {
        for (var row = 0; row < 5; row++) {
            for (var col = 0; col < 3; col++) {
                if (pattern[row][col] == 1) {
                    drawHollowBlock(dc, x + col * blockSize, y + row * blockSize, blockSize);
                }
            }
        }
    }
    
    function drawHollowBlock(dc, x, y, size) {
        // Draw hollow block with 2px border INSIDE the block
        var borderWidth = 2;
        
        // Top border (inside)
        dc.fillRectangle(x, y, size, borderWidth);
        // Bottom border (inside)
        dc.fillRectangle(x, y + size - borderWidth, size, borderWidth);
        // Left border (inside)
        dc.fillRectangle(x, y, borderWidth, size);
        // Right border (inside)
        dc.fillRectangle(x + size - borderWidth, y, borderWidth, size);
        
        // The center remains hollow (black background shows through)
        // Inner area: (x + borderWidth, y + borderWidth) to (x + size - borderWidth, y + size - borderWidth)
    }
    
    function drawDirectAnalogJailbot(dc, width, height) {
        // Clear screen first
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw Jailbot 2.0 pixel art design following GBA aesthetic
        drawJailbot20PixelArt(dc, width, height);
    }
    
    function drawAuthenticJailbot(dc, width, height) {
        var centerX = width / 2;
        var centerY = height / 2;
        var radius = (width < height ? width : height) / 2 - 20;
        
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var minutes = clockTime.min;
        var seconds = clockTime.sec;
        
        // Draw analog hands (minimalist - only outer third)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Hour hand (pivots from center with small tail)
        var hourAngle = (hours % 12) * Math.PI / 6.0 + minutes * Math.PI / 360.0;
        var hourLength = radius * 0.5;
        var hourTail = hourLength * 0.15; // Small tail opposite the hand
        var hourStartX = centerX - hourTail * Math.sin(hourAngle);
        var hourStartY = centerY + hourTail * Math.cos(hourAngle);
        var hourEndX = centerX + hourLength * Math.sin(hourAngle);
        var hourEndY = centerY - hourLength * Math.cos(hourAngle);
        dc.setPenWidth(3);
        dc.drawLine(hourStartX, hourStartY, hourEndX, hourEndY);
        
        // Minute hand (pivots from center with small tail)
        var minuteAngle = minutes * Math.PI / 30.0;
        var minuteLength = radius * 0.8;
        var minuteTail = minuteLength * 0.15; // Small tail opposite the hand
        var minuteStartX = centerX - minuteTail * Math.sin(minuteAngle);
        var minuteStartY = centerY + minuteTail * Math.cos(minuteAngle);
        var minuteEndX = centerX + minuteLength * Math.sin(minuteAngle);
        var minuteEndY = centerY - minuteLength * Math.cos(minuteAngle);
        dc.setPenWidth(2);
        dc.drawLine(minuteStartX, minuteStartY, minuteEndX, minuteEndY);
        
        // Second hand (pivots from center with small tail)
        var secondAngle = seconds * Math.PI / 30.0;
        var secondLength = radius * 0.9;
        var secondTail = secondLength * 0.2; // Slightly longer tail for balance
        var secondStartX = centerX - secondTail * Math.sin(secondAngle);
        var secondStartY = centerY + secondTail * Math.cos(secondAngle);
        var secondEndX = centerX + secondLength * Math.sin(secondAngle);
        var secondEndY = centerY - secondLength * Math.cos(secondAngle);
        dc.setPenWidth(1);
        dc.drawLine(secondStartX, secondStartY, secondEndX, secondEndY);
        
        // Draw authentic jailbot: white tombstone body with dot-matrix face
        var jailbotSize = radius * 1.0;
        var bodyX = centerX - jailbotSize / 2;
        var bodyY = centerY - jailbotSize / 2;
        
        // 1. Draw white tombstone body
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(bodyX, bodyY, jailbotSize, jailbotSize, jailbotSize / 8);
        
        // 2. Draw black outline
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(bodyX, bodyY, jailbotSize, jailbotSize, jailbotSize / 8);
        
        // 3. Draw dark face panel (upper third of body)
        var panelWidth = jailbotSize * 0.7;
        var panelHeight = jailbotSize * 0.4;
        var panelX = centerX - panelWidth / 2;
        var panelY = bodyY + jailbotSize * 0.15;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(panelX, panelY, panelWidth, panelHeight);
        
        // 4. Draw dot-matrix pixels (10x6 grid)
        var dotSize = panelWidth / 14; // Smaller dots for authentic matrix look
        var dotSpacing = dotSize * 0.8;
        var gridStartX = panelX + dotSize;
        var gridStartY = panelY + dotSize;
        
        var shouldBlink = (clockTime.sec % 3 == 0);
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        // Recreate exact reference layout: 12x8 grid
        var cols = 12;
        var rows = 8;
        dotSize = panelWidth / (cols + 1);
        dotSpacing = dotSize * 0.2;
        gridStartX = panelX + dotSize * 0.5;
        gridStartY = panelY + dotSize * 0.5;
        
        // Jailbot 2.0: Narrowed angry slanted eyes with evil inward tilt
        
        // Left eye: Slanted parallelogram (narrowed, angry look)
        // Top row: cols 1-4 (tapered inner end), offset toward center
        for (var col = 1; col <= 4; col++) {
            if (!shouldBlink) {
                var dotX = gridStartX + col * (dotSize + dotSpacing);
                var dotY = gridStartY + 1 * (dotSize + dotSpacing);
                dc.fillRectangle(dotX, dotY, dotSize, dotSize);
            }
        }
        
        // Bottom row: cols 2-6 (shifted away from center for angry slant)
        for (var col = 2; col <= 6; col++) {
            var dotX = gridStartX + col * (dotSize + dotSpacing);
            var dotY = gridStartY + 2 * (dotSize + dotSpacing);
            dc.fillRectangle(dotX, dotY, dotSize, dotSize);
        }
        
        // Right eye: Mirrored slanted parallelogram
        // Top row: cols 9-12 (tapered inner end), offset toward center  
        for (var col = 9; col <= 12; col++) {
            if (!shouldBlink) {
                var dotX = gridStartX + col * (dotSize + dotSpacing);
                var dotY = gridStartY + 1 * (dotSize + dotSpacing);
                dc.fillRectangle(dotX, dotY, dotSize, dotSize);
            }
        }
        
        // Bottom row: cols 7-11 (shifted away from center for angry slant)
        for (var col = 7; col <= 11; col++) {
            var dotX = gridStartX + col * (dotSize + dotSpacing);
            var dotY = gridStartY + 2 * (dotSize + dotSpacing);
            dc.fillRectangle(dotX, dotY, dotSize, dotSize);
        }
        
        // Mouth: 8x2 block (cols 3-10, rows 5-6)
        for (var row = 5; row <= 6; row++) {
            for (var col = 3; col <= 10; col++) {
                var dotX = gridStartX + col * (dotSize + dotSpacing);
                var dotY = gridStartY + row * (dotSize + dotSpacing);
                dc.fillRectangle(dotX, dotY, dotSize, dotSize);
            }
        }
    }
    
    function drawJailbot3(dc, width, height) {
        var centerX = width / 2;
        var centerY = height / 2;
        
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var minutes = clockTime.min;
        
        // JAILBOT 3.0 MODERN SMARTWATCH DESIGN
        
        // 1. Sleek Visor Panel (top third) - Stealth Black colorway
        var visorWidth = width * 0.8;
        var visorHeight = height * 0.25;
        var visorX = centerX - visorWidth / 2;
        var visorY = height * 0.15;
        
        // Glossy black visor with rounded corners
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(visorX, visorY, visorWidth, visorHeight, visorHeight * 0.3);
        
        // Electric cyan edge lighting
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(visorX, visorY, visorWidth, visorHeight, visorHeight * 0.3);
        
        // 2. Eyes 3.0: Geometric LED slits with cyan glow
        var shouldBlink = (clockTime.sec % 3 == 0);
        var eyeWidth = visorWidth / 6;
        var eyeHeight = visorHeight / 4;
        var leftEyeX = visorX + visorWidth * 0.25;
        var rightEyeX = visorX + visorWidth * 0.65;
        var eyeY = visorY + visorHeight * 0.4;
        
        if (!shouldBlink) {
            // Eye glow halos
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(leftEyeX - 2, eyeY - 1, eyeWidth + 4, eyeHeight + 2);
            dc.fillRectangle(rightEyeX - 2, eyeY - 1, eyeWidth + 4, eyeHeight + 2);
            
            // Bright white core slits
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(leftEyeX, eyeY, eyeWidth, eyeHeight);
            dc.fillRectangle(rightEyeX, eyeY, eyeWidth, eyeHeight);
        }
        
        // 3. Large Time Display (condensed modern numerals)
        var is24Hour = System.getDeviceSettings().is24Hour;
        var timeHour = hours;
        if (!is24Hour && hours > 12) {
            timeHour = hours - 12;
        } else if (!is24Hour && hours == 0) {
            timeHour = 12;
        }
        
        var timeY = centerY - 20;
        var hourStr = timeHour.format("%02d");
        var minStr = minutes.format("%02d");
        
        // Large time display with white text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 30, timeY, Graphics.FONT_NUMBER_HOT, hourStr, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(centerX + 30, timeY, Graphics.FONT_NUMBER_HOT, minStr, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Colon as jail bar (cyan accent)
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(centerX - 2, timeY + 10, 4, 35);
        
        // 4. Fitness Data as Jail Bars
        var barWidth = 8;
        var barHeight = height * 0.35;
        var barY = centerY - barHeight / 2;
        
        // Left bar: Battery level
        var batteryLevel = System.getSystemStats().battery;
        var leftBarX = width * 0.08;
        var batteryHeight = (barHeight * batteryLevel / 100).toNumber();
        
        // Battery color: green to red based on level
        dc.setColor(batteryLevel > 50 ? Graphics.COLOR_GREEN : 
                   batteryLevel > 25 ? Graphics.COLOR_YELLOW : Graphics.COLOR_RED, 
                   Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(leftBarX, barY + barHeight - batteryHeight, barWidth, batteryHeight);
        
        // Bar outline
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(leftBarX, barY, barWidth, barHeight);
        
        // Right bar: Steps progress (cyan accent)
        var rightBarX = width * 0.84;
        var stepsHeight = barHeight * 0.75; // 75% progress placeholder
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(rightBarX, barY + barHeight - stepsHeight, barWidth, stepsHeight);
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(rightBarX, barY, barWidth, barHeight);
        
        // 5. Bottom data strip (compact fitness info)
        var bottomY = height * 0.88;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        
        // Date
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateStr = Lang.format("$1$/$2$", [today.month, today.day]);
        dc.drawText(width * 0.15, bottomY, Graphics.FONT_TINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Battery percentage
        var battStr = Lang.format("$1$%", [batteryLevel.format("%d")]);
        dc.drawText(width * 0.85, bottomY, Graphics.FONT_TINY, battStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawJailbot20PixelArt(dc, width, height) {
        var centerX = width / 2;
        var centerY = height / 2;
        
        System.println("Screen center: " + centerX + ", " + centerY + " (width=" + width + ", height=" + height + ")");
        
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var minutes = clockTime.min;
        
        // ALL BLACK BACKGROUND - no other containers
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Device rim radius for indicators
        var rimRadius = (width < height ? width : height) / 2 - 8;
        
        // 1. Draw minute markers on device rim - ALL RED
        for (var i = 0; i < 60; i++) {
            var angle = i * Math.PI / 30.0; // 6 degrees per minute
            var markerX = centerX + rimRadius * Math.sin(angle);
            var markerY = centerY - rimRadius * Math.cos(angle);
            
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            
            if (i % 5 == 0) {
                // Major markers (5-minute intervals) - rounded rectangles
                if (i == 0) {
                    // 12 o'clock marker - slightly larger
                    dc.fillRoundedRectangle(markerX - 2, markerY - 4, 4, 6, 2);
                } else {
                    dc.fillRoundedRectangle(markerX - 1, markerY - 2, 2, 4, 1);
                }
            } else {
                // Minor markers - small rounded squares
                dc.fillRoundedRectangle(markerX - 1, markerY - 1, 2, 2, 1);
            }
        }
        
        // 2. Update mood system and get expressive Jailbot face
        try {
            var rawSensors = healthDataProvider.gatherSensorData();
            rawSensors[:aod] = inAOD; // Add AOD state
            
            var renderData = moodEngine.update(rawSensors);
            
            // Draw expressive Jailbot face using mood system
            var faceSize = width * 0.7;
            var renderer = new ExpressionRenderer();
            renderer.render(dc, renderData, faceSize, centerX, centerY);
            
            // No debug text - clean design
            
        } catch (ex) {
            // Fallback to simple static face if mood system fails
            System.println("Mood system error: " + ex.getErrorMessage());
            self.drawStaticJailbotFace(dc, centerX, centerY, width * 0.7);
        }
        
        // 3. Draw hour number at MINUTE position - shows progress through the hour
        var minuteAngle = minutes * Math.PI / 30.0; // 6 degrees per minute
        var handRadius = rimRadius - 25; // Further from rim to prevent text overflow
        var numberX = centerX + handRadius * Math.sin(minuteAngle);
        var numberY = centerY - handRadius * Math.cos(minuteAngle);
        
        // 4. Draw hour number directly
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
        
        // Number shadow (GBA style depth)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numberX + 1, numberY + 1, Graphics.FONT_LARGE, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Main number (Jailbot red)
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numberX, numberY, Graphics.FONT_LARGE, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
        
        // No battery indicator - clean minimal design
    }
    
    // Fallback static face for error conditions
    function drawStaticJailbotFace(dc, centerX, centerY, faceSize) {
        // Simple static eyes and mouth
        var eyeWidth = faceSize / 5;
        var eyeHeight = faceSize / 10;
        var eyeY = centerY - faceSize / 8;
        var leftEyeX = centerX - faceSize / 6;
        var rightEyeX = centerX + faceSize / 6;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(leftEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, 4);
        dc.fillRoundedRectangle(rightEyeX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, 4);
        
        var mouthWidth = faceSize / 2.5;
        var mouthHeight = faceSize / 12;
        var mouthY = centerY + faceSize / 12;
        
        dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, 4);
    }
}