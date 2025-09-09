using Toybox.System;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Graphics;

// SOLID Architecture for Emoticon Expression System
// Single Responsibility - parameter-based expression building

// Core expression parameter container
class ExpressionParams {
    // Eye parameters
    var eyeShape;        // "dot", "oval", "line", "winkLeft", "winkRight", "X", "circle", "arcUp", "arcDown", "heart"
    var eyeWidth;        // 0.8-1.4 scale factor
    var eyeHeight;       // 0.6-1.3 scale factor
    var eyeRadius;       // 0.2-0.5 roundedness
    var eyeSeparation;   // 0.3-0.5 distance between eyes
    var eyeAsymmetry;    // 0-0.1 size difference for personality
    var eyeOpenness;     // 0-1 eyelid state (0=closed, 1=open)
    
    // Mouth parameters
    var mouthShape;      // "flat", "curve", "open", "grin", "frown", "smirk", "cat3", "oShock", "tongueOut"
    var mouthWidth;      // 0.4-1.4 scale factor
    var mouthHeight;     // 0.2-0.8 scale factor
    var mouthRadius;     // 0.1-0.5 roundedness
    var mouthCurvature;  // -1 to +1 (negative=frown, positive=smile)
    var mouthOpenness;   // 0-1 how open the mouth is
    
    // Accessory parameters
    var showTears;       // boolean
    var tearSize;        // 0-0.1 size of tear drops
    var showBlush;       // boolean
    var blushIntensity;  // 0-1 intensity of blush
    var showTongue;      // boolean
    var tongueSize;      // 0-0.3 tongue protrusion
    
    // Animation parameters
    var blinkRate;       // 2-8 seconds between blinks
    var blinkDuration;   // 80-200ms blink length
    var expressionIntensity; // 0-1 overall intensity multiplier
    
    function initialize() {
        // Default neutral expression
        self.eyeShape = "dot";
        self.eyeWidth = 1.0;
        self.eyeHeight = 1.0;
        self.eyeRadius = 0.3;
        self.eyeSeparation = 0.38;
        self.eyeAsymmetry = 0.0;
        self.eyeOpenness = 1.0;
        
        self.mouthShape = "flat";
        self.mouthWidth = 1.0;
        self.mouthHeight = 0.3;
        self.mouthRadius = 0.4;
        self.mouthCurvature = 0.0;
        self.mouthOpenness = 0.0;
        
        self.showTears = false;
        self.tearSize = 0.06;
        self.showBlush = false;
        self.blushIntensity = 0.2;
        self.showTongue = false;
        self.tongueSize = 0.2;
        
        self.blinkRate = 4.2;
        self.blinkDuration = 100;
        self.expressionIntensity = 0.5;
    }
}

// Emoticon parser - converts ASCII emoticons to parameter sets
class EmoticonParser {
    function initialize() {
        // Constructor
    }
    
    function parseEmoticon(emoticon) {
        var params = new ExpressionParams();
        var emotStr = emoticon.toString();
        
        // Base emoticon patterns
        if (emotStr.equals(":)") || emotStr.equals(":-)")) {
            self.applyHappy(params);
        } else if (emotStr.equals(":(") || emotStr.equals(":-(")) {
            self.applySad(params);
        } else if (emotStr.equals(":d")) {
            self.applyGrin(params);
        } else if (emotStr.equals(":p")) {
            self.applyTongue(params);
        } else if (emotStr.equals(";)")) {
            self.applyWink(params);
        } else if (emotStr.equals("xd")) {
            self.applyLaugh(params);
        } else if (emotStr.equals(":'(")) {
            self.applyCrying(params);
        } else if (emotStr.equals(":|")) {
            self.applyNeutral(params);
        } else if (emotStr.equals(":o")) {
            self.applyShock(params);
        } else if (emotStr.equals("-_-")) {
            self.applyUnimpressed(params);
        } else if (emotStr.equals("^_^")) {
            self.applyJoy(params);
        } else if (emotStr.equals("o_o")) {
            self.applyConfused(params);
        } else if (emotStr.equals(">:(")) {
            self.applyAngry(params);
        } else if (emotStr.equals(":3")) {
            self.applyCat(params);
        } else if (emotStr.equals("<3")) {
            self.applyLove(params);
        }
        
        return params;
    }
    
    private function applyHappy(params) {
        params.mouthShape = "curve";
        params.mouthCurvature = 0.5;
        params.mouthWidth = 1.2;
        params.expressionIntensity = 0.7;
    }
    
    private function applySad(params) {
        params.mouthShape = "curve";
        params.mouthCurvature = -0.5;
        params.mouthWidth = 1.2;
        params.eyeHeight = 0.9;
        params.expressionIntensity = 0.6;
    }
    
    private function applyGrin(params) {
        params.mouthShape = "grin";
        params.mouthWidth = 1.4;
        params.mouthHeight = 0.4;
        params.mouthOpenness = 0.3;
        params.eyeWidth = 1.2;
        params.eyeHeight = 1.1;
        params.expressionIntensity = 0.9;
    }
    
    private function applyTongue(params) {
        params.mouthShape = "tongueOut";
        params.mouthWidth = 1.1;
        params.mouthOpenness = 0.4;
        params.showTongue = true;
        params.tongueSize = 0.25;
        params.expressionIntensity = 0.8;
    }
    
    private function applyWink(params) {
        params.eyeShape = "winkLeft";
        params.mouthShape = "smirk";
        params.mouthCurvature = 0.3;
        params.mouthWidth = 1.1;
        params.eyeAsymmetry = 0.15;
        params.expressionIntensity = 0.7;
    }
    
    private function applyLaugh(params) {
        params.eyeShape = "X";
        params.mouthShape = "grin";
        params.mouthWidth = 1.4;
        params.mouthHeight = 0.5;
        params.mouthOpenness = 0.4;
        params.expressionIntensity = 1.0;
    }
    
    private function applyCrying(params) {
        params.mouthShape = "curve";
        params.mouthCurvature = -0.6;
        params.mouthWidth = 1.1;
        params.showTears = true;
        params.tearSize = 0.08;
        params.eyeHeight = 0.8;
        params.expressionIntensity = 0.8;
    }
    
    private function applyNeutral(params) {
        params.mouthShape = "flat";
        params.mouthWidth = 1.0;
        params.expressionIntensity = 0.3;
    }
    
    private function applyShock(params) {
        params.eyeShape = "circle";
        params.eyeWidth = 1.2;
        params.eyeHeight = 1.3;
        params.mouthShape = "oShock";
        params.mouthWidth = 0.6;
        params.mouthHeight = 0.7;
        params.mouthOpenness = 0.8;
        params.expressionIntensity = 0.9;
    }
    
    private function applyUnimpressed(params) {
        params.eyeShape = "line";
        params.eyeHeight = 0.3;
        params.mouthShape = "flat";
        params.mouthWidth = 0.8;
        params.expressionIntensity = 0.4;
    }
    
    private function applyJoy(params) {
        params.eyeShape = "arcUp";
        params.eyeWidth = 1.1;
        params.eyeHeight = 1.2;
        params.mouthShape = "curve";
        params.mouthCurvature = 0.7;
        params.mouthWidth = 1.3;
        params.showBlush = true;
        params.blushIntensity = 0.3;
        params.expressionIntensity = 0.9;
    }
    
    private function applyConfused(params) {
        params.eyeShape = "circle";
        params.eyeWidth = 1.0;
        params.eyeHeight = 1.1;
        params.eyeAsymmetry = 0.1;
        params.mouthShape = "curve";
        params.mouthCurvature = 0.1;
        params.mouthWidth = 0.9;
        params.expressionIntensity = 0.5;
    }
    
    private function applyAngry(params) {
        params.eyeShape = "line";
        params.eyeWidth = 0.9;
        params.eyeHeight = 1.2;
        params.eyeOpenness = 0.8;
        params.mouthShape = "frown";
        params.mouthCurvature = -0.7;
        params.mouthWidth = 1.0;
        params.expressionIntensity = 0.9;
    }
    
    private function applyCat(params) {
        params.mouthShape = "cat3";
        params.mouthWidth = 0.7;
        params.mouthHeight = 0.25;
        params.eyeWidth = 1.1;
        params.expressionIntensity = 0.6;
    }
    
    private function applyLove(params) {
        params.eyeShape = "heart";
        params.eyeWidth = 1.0;
        params.eyeHeight = 1.0;
        params.mouthShape = "curve";
        params.mouthCurvature = 0.6;
        params.mouthWidth = 1.2;
        params.showBlush = true;
        params.blushIntensity = 0.4;
        params.expressionIntensity = 0.8;
    }
}

// Enhanced expression renderer with emoticon support
class EmoticonRenderer {
    private var parser;
    
    function initialize() {
        self.parser = new EmoticonParser();
    }
    
    function renderEmoticon(dc, emoticon, centerX, centerY, faceSize) {
        var params = self.parser.parseEmoticon(emoticon);
        self.drawExpression(dc, params, centerX, centerY, faceSize);
    }
    
    function drawExpression(dc, params, centerX, centerY, faceSize) {
        // Calculate base dimensions
        var baseEyeWidth = (faceSize / 5);
        var baseEyeHeight = (faceSize / 10);
        var baseMouthWidth = (faceSize / 2.5);
        var baseMouthHeight = (faceSize / 12);
        
        // Eye positions
        var eyeY = centerY - faceSize / 8;
        var eyeSep = (faceSize / 6) * params.eyeSeparation / 0.38; // Normalize to default
        var leftEyeX = centerX - eyeSep;
        var rightEyeX = centerX + eyeSep;
        
        // Draw eyes based on shape
        self.drawEyes(dc, params, leftEyeX, rightEyeX, eyeY, baseEyeWidth, baseEyeHeight);
        
        // Draw mouth
        var mouthY = centerY + faceSize / 12;
        self.drawMouth(dc, params, centerX, mouthY, baseMouthWidth, baseMouthHeight);
        
        // Draw accessories
        self.drawAccessories(dc, params, centerX, centerY, faceSize);
    }
    
    private function drawEyes(dc, params, leftX, rightX, eyeY, baseWidth, baseHeight) {
        var eyeWidth = baseWidth * params.eyeWidth;
        var eyeHeight = baseHeight * params.eyeHeight * params.eyeOpenness;
        var eyeRadius = eyeHeight * params.eyeRadius;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        if (params.eyeShape.equals("dot") || params.eyeShape.equals("circle")) {
            // Standard rounded rectangle eyes
            dc.fillRoundedRectangle(leftX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, eyeRadius);
            dc.fillRoundedRectangle(rightX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, eyeRadius);
            
        } else if (params.eyeShape.equals("winkLeft")) {
            // Left eye closed (wink), right eye normal
            var closedHeight = eyeHeight * 0.2;
            dc.fillRoundedRectangle(leftX - eyeWidth/2, eyeY + (eyeHeight - closedHeight)/2, eyeWidth, closedHeight, eyeRadius);
            dc.fillRoundedRectangle(rightX - eyeWidth/2, eyeY, eyeWidth, eyeHeight, eyeRadius);
            
        } else if (params.eyeShape.equals("line")) {
            // Horizontal line eyes
            var lineHeight = eyeHeight * 0.3;
            dc.fillRoundedRectangle(leftX - eyeWidth/2, eyeY + (eyeHeight - lineHeight)/2, eyeWidth, lineHeight, lineHeight/2);
            dc.fillRoundedRectangle(rightX - eyeWidth/2, eyeY + (eyeHeight - lineHeight)/2, eyeWidth, lineHeight, lineHeight/2);
            
        } else if (params.eyeShape.equals("X")) {
            // X-shaped eyes (laughing)
            self.drawXEyes(dc, leftX, rightX, eyeY, eyeWidth, eyeHeight);
            
        } else if (params.eyeShape.equals("arcUp")) {
            // Happy arc eyes (^_^)
            self.drawArcEyes(dc, leftX, rightX, eyeY, eyeWidth, eyeHeight, true);
            
        } else if (params.eyeShape.equals("heart")) {
            // Heart-shaped eyes
            self.drawHeartEyes(dc, leftX, rightX, eyeY, eyeWidth, eyeHeight);
        }
    }
    
    private function drawXEyes(dc, leftX, rightX, eyeY, width, height) {
        var thickness = height * 0.25;
        var halfWidth = width * 0.4;
        var halfHeight = height * 0.4;
        
        // Left X
        dc.fillRoundedRectangle(leftX - halfWidth, eyeY + halfHeight/2, width * 0.8, thickness, thickness/2);
        dc.fillRoundedRectangle(leftX - halfWidth, eyeY + height - halfHeight/2 - thickness, width * 0.8, thickness, thickness/2);
        
        // Right X  
        dc.fillRoundedRectangle(rightX - halfWidth, eyeY + halfHeight/2, width * 0.8, thickness, thickness/2);
        dc.fillRoundedRectangle(rightX - halfWidth, eyeY + height - halfHeight/2 - thickness, width * 0.8, thickness, thickness/2);
    }
    
    private function drawArcEyes(dc, leftX, rightX, eyeY, width, height, upward) {
        var arcHeight = height * 0.6;
        var y = upward ? eyeY + height - arcHeight : eyeY;
        
        dc.fillRoundedRectangle(leftX - width/2, y, width, arcHeight, arcHeight/2);
        dc.fillRoundedRectangle(rightX - width/2, y, width, arcHeight, arcHeight/2);
    }
    
    private function drawHeartEyes(dc, leftX, rightX, eyeY, width, height) {
        // Simplified heart as two rounded rectangles
        var heartWidth = width * 0.6;
        var heartHeight = height * 0.8;
        
        dc.fillRoundedRectangle(leftX - heartWidth/2, eyeY, heartWidth, heartHeight, heartHeight/3);
        dc.fillRoundedRectangle(rightX - heartWidth/2, eyeY, heartWidth, heartHeight, heartHeight/3);
    }
    
    private function drawMouth(dc, params, centerX, mouthY, baseWidth, baseHeight) {
        var mouthWidth = baseWidth * params.mouthWidth;
        var mouthHeight = baseHeight * params.mouthHeight;
        var mouthRadius = mouthHeight * params.mouthRadius;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        if (params.mouthShape.equals("flat")) {
            // Straight line mouth
            dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, mouthRadius);
            
        } else if (params.mouthShape.equals("curve")) {
            // Curved mouth (smile/frown)
            if (params.mouthCurvature > 0) {
                // Smile - slightly wider, curved upward
                mouthWidth *= 1.1;
                mouthHeight *= (1.0 + params.mouthCurvature * 0.5);
            } else if (params.mouthCurvature < 0) {
                // Frown - narrower, curved downward  
                mouthWidth *= 0.9;
                mouthHeight *= (1.0 - params.mouthCurvature * 0.5);
            }
            dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, mouthRadius);
            
        } else if (params.mouthShape.equals("grin")) {
            // Wide grin with teeth indication
            mouthHeight *= (1.0 + params.mouthOpenness);
            dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, mouthRadius);
            
        } else if (params.mouthShape.equals("oShock")) {
            // Oval shock mouth
            var ovalWidth = mouthWidth * 0.6;
            var ovalHeight = mouthHeight * (1.0 + params.mouthOpenness * 2);
            dc.fillRoundedRectangle(centerX - ovalWidth/2, mouthY, ovalWidth, ovalHeight, ovalWidth/2);
            
        } else if (params.mouthShape.equals("cat3")) {
            // Cat mouth (small curved)
            var catWidth = mouthWidth * 0.5;
            dc.fillRoundedRectangle(centerX - catWidth/2, mouthY, catWidth, mouthHeight, mouthRadius);
            
        } else if (params.mouthShape.equals("tongueOut")) {
            // Mouth with tongue
            dc.fillRoundedRectangle(centerX - mouthWidth/2, mouthY, mouthWidth, mouthHeight, mouthRadius);
            if (params.showTongue) {
                var tongueWidth = mouthWidth * 0.4;
                var tongueHeight = mouthHeight * params.tongueSize * 3;
                var tongueY = mouthY + mouthHeight;
                dc.fillRoundedRectangle(centerX - tongueWidth/2, tongueY, tongueWidth, tongueHeight, tongueWidth/2);
            }
        }
    }
    
    private function drawAccessories(dc, params, centerX, centerY, faceSize) {
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        
        // Tears
        if (params.showTears) {
            var tearSize = faceSize * params.tearSize;
            var tearX = centerX - faceSize / 4;
            var tearY = centerY - faceSize / 12;
            dc.fillRoundedRectangle(tearX, tearY, tearSize, tearSize * 1.5, tearSize/2);
        }
        
        // Blush (simplified as small rectangles)
        if (params.showBlush) {
            var blushSize = faceSize * 0.08 * params.blushIntensity;
            var blushY = centerY + faceSize / 20;
            dc.fillRoundedRectangle(centerX - faceSize/3 - blushSize, blushY, blushSize, blushSize/2, blushSize/4);
            dc.fillRoundedRectangle(centerX + faceSize/3, blushY, blushSize, blushSize/2, blushSize/4);
        }
    }
}