using Toybox.Graphics;

module JailbotFace {
    
    class Eye {
        var cols = 9;   // Reduced by 1 pixel block for narrower eyes
        var rows = 4;   // Keep height the same
        
        function getSpec() {
            return new PixelResolution.GridSpec(cols, rows);
        }
    }
    
    class Mouth {
        var cols = 14;  // Scaled up for 5px blocks (was 10 at 7px)
        var rows = 4;   // Reduced by 2 for better proportions
        
        function getSpec() {
            return new PixelResolution.GridSpec(cols, rows);
        }
    }
    
    class FaceLayout {
        var resManager;
        var leftEye;
        var rightEye;
        var mouth;
        var eyeSpacingBlocks = 6;  // Scaled spacing for 5px blocks
        
        function initialize() {
            resManager = new PixelResolution.ResolutionManager();
            leftEye = new Eye();
            rightEye = new Eye();
            mouth = new Mouth();
        }
        
        function adjustEyeSpacing(blocks) {
            eyeSpacingBlocks = blocks;
        }
        
        function moveEyesApart() {
            eyeSpacingBlocks = eyeSpacingBlocks + 1;
        }
        
        function moveEyesCloser() {
            if (eyeSpacingBlocks > 0) {
                eyeSpacingBlocks = eyeSpacingBlocks - 1;
            }
        }
        
        function setEyeSpacing(blocks) {
            eyeSpacingBlocks = blocks;
        }
        
        function draw(dc, screenWidth, screenHeight) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            
            // Update scaling first
            resManager.updateScale(dc);
            
            var blockSize = resManager.blockSize;
            var gap = resManager.gap;
            
            // Get current time for blinking animation
            var clockTime = System.getClockTime();
            // Blink every 3 seconds for half a second
            var shouldBlink = (clockTime.sec % 3 == 0);
            
            // Calculate eye positions
            var eyeSpec = leftEye.getSpec();
            var eyeWidth = eyeSpec.cols * blockSize + (eyeSpec.cols - 1) * gap;
            var eyeHeight = eyeSpec.rows * blockSize + (eyeSpec.rows - 1) * gap;
            
            // Eye spacing in pixels (convert block units to pixels)
            var eyeSpacingPx = eyeSpacingBlocks * (blockSize + gap);
            
            // Center horizontally
            var totalEyesWidth = eyeWidth * 2 + eyeSpacingPx;
            var leftEyeX = (screenWidth - totalEyesWidth) / 2;
            var rightEyeX = leftEyeX + eyeWidth + eyeSpacingPx;
            var eyeY = screenHeight / 3 + blockSize * 2;  // Moved down 2 blocks
            
            // Draw left eye
            var leftEyeMetrics = resManager.positionGrid(leftEyeX, eyeY);
            var leftRenderer = new PixelResolution.PixelRenderer(dc, leftEyeMetrics);
            if (!shouldBlink) {
                // Normal open eye
                leftRenderer.drawRectangle(0, 0, eyeSpec.cols, eyeSpec.rows);
            } else {
                // Closed eye (horizontal line in middle)
                leftRenderer.drawRectangle(0, eyeSpec.rows/2, eyeSpec.cols, 1);
            }
            
            // Draw right eye
            var rightEyeMetrics = resManager.positionGrid(rightEyeX, eyeY);
            var rightRenderer = new PixelResolution.PixelRenderer(dc, rightEyeMetrics);
            if (!shouldBlink) {
                // Normal open eye
                rightRenderer.drawRectangle(0, 0, eyeSpec.cols, eyeSpec.rows);
            } else {
                // Closed eye (horizontal line in middle)
                rightRenderer.drawRectangle(0, eyeSpec.rows/2, eyeSpec.cols, 1);
            }
            
            // Draw mouth
            var mouthSpec = mouth.getSpec();
            var mouthWidth = mouthSpec.cols * blockSize + (mouthSpec.cols - 1) * gap;
            var mouthX = (screenWidth - mouthWidth) / 2;
            var mouthY = screenHeight * 2 / 3 - blockSize * 6;  // Six blocks higher (moved up 2 more)
            
            var mouthMetrics = resManager.positionGrid(mouthX, mouthY);
            var mouthRenderer = new PixelResolution.PixelRenderer(dc, mouthMetrics);
            mouthRenderer.drawRectangle(0, 0, mouthSpec.cols, mouthSpec.rows);
        }
    }
}