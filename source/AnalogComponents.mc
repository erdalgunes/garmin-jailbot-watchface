using Toybox.Graphics;
using Toybox.Math;

module AnalogClock {
    
    // Single Responsibility: Each hand type has its own class
    class HourHand {
        var length;
        var width;
        var color;
        
        function setup(radius) {
            length = radius * 0.50;  // 50% of radius per classic proportions
            width = 3;               // Widest hand
            color = Graphics.COLOR_RED;
        }
        
        function draw(dc, centerX, centerY, angle) {
            // YAGNI: Show only outer third of hand for minimalist design
            var endX = centerX + length * Math.sin(angle);
            var endY = centerY - length * Math.cos(angle);
            var startX = centerX + (length * 0.67) * Math.sin(angle); // Start at 67% from center
            var startY = centerY - (length * 0.67) * Math.cos(angle);
            
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(width);
            dc.drawLine(startX, startY, endX, endY);
        }
        
        function calculateAngle(hours, minutes) {
            // Hour hand moves continuously, not in discrete steps
            var totalMinutes = (hours % 12) * 60 + minutes;
            return (totalMinutes / 720.0) * 2 * Math.PI; // 720 = 12 * 60
        }
    }
    
    class MinuteHand {
        var length;
        var width;
        var color;
        
        function setup(radius) {
            length = radius * 0.90;  // 90% of radius to reach minute track
            width = 2;               // Medium width
            color = Graphics.COLOR_RED;
        }
        
        function draw(dc, centerX, centerY, angle) {
            // YAGNI: Show only outer third of hand for minimalist design
            var endX = centerX + length * Math.sin(angle);
            var endY = centerY - length * Math.cos(angle);
            var startX = centerX + (length * 0.67) * Math.sin(angle); // Start at 67% from center
            var startY = centerY - (length * 0.67) * Math.cos(angle);
            
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(width);
            dc.drawLine(startX, startY, endX, endY);
        }
        
        function calculateAngle(minutes, seconds) {
            // Minute hand moves continuously with seconds
            var totalSeconds = minutes * 60 + seconds;
            return (totalSeconds / 3600.0) * 2 * Math.PI; // 3600 = 60 * 60
        }
    }
    
    class SecondHand {
        var length;
        var width;
        var color;
        
        function setup(radius) {
            length = radius * 0.95;  // 95% of radius
            width = 1;               // Thinnest hand
            color = Graphics.COLOR_WHITE;
        }
        
        function draw(dc, centerX, centerY, angle) {
            // YAGNI: Show only outer third of hand for minimalist design
            var endX = centerX + length * Math.sin(angle);
            var endY = centerY - length * Math.cos(angle);
            var startX = centerX + (length * 0.67) * Math.sin(angle); // Start at 67% from center
            var startY = centerY - (length * 0.67) * Math.cos(angle);
            
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(width);
            dc.drawLine(startX, startY, endX, endY);
        }
        
        function calculateAngle(seconds) {
            return (seconds / 60.0) * 2 * Math.PI;
        }
    }
    
    // Interface Segregation: Separate rim indicators from hands
    class RimIndicators {
        var centerX;
        var centerY;
        var radius;
        var hourMarkLength;
        var minuteMarkLength;
        
        function setup(x, y, r) {
            centerX = x;
            centerY = y;
            radius = r;
            hourMarkLength = r * 0.12;    // Hour marks 12% of radius
            minuteMarkLength = r * 0.06;  // Minute marks 6% of radius
        }
        
        function draw(dc) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            
            // KISS: Draw only essential markers - 12 and 3/6/9 positions
            // Strong 12 o'clock marker
            drawStrongMark(dc, 0);
            
            // Secondary markers at 3, 6, 9
            drawSecondaryMark(dc, Math.PI / 2);  // 3 o'clock
            drawSecondaryMark(dc, Math.PI);      // 6 o'clock  
            drawSecondaryMark(dc, 3 * Math.PI / 2); // 9 o'clock
        }
        
        
        function drawStrongMark(dc, angle) {
            // 12 o'clock: Strong, long marker
            var outerRadius = radius * 0.95;
            var innerRadius = outerRadius - (radius * 0.08); // 8% of radius
            
            var outerX = centerX + outerRadius * Math.sin(angle);
            var outerY = centerY - outerRadius * Math.cos(angle);
            var innerX = centerX + innerRadius * Math.sin(angle);
            var innerY = centerY - innerRadius * Math.cos(angle);
            
            dc.setPenWidth(3); // Thick for strong marker
            dc.drawLine(innerX, innerY, outerX, outerY);
        }
        
        function drawSecondaryMark(dc, angle) {
            // 3/6/9 o'clock: Shorter, thinner markers
            var outerRadius = radius * 0.95;
            var innerRadius = outerRadius - (radius * 0.04); // 4% of radius
            
            var outerX = centerX + outerRadius * Math.sin(angle);
            var outerY = centerY - outerRadius * Math.cos(angle);
            var innerX = centerX + innerRadius * Math.sin(angle);
            var innerY = centerY - innerRadius * Math.cos(angle);
            
            dc.setPenWidth(1); // Thinner for secondary markers
            dc.drawLine(innerX, innerY, outerX, outerY);
        }
    }
    
    // Dependency Inversion: Abstract clock face that can be extended
    class AnalogClockFace {
        var hourHand;
        var minuteHand;
        var secondHand;
        var rimIndicators;
        var centerX;
        var centerY;
        var radius;
        
        function initialize(x, y, r) {
            centerX = x;
            centerY = y;
            radius = r;
            
            hourHand = new HourHand();
            hourHand.setup(radius);
            
            minuteHand = new MinuteHand();
            minuteHand.setup(radius);
            
            secondHand = new SecondHand();
            secondHand.setup(radius);
            
            rimIndicators = new RimIndicators();
            rimIndicators.setup(centerX, centerY, radius);
        }
        
        function draw(dc, hours, minutes, seconds) {
            // Draw rim indicators first (background)
            rimIndicators.draw(dc);
            
            // Draw hands in order (hour, minute, second on top)
            var hourAngle = hourHand.calculateAngle(hours, minutes);
            var minuteAngle = minuteHand.calculateAngle(minutes, seconds);
            var secondAngle = secondHand.calculateAngle(seconds);
            
            hourHand.draw(dc, centerX, centerY, hourAngle);
            minuteHand.draw(dc, centerX, centerY, minuteAngle);
            secondHand.draw(dc, centerX, centerY, secondAngle);
            
            // YAGNI: No center dot for minimal design - clean center
        }
    }
}