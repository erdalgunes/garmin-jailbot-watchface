using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;

module AOD {
    
    class MinimalTimeDisplay {
        var resManager;
        var lastMinute = -1;
        
        // Simplified digit patterns for AOD (cleaner, less pixels)
        var digitPatterns = [
            // 0
            [[1,1,1],
             [1,0,1],
             [1,0,1],
             [1,0,1],
             [1,1,1]],
            // 1
            [[0,1,0],
             [0,1,0],
             [0,1,0],
             [0,1,0],
             [0,1,0]],
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
        
        function initialize() {
            resManager = new PixelResolution.ResolutionManager();
        }
        
        function drawAOD(dc, screenWidth, screenHeight) {
            var clockTime = System.getClockTime();
            var hour = clockTime.hour;
            var min = clockTime.min;
            
            // Clear screen only once per minute for battery
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            var is24Hour = System.getDeviceSettings().is24Hour;
            if (!is24Hour) {
                if (hour == 0) {
                    hour = 12;
                } else if (hour > 12) {
                    hour = hour - 12;
                }
            }
            
            // Update scaling for current device
            resManager.updateScale(dc);
            
            // Use unified pixelation system 
            var timeSpec = new PixelResolution.GridSpec(30, 10);
            var timeMetrics = resManager.centerGrid(screenWidth, screenHeight, timeSpec);
            var timeRenderer = new PixelResolution.PixelRenderer(dc, timeMetrics);
            
            // Clear only the time area (minimal pixels)
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            var clearWidth = timeMetrics.getTotalWidth(timeSpec.cols);
            var clearHeight = timeMetrics.getTotalHeight(timeSpec.rows);
            dc.fillRectangle(
                timeMetrics.originX - timeMetrics.blockSize, 
                timeMetrics.originY - timeMetrics.blockSize, 
                clearWidth + timeMetrics.blockSize * 2, 
                clearHeight + timeMetrics.blockSize * 2
            );
            
            // Draw time digits with low-luminance filled pixels (burn-in safe)
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            
            var hourTens = hour / 10;
            var hourOnes = hour % 10;
            var minTens = min / 10;
            var minOnes = min % 10;
            
            // Add burn-in prevention pixel shifting (1px random walk)
            var shiftX = (min % 3) - 1;  // -1, 0, 1 shift based on minute
            var shiftY = ((min / 3) % 3) - 1;  // vertical shift every 3 minutes
            
            // Position digits: HH:MM layout with pixel shifting
            drawFilledDigit(timeRenderer, digitPatterns[hourTens], 2 + shiftX, 3 + shiftY);
            drawFilledDigit(timeRenderer, digitPatterns[hourOnes], 7 + shiftX, 3 + shiftY);
            
            // Draw colon (blink every other minute to reduce burn-in)
            if (min % 2 == 0) {
                drawFilledColon(timeRenderer, 12 + shiftX, 3 + shiftY);
            }
            
            drawFilledDigit(timeRenderer, digitPatterns[minTens], 15 + shiftX, 3 + shiftY);
            drawFilledDigit(timeRenderer, digitPatterns[minOnes], 20 + shiftX, 3 + shiftY);
        }
        
        function drawFilledDigit(renderer, pattern, startCol, startRow) {
            for (var row = 0; row < 5; row++) {
                for (var col = 0; col < 3; col++) {
                    if (pattern[row][col] == 1) {
                        drawFilledPixelBlock(renderer, startCol + col, startRow + row);
                    }
                }
            }
        }
        
        function drawFilledColon(renderer, startCol, startRow) {
            // Draw colon as two filled blocks vertically aligned
            drawFilledPixelBlock(renderer, startCol, startRow + 1);
            drawFilledPixelBlock(renderer, startCol, startRow + 3);
        }
        
        function drawFilledPixelBlock(renderer, col, row) {
            // Draw filled pixel block (burn-in safe, uses fewer pixels than borders)
            var x = renderer.metrics.getCellX(col);
            var y = renderer.metrics.getCellY(row);
            var size = renderer.metrics.blockSize;
            
            // Fill entire block for better readability and fewer edge pixels
            renderer.dc.fillRectangle(x, y, size, size);
        }
    }
}