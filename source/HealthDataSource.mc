using Toybox.System;
using Toybox.UserProfile;
using Toybox.ActivityMonitor;
using Toybox.SensorHistory;
using Toybox.Activity;
using Toybox.Lang;

// Health snapshot containing all sensor data
class HealthSnapshot {
    var heartRate = null;        // Current heart rate in BPM
    var hrZone = 0;              // Current HR zone (0-5)
    var bodyBattery = -1;        // Body battery level (0-100, -1 if unavailable)
    var stress = -1;             // Stress level (0-100, -1 if unavailable)
    var stepGoalPercent = 0;     // Percentage of step goal achieved
    var moveBar = 0;             // Move bar level (0-5)
    var isActive = false;        // Whether user is in an activity
    var restingHR = null;        // Resting heart rate
    
    function initialize() {
        // All fields initialized above
    }
}

// Data source for health metrics with null-safe access
class HealthDataSource {
    
    function initialize() {
        // No initialization needed
    }
    
    // Get current health snapshot with all available data
    function getSnapshot() {
        var snapshot = new HealthSnapshot();
        
        // Get activity info for HR zone and active state
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null) {
            // Current heart rate from activity
            if (activityInfo.currentHeartRate != null) {
                snapshot.heartRate = activityInfo.currentHeartRate;
            }
            
            // HR Zone (0-5, where 0 is rest, 5 is max)
            if (activityInfo has :currentHeartRateZone && activityInfo.currentHeartRateZone != null) {
                snapshot.hrZone = activityInfo.currentHeartRateZone;
            }
        }
        
        // Get current day stats from ActivityMonitor
        var info = ActivityMonitor.getInfo();
        if (info != null) {
            // Step goal percentage
            var stepGoal = info.stepGoal;
            if (stepGoal != null && stepGoal > 0) {
                var steps = info.steps;
                if (steps != null) {
                    snapshot.stepGoalPercent = (steps * 100) / stepGoal;
                }
            }
            
            // Move bar level (0-5, where 5 means need to move)
            if (info has :moveBarLevel && info.moveBarLevel != null) {
                snapshot.moveBar = info.moveBarLevel;
            }
        }
        
        // Get body battery from SensorHistory
        if (Toybox has :SensorHistory && SensorHistory has :getBodyBatteryHistory) {
            var bbIterator = SensorHistory.getBodyBatteryHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
            if (bbIterator != null) {
                var sample = bbIterator.next();
                if (sample != null && sample.data != null) {
                    snapshot.bodyBattery = sample.data;
                }
            }
        }
        
        // Get stress level from SensorHistory
        if (Toybox has :SensorHistory && SensorHistory has :getStressHistory) {
            var stressIterator = SensorHistory.getStressHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
            if (stressIterator != null) {
                var sample = stressIterator.next();
                if (sample != null && sample.data != null) {
                    snapshot.stress = sample.data;
                }
            }
        }
        
        // Get user profile for resting HR
        var profile = UserProfile.getProfile();
        if (profile != null && profile has :restingHeartRate) {
            snapshot.restingHR = profile.restingHeartRate;
        }
        
        // Determine if user is active based on HR zone
        snapshot.isActive = (snapshot.hrZone >= 1);
        
        return snapshot;
    }
    
    // Check if health features are available on this device
    function isHealthAvailable() {
        // Check for basic health support
        var hasActivityMonitor = (Toybox has :ActivityMonitor);
        var hasSensorHistory = (Toybox has :SensorHistory);
        
        return hasActivityMonitor && hasSensorHistory;
    }
    
    // Get a debug string representation of current health data
    function getDebugString() {
        var snapshot = getSnapshot();
        var debugStr = "HR:" + (snapshot.heartRate != null ? snapshot.heartRate : "--") + 
                      " Z:" + snapshot.hrZone +
                      " BB:" + (snapshot.bodyBattery >= 0 ? snapshot.bodyBattery : "--") +
                      " S:" + (snapshot.stress >= 0 ? snapshot.stress : "--") +
                      " Step:" + snapshot.stepGoalPercent + "%" +
                      " Move:" + snapshot.moveBar;
        return debugStr;
    }
}