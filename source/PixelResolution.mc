using Toybox.Graphics;
using Toybox.Math;

module PixelResolution {
    
    class GridSpec {
        var cols;
        var rows;
        
        function initialize(c, r) {
            self.cols = c;
            self.rows = r;
        }
    }
    
    class PixelMetrics {
        var blockSize;
        var gap;
        var originX;
        var originY;
        
        function initialize(block, g, x, y) {
            self.blockSize = block;
            self.gap = g;
            self.originX = x;
            self.originY = y;
        }
        
        function getCellX(col) {
            return originX + col * (blockSize + gap);
        }
        
        function getCellY(row) {
            return originY + row * (blockSize + gap);
        }
        
        function getTotalWidth(cols) {
            return cols * blockSize + (cols - 1) * gap;
        }
        
        function getTotalHeight(rows) {
            return rows * blockSize + (rows - 1) * gap;
        }
    }
    
    class ResolutionManager {
        var baseWidth = 260.0;  // Baseline design width (fenix7)
        var baseBlockSize = 5;   // Base block size at baseline
        var baseGap = 1;         // Base gap at baseline
        
        var blockSize;
        var gap;
        
        function initialize() {
        }
        
        function updateScale(dc) {
            var currentWidth = dc.getWidth();
            var scale = currentWidth / baseWidth;
            
            blockSize = Math.round(baseBlockSize * scale);
            if (blockSize < 1) { blockSize = 1; }
            
            gap = Math.round(baseGap * scale);
            if (gap < 0) { gap = 0; }
        }
        
        function dp(pixels, dc) {
            var currentWidth = dc.getWidth();
            var scale = currentWidth / baseWidth;
            var result = Math.round(pixels * scale);
            if (result < 1) { result = 1; }
            return result;
        }
        
        function setBlockSize(size) {
            self.blockSize = size;
        }
        
        function setGap(g) {
            self.gap = g;
        }
        
        function centerGrid(screenWidth, screenHeight, gridSpec) {
            var metrics = new PixelMetrics(blockSize, gap, 0, 0);
            var totalWidth = metrics.getTotalWidth(gridSpec.cols);
            var totalHeight = metrics.getTotalHeight(gridSpec.rows);
            
            metrics.originX = (screenWidth - totalWidth) / 2;
            metrics.originY = (screenHeight - totalHeight) / 2;
            
            return metrics;
        }
        
        function positionGrid(x, y) {
            return new PixelMetrics(blockSize, gap, x, y);
        }
    }
    
    class PixelRenderer {
        var dc;
        var metrics;
        
        function initialize(drawContext, pixelMetrics) {
            self.dc = drawContext;
            self.metrics = pixelMetrics;
        }
        
        function drawGrid(gridSpec, pattern) {
            for (var row = 0; row < gridSpec.rows; row++) {
                for (var col = 0; col < gridSpec.cols; col++) {
                    if (pattern == null || (pattern[row] != null && pattern[row][col] == 1)) {
                        dc.fillRectangle(
                            metrics.getCellX(col),
                            metrics.getCellY(row),
                            metrics.blockSize,
                            metrics.blockSize
                        );
                    }
                }
            }
        }
        
        function drawRectangle(startCol, startRow, cols, rows) {
            for (var row = 0; row < rows; row++) {
                for (var col = 0; col < cols; col++) {
                    dc.fillRectangle(
                        metrics.getCellX(startCol + col),
                        metrics.getCellY(startRow + row),
                        metrics.blockSize,
                        metrics.blockSize
                    );
                }
            }
        }
    }
}