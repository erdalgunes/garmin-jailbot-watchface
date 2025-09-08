using Toybox.Graphics;
using Toybox.System;

module JailbotAnalog {
    
    // Open/Closed Principle: Extend AnalogClockFace with Jailbot features
    class JailbotAnalogFace extends AnalogClock.AnalogClockFace {
        var jailbotFace;
        var showJailbot;
        var blinkTimer;
        
        function initialize(x, y, r) {
            AnalogClockFace.initialize(x, y, r);
            
            // Initialize jailbot components but smaller for analog face
            jailbotFace = new JailbotFace.FaceLayout();
            jailbotFace.initialize();
            
            showJailbot = true;
            blinkTimer = 0;
        }
        
        function draw(dc, hours, minutes, seconds) {
            // Clear screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw analog clock (parent implementation)
            AnalogClockFace.draw(dc, hours, minutes, seconds);
            
            if (showJailbot) {
                var clockTime = System.getClockTime();
                drawJailbotElements(dc, clockTime);
            }
        }
        
        function drawWithScreen(dc, screenWidth, screenHeight) {
            var clockTime = System.getClockTime();
            draw(dc, clockTime.hour, clockTime.min, clockTime.sec);
        }
        
        function drawJailbotElements(dc, clockTime) {
            // Position jailbot face in the center area (where analog faces usually have logo)
            var shouldBlink = (clockTime.sec % 3 == 0);
            
            // Scale up jailbot much larger for prominence in clean center
            var jailbotSize = radius * 1.2; // 120% of clock radius - fills most of center
            var jailbotX = centerX - jailbotSize / 2;
            var jailbotY = centerY - jailbotSize / 2;
            
            drawMiniJailbot(dc, jailbotX, jailbotY, jailbotSize, shouldBlink);
        }
        
        function drawMiniJailbot(dc, x, y, size, shouldBlink) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            
            var blockSize = size / 14; // Scale to fit in center
            
            // Draw eyes
            var leftEyeX = x + blockSize * 4;
            var rightEyeX = x + blockSize * 9;
            var eyeY = y + blockSize * 4;
            var eyeWidth = blockSize * 2;
            var eyeHeight = shouldBlink ? blockSize : blockSize * 2;
            
            dc.fillRectangle(leftEyeX, eyeY, eyeWidth, eyeHeight);
            dc.fillRectangle(rightEyeX, eyeY, eyeWidth, eyeHeight);
            
            // Draw mouth
            var mouthX = x + blockSize * 5;
            var mouthY = y + blockSize * 8;
            var mouthWidth = blockSize * 4;
            var mouthHeight = blockSize;
            
            dc.fillRectangle(mouthX, mouthY, mouthWidth, mouthHeight);
        }
        
        function toggleJailbotDisplay() {
            showJailbot = !showJailbot;
        }
    }
    
    // Factory pattern for different analog styles
    class AnalogStyleFactory {
        static function createClassicStyle(x, y, r) {
            var face = new JailbotAnalogFace(x, y, r);
            return face;
        }
        
        static function createMinimalStyle(x, y, r) {
            var face = new JailbotAnalogFace(x, y, r);
            // Could customize colors, remove some indicators, etc.
            return face;
        }
    }
}