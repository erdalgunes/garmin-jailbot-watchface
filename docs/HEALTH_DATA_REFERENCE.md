# Garmin Connect IQ Health Data Reference

*A comprehensive guide to accessing health and wellness data in Connect IQ watch faces and applications*

Version: 1.0  
SDK: Connect IQ 3.2+ (with 4.x+ features noted)  
Last Updated: January 2025

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Permission Model](#permission-model)
3. [Activity Monitoring](#activity-monitoring)
4. [Heart Rate & Sensors](#heart-rate--sensors)
5. [User Profile Data](#user-profile-data)
6. [Sleep Data](#sleep-data)
7. [System Information](#system-information)
8. [Device Compatibility](#device-compatibility)
9. [Implementation Examples](#implementation-examples)
10. [Best Practices](#best-practices)

---

## Executive Summary

### Available Health Data Categories

Connect IQ provides access to comprehensive health metrics through several APIs:

- **Activity Data**: Steps, calories, distance, floors, intensity minutes
- **Biometric Sensors**: Heart rate, body battery, stress, SpO2
- **User Profile**: Demographics, fitness level, heart rate zones
- **Sleep Tracking**: Sleep stages, duration, quality metrics
- **Environmental**: Temperature, altitude, pressure
- **System**: Battery, memory, GPS location

### Why Health Data Matters for Watch Faces

1. **Personalization**: Adapt display based on user's activity level and health status
2. **Motivation**: Show progress toward daily goals at a glance
3. **Context**: Provide relevant information based on current physiological state
4. **Insights**: Surface trends and patterns in health metrics

### SDK Requirements

| Feature | Minimum SDK | Notes |
|---------|-------------|-------|
| Basic Activity | 1.4+ | Steps, calories, distance |
| Heart Rate | 2.4+ | Requires OHR sensor |
| Intensity Minutes | 3.0+ | Weekly aggregates |
| Body Battery | 4.0+ | Device-specific |
| Stress | 4.0+ | Device-specific |
| SpO2 | 3.2+ | User must enable |

---

## Permission Model

### Required Permissions in manifest.xml

```xml
<iq:permissions>
    <!-- Activity monitoring data -->
    <iq:uses-permission id="Activity"/>
    
    <!-- Heart rate sensor -->
    <iq:uses-permission id="Sensor"/>
    <iq:uses-permission id="SensorHistory"/>
    
    <!-- User profile information -->
    <iq:uses-permission id="UserProfile"/>
    
    <!-- Positioning/GPS (if needed) -->
    <iq:uses-permission id="Positioning"/>
    
    <!-- Communications (for web requests) -->
    <iq:uses-permission id="Communications"/>
</iq:permissions>
```

### Permission Descriptions

| Permission | Grants Access To | User Consent Required |
|------------|------------------|----------------------|
| `Activity` | Steps, calories, distance, floors | No |
| `Sensor` | Heart rate, body sensors | Yes |
| `SensorHistory` | Historical sensor data | Yes |
| `UserProfile` | Age, weight, height, zones | Yes |
| `Positioning` | GPS location, speed | Yes |
| `Communications` | Internet connectivity | Yes |

---

## Activity Monitoring

### ActivityMonitor.Info Object

Access daily activity metrics through `ActivityMonitor.getInfo()`:

```monkeyc
using Toybox.ActivityMonitor;

var info = ActivityMonitor.getInfo();
```

### Available Metrics

| Method | Returns | Description | Units |
|--------|---------|-------------|-------|
| `steps` | Number | Steps taken today | count |
| `stepGoal` | Number | User's daily step goal | count |
| `calories` | Number | Calories burned today | kcal |
| `distance` | Float | Distance traveled today | centimeters |
| `floorsClimbed` | Number | Floors ascended | count |
| `floorsDescended` | Number | Floors descended | count |
| `floorsClimbedGoal` | Number | Daily floors goal | count |
| `activeMinutesDay` | ActiveMinutes | Today's active minutes | object |
| `activeMinutesWeek` | ActiveMinutes | Week's active minutes | object |
| `moveBarLevel` | Number | Inactivity level (0-5) | level |

### ActiveMinutes Object

```monkeyc
class ActiveMinutes {
    var moderate;        // Moderate intensity minutes
    var vigorous;        // Vigorous intensity minutes
    var total;          // Total active minutes
    var goal;           // Daily/weekly goal
}
```

### Move Bar Levels

| Level | Meaning | Action Required |
|-------|---------|-----------------|
| 0 | No alert | Active recently |
| 1 | Initial alert | Walk for 2 minutes |
| 2 | Increased alert | Walk for 3 minutes |
| 3-5 | Maximum alert | Extended inactivity |

---

## Heart Rate & Sensors

### Current Heart Rate

```monkeyc
using Toybox.Sensor;
using Toybox.Activity;

// Method 1: Direct sensor access
var heartRate = Sensor.getInfo().heartRate;

// Method 2: From activity info (if available)
var activityInfo = Activity.getActivityInfo();
if (activityInfo != null) {
    heartRate = activityInfo.currentHeartRate;
}
```

### Sensor.Info Object

Access through `Sensor.getInfo()`:

| Property | Type | Description | Range/Units |
|----------|------|-------------|-------------|
| `heartRate` | Number\|null | Current HR | BPM |
| `altitude` | Float\|null | Current altitude | meters |
| `pressure` | Float\|null | Barometric pressure | Pa |
| `temperature` | Float\|null | Temperature | Celsius |
| `speed` | Float\|null | Current speed | m/s |
| `cadence` | Number\|null | Step/pedal cadence | RPM |
| `power` | Number\|null | Power output | watts |
| `heading` | Float\|null | Compass heading | radians |

### Advanced Biometrics (Device-Specific)

```monkeyc
// Body Battery (energy level)
var bodyBattery = null;
if (Sensor has :getBodyBatteryInfo) {
    var bbInfo = Sensor.getBodyBatteryInfo();
    if (bbInfo != null) {
        bodyBattery = bbInfo.level; // 0-100
    }
}

// Stress Level
var stress = null;
if (Sensor has :getStressInfo) {
    var stressInfo = Sensor.getStressInfo();
    if (stressInfo != null) {
        stress = stressInfo.stress; // 0-100
    }
}

// Pulse Ox (SpO2)
var spo2 = null;
if (Sensor has :getPulseOxInfo) {
    var oxInfo = Sensor.getPulseOxInfo();
    if (oxInfo != null) {
        spo2 = oxInfo.percent; // SpO2 percentage
    }
}
```

### Heart Rate Zones

```monkeyc
using Toybox.UserProfile;

// Get zone boundaries
var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
// Returns array: [zone1Max, zone2Max, zone3Max, zone4Max, zone5Max]

// Determine current zone
function getHRZone(heartRate, zones) {
    if (heartRate == null || zones == null) { return 0; }
    
    for (var i = 0; i < zones.size(); i++) {
        if (heartRate < zones[i]) {
            return i + 1; // Zones are 1-indexed
        }
    }
    return zones.size() + 1; // Max zone
}
```

---

## User Profile Data

### UserProfile Methods

```monkeyc
using Toybox.UserProfile;

var profile = UserProfile.getProfile();
```

| Method | Returns | Description | Units/Type |
|--------|---------|-------------|------------|
| `height` | Float | User height | cm |
| `weight` | Number | User weight | grams |
| `age` | Number | User age | years |
| `gender` | Number | Gender | GENDER_MALE/FEMALE |
| `activityClass` | Number | Fitness level | 0-100 |
| `restingHeartRate` | Number | Resting HR | BPM |
| `vo2Max` | Number\|null | VO2 max estimate | ml/kg/min |
| `birthYear` | Number | Birth year | year |

### Fitness Level Classification

| Activity Class | Description |
|----------------|-------------|
| 0-20 | Sedentary |
| 21-40 | Lightly Active |
| 41-60 | Active |
| 61-80 | Very Active |
| 81-100 | Extremely Active |

---

## Sleep Data

### Sleep Monitoring (Limited Access)

Note: Full sleep data is typically not available to watch faces during runtime. Limited access through:

```monkeyc
using Toybox.SensorHistory;

// Get recent sleep history (if available)
if (Toybox has :SensorHistory) {
    var iterator = SensorHistory.getHeartRateHistory({
        :period => 1,
        :order => SensorHistory.ORDER_NEWEST_FIRST
    });
    
    // Analyze HR patterns for sleep detection
    // Low, stable HR often indicates sleep
}
```

### Sleep Detection Heuristics

For watch faces, sleep state can be inferred:

```monkeyc
function isSleeping(heartRate, activityInfo, currentHour) {
    // Simple heuristic
    var isNightTime = (currentHour >= 22 || currentHour <= 6);
    var lowHR = (heartRate != null && heartRate < 60);
    var noActivity = (activityInfo.moveBarLevel == 0);
    
    return isNightTime && lowHR && noActivity;
}
```

---

## System Information

### System Stats

```monkeyc
using Toybox.System;

var stats = System.getSystemStats();
```

| Property | Type | Description | Units |
|----------|------|-------------|-------|
| `battery` | Float | Battery level | percentage |
| `batteryInDays` | Float\|null | Estimated battery life | days |
| `charging` | Boolean | Charging status | true/false |
| `solarIntensity` | Number\|null | Solar charging level | 0-100 |
| `totalMemory` | Number | Total memory | bytes |
| `usedMemory` | Number | Used memory | bytes |
| `freeMemory` | Number | Available memory | bytes |

### Device Settings

```monkeyc
var settings = System.getDeviceSettings();

// Available properties:
settings.is24Hour;           // Time format
settings.distanceUnits;      // UNIT_METRIC/UNIT_STATUTE
settings.heightUnits;        // UNIT_METRIC/UNIT_STATUTE  
settings.weightUnits;        // UNIT_METRIC/UNIT_STATUTE
settings.paceUnits;          // UNIT_METRIC/UNIT_STATUTE
settings.temperatureUnits;   // UNIT_CELSIUS/UNIT_FAHRENHEIT
settings.phoneConnected;     // Phone connection status
settings.alarmCount;         // Number of alarms set
settings.notificationCount;  // Pending notifications
settings.tonesOn;           // Sound enabled
settings.vibrateOn;         // Vibration enabled
```

---

## Device Compatibility

### Feature Availability Matrix

| Feature | Fenix 7 | FR965 | FR265 | Venu 3 | Instinct 2 | Notes |
|---------|---------|-------|-------|--------|------------|-------|
| Steps/Calories | ✅ | ✅ | ✅ | ✅ | ✅ | Universal |
| Heart Rate | ✅ | ✅ | ✅ | ✅ | ✅ | All have OHR |
| Body Battery | ✅ | ✅ | ✅ | ✅ | ✅ | Firstbeat |
| Stress | ✅ | ✅ | ✅ | ✅ | ✅ | Firstbeat |
| Pulse Ox | ✅ | ✅ | ✅ | ✅ | ❌ | Hardware dependent |
| Floors | ✅ | ✅ | ✅ | ✅ | ✅ | Barometer required |
| Temperature | ✅ | ✅ | ❌ | ❌ | ✅ | Sensor dependent |
| Solar Intensity | Some | ❌ | ❌ | ❌ | Some | Solar models only |

### Runtime Feature Detection

```monkeyc
// Check for feature availability
function hasBodyBattery() {
    return (Sensor has :getBodyBatteryInfo);
}

function hasPulseOx() {
    return (Sensor has :getPulseOxInfo);
}

function hasBarometer() {
    var pressure = Sensor.getInfo().pressure;
    return (pressure != null);
}

// Safe access pattern
function getSafeBodyBattery() {
    if (Sensor has :getBodyBatteryInfo) {
        var info = Sensor.getBodyBatteryInfo();
        if (info != null && info.level != null) {
            return info.level;
        }
    }
    return null;
}
```

---

## Implementation Examples

### Complete Health Widget Example

```monkeyc
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.ActivityMonitor;
using Toybox.Sensor;
using Toybox.UserProfile;

class HealthDataView extends WatchUi.View {
    
    hidden var mHealthData;
    
    function initialize() {
        View.initialize();
        mHealthData = {};
    }
    
    function onUpdate(dc) {
        // Gather all health data
        collectHealthData();
        
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Display health metrics
        var y = 30;
        var lineHeight = 25;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Steps
        dc.drawText(120, y, Graphics.FONT_SMALL, 
            "Steps: " + mHealthData[:steps] + "/" + mHealthData[:stepGoal], 
            Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        // Heart Rate
        var hrText = "HR: ";
        if (mHealthData[:heartRate] != null) {
            hrText += mHealthData[:heartRate] + " bpm";
        } else {
            hrText += "--";
        }
        dc.drawText(120, y, Graphics.FONT_SMALL, hrText, 
            Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        // Body Battery
        if (mHealthData[:bodyBattery] != null) {
            dc.drawText(120, y, Graphics.FONT_SMALL, 
                "Battery: " + mHealthData[:bodyBattery] + "%", 
                Graphics.TEXT_JUSTIFY_CENTER);
            y += lineHeight;
        }
        
        // Stress
        if (mHealthData[:stress] != null) {
            dc.drawText(120, y, Graphics.FONT_SMALL, 
                "Stress: " + mHealthData[:stress], 
                Graphics.TEXT_JUSTIFY_CENTER);
            y += lineHeight;
        }
        
        // Calories
        dc.drawText(120, y, Graphics.FONT_SMALL, 
            "Calories: " + mHealthData[:calories], 
            Graphics.TEXT_JUSTIFY_CENTER);
        y += lineHeight;
        
        // Distance
        var km = mHealthData[:distance] / 100000.0;
        dc.drawText(120, y, Graphics.FONT_SMALL, 
            "Distance: " + km.format("%.2f") + " km", 
            Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function collectHealthData() {
        // Activity data
        var activityInfo = ActivityMonitor.getInfo();
        if (activityInfo != null) {
            mHealthData[:steps] = activityInfo.steps;
            mHealthData[:stepGoal] = activityInfo.stepGoal;
            mHealthData[:calories] = activityInfo.calories;
            mHealthData[:distance] = activityInfo.distance;
            mHealthData[:floors] = activityInfo.floorsClimbed;
            mHealthData[:moveBar] = activityInfo.moveBarLevel;
        }
        
        // Sensor data
        var sensorInfo = Sensor.getInfo();
        if (sensorInfo != null) {
            mHealthData[:heartRate] = sensorInfo.heartRate;
        }
        
        // Body Battery (if available)
        if (Sensor has :getBodyBatteryInfo) {
            var bbInfo = Sensor.getBodyBatteryInfo();
            if (bbInfo != null) {
                mHealthData[:bodyBattery] = bbInfo.level;
            }
        }
        
        // Stress (if available)
        if (Sensor has :getStressInfo) {
            var stressInfo = Sensor.getStressInfo();
            if (stressInfo != null) {
                mHealthData[:stress] = stressInfo.stress;
            }
        }
        
        // User profile
        var profile = UserProfile.getProfile();
        if (profile != null) {
            mHealthData[:restingHR] = profile.restingHeartRate;
        }
    }
}
```

### Goal Progress Arc

```monkeyc
function drawGoalArc(dc, centerX, centerY, radius, current, goal) {
    var percentage = (current.toFloat() / goal.toFloat());
    if (percentage > 1.0) { percentage = 1.0; }
    
    var startAngle = 90;  // Start at top
    var endAngle = 90 - (360 * percentage);
    
    // Background arc
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(10);
    dc.drawArc(centerX, centerY, radius, 
        Graphics.ARC_CLOCKWISE, 90, -270);
    
    // Progress arc
    var color = Graphics.COLOR_GREEN;
    if (percentage < 0.5) { color = Graphics.COLOR_RED; }
    else if (percentage < 0.8) { color = Graphics.COLOR_YELLOW; }
    
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawArc(centerX, centerY, radius, 
        Graphics.ARC_CLOCKWISE, startAngle, endAngle);
}
```

---

## Best Practices

### 1. Null Safety

Always check for null values:

```monkeyc
function getSafeHeartRate() {
    var info = Sensor.getInfo();
    if (info != null && info.heartRate != null) {
        return info.heartRate;
    }
    return 0;  // or return null
}
```

### 2. Update Frequency

Optimize sensor polling:

```monkeyc
class MyWatchFace extends WatchUi.WatchFace {
    hidden var mLastSensorUpdate = 0;
    hidden var mSensorUpdateInterval = 5000; // 5 seconds
    
    function onUpdate(dc) {
        var now = System.getTimer();
        
        // Only update sensors periodically
        if (now - mLastSensorUpdate > mSensorUpdateInterval) {
            updateSensorData();
            mLastSensorUpdate = now;
        }
        
        // Draw using cached data
        drawWatchFace(dc);
    }
}
```

### 3. Battery Optimization

- Cache sensor readings
- Use appropriate update intervals
- Avoid continuous sensor polling
- Disable unused sensors

### 4. Permission Handling

```monkeyc
function requestHeartRatePermission() {
    if (Toybox has :SensorHistory) {
        if (!System.getDeviceSettings().heartRateEnabled) {
            // HR sensor is disabled in system settings
            return false;
        }
    }
    
    // Permission will be requested on first access
    var hr = Sensor.getInfo().heartRate;
    return (hr != null);
}
```

### 5. Units Conversion

```monkeyc
function convertDistance(distanceCm, units) {
    if (units == System.UNIT_METRIC) {
        return distanceCm / 100000.0; // to km
    } else {
        return distanceCm / 160934.4; // to miles
    }
}

function formatDistance(distanceCm) {
    var settings = System.getDeviceSettings();
    var distance = convertDistance(distanceCm, settings.distanceUnits);
    var unit = (settings.distanceUnits == System.UNIT_METRIC) ? "km" : "mi";
    return distance.format("%.2f") + " " + unit;
}
```

### 6. Error Handling

```monkeyc
function safeHealthDataAccess() {
    try {
        var info = ActivityMonitor.getInfo();
        if (info != null) {
            return info.steps;
        }
    } catch (ex) {
        // Log error or provide fallback
        System.println("Error accessing health data: " + ex.getMessage());
    }
    return 0;
}
```

---

## Privacy and Compliance

### User Consent

1. **Explicit Permissions**: Always declare required permissions in manifest.xml
2. **Graceful Degradation**: Handle permission denial without crashing
3. **Transparency**: Inform users why you need specific health data
4. **Data Minimization**: Only request data you actually use

### Data Handling

1. **Local Only**: Health data should stay on device unless user explicitly consents to sharing
2. **No Caching**: Don't persist sensitive health data unnecessarily
3. **Secure Transmission**: If syncing data, use encrypted connections
4. **GDPR/HIPAA**: Consider regulatory requirements for health data

### Store Guidelines

When publishing to Connect IQ Store:

1. Clearly describe what health data is used
2. Explain the purpose of each permission
3. Provide privacy policy if data leaves device
4. Include screenshots showing health features
5. Test with permissions denied

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Heart rate always null | Permission denied or sensor off | Check permissions and device settings |
| Body Battery unavailable | Device doesn't support | Use feature detection |
| Steps not updating | Activity tracking disabled | Check user's activity tracking settings |
| Wrong units displayed | Not checking user preferences | Use System.getDeviceSettings() |
| High battery drain | Too frequent sensor polling | Implement caching and throttling |

### Debug Helpers

```monkeyc
function logHealthCapabilities() {
    System.println("Device Health Capabilities:");
    System.println("- Has HR: " + (Sensor.getInfo().heartRate != null));
    System.println("- Has Body Battery: " + (Sensor has :getBodyBatteryInfo));
    System.println("- Has Stress: " + (Sensor has :getStressInfo));
    System.println("- Has Pulse Ox: " + (Sensor has :getPulseOxInfo));
    System.println("- Has Barometer: " + (Sensor.getInfo().pressure != null));
}
```

---

## Summary

Garmin Connect IQ provides extensive health data access for creating engaging, health-focused watch faces and applications. Key takeaways:

1. **Always check for null values** - Not all devices support all features
2. **Use feature detection** - Check capabilities at runtime
3. **Respect user privacy** - Request only necessary permissions
4. **Optimize for battery** - Cache data and throttle updates
5. **Handle errors gracefully** - Provide fallbacks for missing data
6. **Test on multiple devices** - Features vary significantly

By following these guidelines and leveraging the available health APIs responsibly, you can create powerful health-tracking experiences that help users achieve their wellness goals.

---

*For the latest API updates and device-specific features, consult the official Garmin Connect IQ documentation and SDK release notes.*