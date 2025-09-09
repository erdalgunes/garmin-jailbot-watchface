using Toybox.System;
using Toybox.ActivityMonitor;
using Toybox.Lang;
using Toybox.Time;

// Health data integration - SOLID Single Responsibility for data gathering
class HealthDataProvider {
    private var lastActivityEndTime;
    private var restingHRBaseline;
    private var stepGoalCache;
    private var achievementFlags;
    
    function initialize() {
        self.lastActivityEndTime = 0;
        self.restingHRBaseline = 60; // Default, will learn over time
        self.stepGoalCache = 10000; // Default
        self.achievementFlags = {
            :stepGoalReached => false,
            :lastStepCount => 0
        };
    }
    
    function gatherSensorData() {
        var sensors = {};
        
        // Get activity monitor info
        var info = ActivityMonitor.getInfo();
        var stats = System.getSystemStats();
        
        // Basic metrics
        sensors[:steps] = info.steps != null ? info.steps : 0;
        sensors[:stepGoal] = info.stepGoal != null ? info.stepGoal : self.stepGoalCache;
        
        // Cache step goal for consistency
        if (info.stepGoal != null && info.stepGoal > 0) {
            self.stepGoalCache = info.stepGoal;
        }
        
        // Heart rate data
        var heartRateData = self.getHeartRateData();
        sensors[:heartRate] = heartRateData[:current];
        sensors[:restingHR] = heartRateData[:resting];
        
        // Stress and Body Battery
        sensors[:stress] = self.getStressLevel();
        sensors[:bodyBattery] = self.getBodyBatteryLevel();
        
        // Activity status
        var activityInfo = self.getActivityStatus();
        sensors[:inActivity] = activityInfo[:active];
        sensors[:postActivity30] = activityInfo[:postActivity30];
        
        // Sleep quality (estimated from available data)
        sensors[:sleepQuality] = self.estimateSleepQuality();
        
        // Achievement detection
        sensors[:achievementEvent] = self.detectAchievements(sensors[:steps], sensors[:stepGoal]);
        
        // AOD status
        sensors[:aod] = self.isInAODMode();
        
        return sensors;
    }
    
    private function getHeartRateData() {
        var currentHR = 70; // Default
        
        try {
            // Use ActivityMonitor info for basic heart rate if available
            var info = ActivityMonitor.getInfo();
            if (info has :heartRate && info.heartRate != null) {
                currentHR = info.heartRate;
            }
        } catch (ex) {
            // Heart rate not available on this device or permission denied
            System.println("HR not available: " + ex.getErrorMessage());
        }
        
        return {
            :current => currentHR,
            :resting => self.restingHRBaseline
        };
    }
    
    private function getStressLevel() {
        // Simplified stress estimation since direct API not available
        // Base on activity level and time patterns
        var stress = self.estimateStressFromActivity();
        return stress;
    }
    
    private function getBodyBatteryLevel() {
        var bodyBattery = 75; // Default
        
        try {
            // Try to get body battery from system stats
            var stats = System.getSystemStats();
            if (stats has :batteryInDays) {
                // Estimate energy from battery level and activity
                bodyBattery = self.estimateBodyBattery();
            }
        } catch (ex) {
            System.println("Body Battery estimation error: " + ex.getErrorMessage());
        }
        
        return bodyBattery;
    }
    
    private function estimateStressFromActivity() {
        var stress = 50; // Baseline moderate
        
        try {
            var info = ActivityMonitor.getInfo();
            var now = System.getClockTime();
            var hour = now.hour;
            
            // Time-based stress patterns
            if (hour >= 9 && hour <= 17) {
                stress += 10; // Work hours slightly higher
            }
            if (hour >= 22 || hour <= 6) {
                stress -= 10; // Night/early morning lower
            }
            
            // Activity-based adjustments
            if (info has :activeMinutesWeek && info.activeMinutesWeek != null) {
                var weeklyActive = info.activeMinutesWeek.total;
                if (weeklyActive > 150) { // WHO recommendation
                    stress -= 15; // Regular activity reduces stress
                }
            }
            
            // Keep in bounds
            if (stress < 0) { stress = 0; }
            if (stress > 100) { stress = 100; }
            
        } catch (ex) {
            System.println("Stress estimation error: " + ex.getErrorMessage());
        }
        
        return stress;
    }
    
    private function estimateBodyBattery() {
        // Simple estimation based on time of day and activity
        var now = System.getClockTime();
        var hour = now.hour;
        
        // Rough daily curve - highest in morning, lowest in evening
        var timeBasedEnergy = 100 - ((hour * 100) / 24);
        
        // Adjust based on activity level (rough proxy)
        var info = ActivityMonitor.getInfo();
        var steps = info.steps != null ? info.steps : 0;
        var stepGoal = info.stepGoal != null ? info.stepGoal : 10000;
        
        var activityAdjustment = 0;
        if (steps > stepGoal * 1.5) {
            activityAdjustment = -20; // High activity drains energy
        } else if (steps < stepGoal * 0.5) {
            activityAdjustment = 5; // Low activity preserves energy
        }
        
        var estimated = timeBasedEnergy + activityAdjustment;
        return estimated < 0 ? 0 : (estimated > 100 ? 100 : estimated);
    }
    
    private function getActivityStatus() {
        var active = false;
        var postActivity30 = false;
        
        // Check if currently in an activity
        // Note: This is simplified - real implementation would use Activity APIs
        try {
            // Rough estimation based on heart rate elevation
            var hrData = self.getHeartRateData();
            var hrElevation = hrData[:current] - hrData[:resting];
            
            // Consider "in activity" if HR is significantly elevated
            active = hrElevation > 15;
            
            // Post-activity detection (simplified)
            var now = System.getTimer();
            if (self.lastActivityEndTime > 0) {
                var timeSinceActivity = now - self.lastActivityEndTime;
                postActivity30 = timeSinceActivity < 1800000; // 30 minutes in milliseconds
            }
            
            // Update activity end time tracking (simplified logic)
            if (!active && self.wasActiveRecently()) {
                self.lastActivityEndTime = now;
            }
            
        } catch (ex) {
            System.println("Activity status error: " + ex.getErrorMessage());
        }
        
        return {
            :active => active,
            :postActivity30 => postActivity30
        };
    }
    
    private function wasActiveRecently() {
        // Simple implementation - could be more sophisticated
        // Check if HR was elevated recently
        return false; // Placeholder
    }
    
    private function estimateSleepQuality() {
        var quality = 0.7; // Default good sleep
        
        try {
            // Estimate based on available data
            var now = System.getClockTime();
            var hour = now.hour;
            
            // Rough estimation: if it's morning and body battery is high, sleep was good
            if (hour >= 6 && hour <= 10) {
                var bodyBattery = self.getBodyBatteryLevel();
                quality = bodyBattery / 100.0;
            } else {
                // Use previous estimate or default
                quality = 0.7;
            }
            
        } catch (ex) {
            System.println("Sleep estimation error: " + ex.getErrorMessage());
        }
        
        return quality;
    }
    
    private function detectAchievements(steps, stepGoal) {
        var achievementDetected = false;
        
        // Step goal achievement
        if (steps >= stepGoal && !self.achievementFlags[:stepGoalReached]) {
            achievementDetected = true;
            self.achievementFlags[:stepGoalReached] = true;
            System.println("Step goal achieved!");
        }
        
        // Reset achievement flag if steps decrease (new day)
        if (steps < self.achievementFlags[:lastStepCount]) {
            self.achievementFlags[:stepGoalReached] = false;
        }
        
        self.achievementFlags[:lastStepCount] = steps;
        
        return achievementDetected;
    }
    
    private function isInAODMode() {
        // Detect if watch is in Always On Display mode
        // This is simplified - actual implementation would check system state
        try {
            var stats = System.getSystemStats();
            // Some devices expose AOD state
            if (stats has :inAOD) {
                return stats.inAOD;
            }
            
            // Fallback: assume AOD if battery is critical or based on time
            return stats.battery < 10;
            
        } catch (ex) {
            return false;
        }
    }
    
    // Learning system for resting heart rate baseline
    function updateRestingHRBaseline(currentHR, isResting) {
        if (isResting && currentHR > 40 && currentHR < 100) {
            // Simple exponential moving average
            var alpha = 0.05; // Learning rate
            self.restingHRBaseline = (alpha * currentHR) + ((1.0 - alpha) * self.restingHRBaseline);
        }
    }
    
    // Debug function to log current sensor values
    function debugSensorData() {
        var sensors = self.gatherSensorData();
        
        System.println("=== Sensor Data ===");
        System.println("Steps: " + sensors[:steps] + "/" + sensors[:stepGoal]);
        System.println("HR: " + sensors[:heartRate] + " (resting: " + sensors[:restingHR] + ")");
        System.println("Stress: " + sensors[:stress]);
        System.println("Body Battery: " + sensors[:bodyBattery]);
        System.println("In Activity: " + sensors[:inActivity]);
        System.println("Post Activity: " + sensors[:postActivity30]);
        System.println("Sleep Quality: " + sensors[:sleepQuality]);
        System.println("Achievement: " + sensors[:achievementEvent]);
        System.println("AOD: " + sensors[:aod]);
        System.println("==================");
    }
}