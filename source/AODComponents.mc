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
            
            // Ghost Jailbot AOD - hollow outlines for minimal pixels
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            
            var hourTens = hour / 10;
            var hourOnes = hour % 10;
            var minTens = min / 10;
            var minOnes = min % 10;
            
            // Draw hollow outline digits (much fewer pixels than filled)
            drawHollowDigit(timeRenderer, digitPatterns[hourTens], 2, 3);
            drawHollowDigit(timeRenderer, digitPatterns[hourOnes], 7, 3);
            
            // Draw minimal colon - just 2 pixels
            drawMinimalColon(timeRenderer, 12, 3);
            
            drawHollowDigit(timeRenderer, digitPatterns[minTens], 15, 3);
            drawHollowDigit(timeRenderer, digitPatterns[minOnes], 20, 3);
            
            // Draw Ghost Jailbot outline above time
            drawGhostJailbot(dc, screenWidth, screenHeight/3);
        }
        
        function drawHollowDigit(renderer, pattern, startCol, startRow) {
            // Draw only the outline of the digit pattern (minimal pixels)
            for (var row = 0; row < 5; row++) {
                for (var col = 0; col < 3; col++) {
                    if (pattern[row][col] == 1) {
                        // Check if this is an edge pixel
                        var isEdge = false;
                        
                        // Check if any neighbor is empty (0 or out of bounds)
                        if (row == 0 || row == 4 || col == 0 || col == 2) {
                            isEdge = true;
                        } else if (pattern[row-1][col] == 0 || pattern[row+1][col] == 0 ||
                                   pattern[row][col-1] == 0 || pattern[row][col+1] == 0) {
                            isEdge = true;
                        }
                        
                        if (isEdge) {
                            drawPixelDot(renderer, startCol + col, startRow + row);
                        }
                    }
                }
            }
        }
        
        function drawMinimalColon(renderer, startCol, startRow) {
            // Just 2 minimal dots for colon
            drawPixelDot(renderer, startCol, startRow + 1);
            drawPixelDot(renderer, startCol, startRow + 3);
        }
        
        function drawPixelDot(renderer, col, row) {
            // Draw single pixel for minimal battery usage
            var x = renderer.metrics.getCellX(col);
            var y = renderer.metrics.getCellY(row);
            var size = renderer.metrics.blockSize;
            renderer.dc.fillRectangle(x, y, size, size);
        }
        
        function drawGhostJailbot(dc, screenWidth, centerY) {
            var centerX = screenWidth / 2;
            var size = screenWidth / 6; // Small ghost Jailbot
            
            // Draw hollow rectangle for head outline
            dc.setPenWidth(1);
            dc.drawRoundedRectangle(centerX - size/2, centerY - size/2, size, size, size/8);
            
            // Draw minimal eyes - just 2 dots
            var eyeY = centerY - size/6;
            var leftEyeX = centerX - size/4;
            var rightEyeX = centerX + size/4;
            
            dc.fillCircle(leftEyeX, eyeY, 1);
            dc.fillCircle(rightEyeX, eyeY, 1);
            
            // Draw minimal mouth - single line
            var mouthY = centerY + size/6;
            dc.drawLine(centerX - size/4, mouthY, centerX + size/4, mouthY);
        }
    }
}