using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;

module PixelTime {
    
    class DigitPatterns {
        static var patterns = [
            // 0
            [[1,1,1],
             [1,0,1],
             [1,0,1],
             [1,0,1],
             [1,1,1]],
            // 1
            [[0,1,0],
             [1,1,0],
             [0,1,0],
             [0,1,0],
             [1,1,1]],
            // 2
            [[1,1,1],
             [0,0,1],
             [1,1,1],
             [1,0,0],
             [1,1,1]],
            // 3
            [[1,1,1],
             [0,0,1],
             [1,1,1],
             [0,0,1],
             [1,1,1]],
            // 4
            [[1,0,1],
             [1,0,1],
             [1,1,1],
             [0,0,1],
             [0,0,1]],
            // 5
            [[1,1,1],
             [1,0,0],
             [1,1,1],
             [0,0,1],
             [1,1,1]],
            // 6
            [[1,1,1],
             [1,0,0],
             [1,1,1],
             [1,0,1],
             [1,1,1]],
            // 7
            [[1,1,1],
             [0,0,1],
             [0,0,1],
             [0,0,1],
             [0,0,1]],
            // 8
            [[1,1,1],
             [1,0,1],
             [1,1,1],
             [1,0,1],
             [1,1,1]],
            // 9
            [[1,1,1],
             [1,0,1],
             [1,1,1],
             [0,0,1],
             [1,1,1]]
        ];
    }
    
    class TimeDisplay {
        var resManager;
        var digitCols = 3;
        var digitRows = 5;
        var colonSpacing = 2;  // Blocks between digits and colon
        
        function initialize() {
            resManager = new PixelResolution.ResolutionManager();
        }
        
        function draw(dc, screenWidth, screenHeight) {
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
            
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            
            // Update scaling first
            resManager.updateScale(dc);
            
            var blockSize = resManager.blockSize;
            var gap = resManager.gap;
            
            // Calculate dimensions
            var digitWidth = digitCols * blockSize + (digitCols - 1) * gap;
            var digitHeight = digitRows * blockSize + (digitRows - 1) * gap;
            var colonWidth = blockSize;
            var spaceBetweenDigits = colonSpacing * (blockSize + gap);
            
            // Total width of time display
            var totalWidth = digitWidth * 4 + spaceBetweenDigits * 3 + colonWidth;
            var startX = (screenWidth - totalWidth) / 2;
            var startY = 20;  // Top position
            
            // Draw hour tens
            var hourTens = hour / 10;
            drawDigit(dc, hourTens, startX, startY);
            
            // Draw hour ones
            var hourOnes = hour % 10;
            drawDigit(dc, hourOnes, startX + digitWidth + spaceBetweenDigits, startY);
            
            // Draw colon
            var colonX = startX + (digitWidth + spaceBetweenDigits) * 2;
            var colonY1 = startY + blockSize + gap;
            var colonY2 = startY + (blockSize + gap) * 3;
            
            var colonMetrics = resManager.positionGrid(colonX, colonY1);
            var colonRenderer = new PixelResolution.PixelRenderer(dc, colonMetrics);
            colonRenderer.drawRectangle(0, 0, 1, 1);
            
            colonMetrics = resManager.positionGrid(colonX, colonY2);
            colonRenderer = new PixelResolution.PixelRenderer(dc, colonMetrics);
            colonRenderer.drawRectangle(0, 0, 1, 1);
            
            // Draw minute tens
            var minTens = min / 10;
            drawDigit(dc, minTens, colonX + colonWidth + spaceBetweenDigits, startY);
            
            // Draw minute ones
            var minOnes = min % 10;
            drawDigit(dc, minOnes, colonX + colonWidth + spaceBetweenDigits + digitWidth + spaceBetweenDigits, startY);
        }
        
        function drawDigit(dc, digit, x, y) {
            var pattern = DigitPatterns.patterns[digit];
            var metrics = resManager.positionGrid(x, y);
            var renderer = new PixelResolution.PixelRenderer(dc, metrics);
            
            for (var row = 0; row < digitRows; row++) {
                for (var col = 0; col < digitCols; col++) {
                    if (pattern[row][col] == 1) {
                        renderer.drawRectangle(col, row, 1, 1);
                    }
                }
            }
        }
    }
}