# Issue #013: Create field metadata storage

## Summary
Implement metadata storage and management for field properties, game conditions, and field state.

## Description
Create a system for storing and managing field metadata including weather conditions, field conditions, game information, and other dynamic properties that may affect gameplay or visualization.

## Acceptance Criteria
- [ ] Create metadata structure for field properties
- [ ] Add weather condition tracking
- [ ] Implement field condition management
- [ ] Add game information storage
- [ ] Create metadata query functions
- [ ] Implement metadata serialization support

## Dependencies
- #010: Design Field struct layout

## Implementation Notes

### Metadata Structures (lib/field.zig)
```zig
/// Field metadata containing additional properties and state.
pub const FieldMetadata = struct {
    // Field identification
    stadium_name: []const u8 = "Generic Stadium",
    team_home: []const u8 = "",
    team_away: []const u8 = "",
    
    // Weather conditions
    weather: WeatherConditions = .{},
    
    // Field conditions
    field_condition: FieldCondition = .good,
    wear_areas: []WearArea = &.{},
    
    // Game information
    game_time: ?i64 = null,
    attendance: ?u32 = null,
    
    // Field features
    has_dome: bool = false,
    has_retractable_roof: bool = false,
    elevation_feet: f32 = 0.0,
};

/// Weather conditions affecting the field.
pub const WeatherConditions = struct {
    temperature_fahrenheit: f32 = 70.0,
    wind_speed_mph: f32 = 0.0,
    wind_direction_degrees: f32 = 0.0, // 0 = North, 90 = East
    precipitation: Precipitation = .none,
    humidity_percent: f32 = 50.0,
};

/// Types of precipitation.
pub const Precipitation = enum {
    none,
    light_rain,
    heavy_rain,
    snow,
    sleet,
    fog,
};

/// Field condition states.
pub const FieldCondition = enum {
    excellent,
    good,
    fair,
    poor,
    unplayable,
    
    pub fn toMultiplier(self: FieldCondition) f32 {
        return switch (self) {
            .excellent => 1.0,
            .good => 0.95,
            .fair => 0.85,
            .poor => 0.70,
            .unplayable => 0.0,
        };
    }
};

/// Areas of field wear.
pub const WearArea = struct {
    center: Coordinate,
    radius: f32,
    severity: f32, // 0.0 = no wear, 1.0 = completely worn
};

impl Field {
    /// Sets field metadata.
    pub fn setMetadata(self: *Field, metadata: FieldMetadata) void {
        self.metadata = metadata;
    }
    
    /// Gets current field condition multiplier.
    pub fn getConditionMultiplier(self: Field) f32 {
        return self.metadata.field_condition.toMultiplier();
    }
    
    /// Checks if weather affects play.
    pub fn hasWeatherImpact(self: Field) bool {
        const weather = self.metadata.weather;
        return weather.wind_speed_mph > 15.0 or
               weather.precipitation != .none or
               weather.temperature_fahrenheit < 32.0 or
               weather.temperature_fahrenheit > 95.0;
    }
    
    /// Gets wind vector for ball physics.
    pub fn getWindVector(self: Field) struct { x: f32, y: f32 } {
        const weather = self.metadata.weather;
        const wind_rad = weather.wind_direction_degrees * std.math.pi / 180.0;
        const wind_factor = weather.wind_speed_mph / 50.0; // Normalize to 0-1
        
        return .{
            .x = @sin(wind_rad) * wind_factor,
            .y = @cos(wind_rad) * wind_factor,
        };
    }
    
    /// Adds a wear area to the field.
    pub fn addWearArea(
        self: *Field,
        center: Coordinate,
        radius: f32,
        severity: f32,
    ) !void {
        const wear_area = WearArea{
            .center = center,
            .radius = radius,
            .severity = std.math.clamp(severity, 0.0, 1.0),
        };
        
        // This would require dynamic allocation
        // For now, assume a fixed array or allocator usage
        try self.wear_areas.append(wear_area);
    }
    
    /// Gets field condition at a specific coordinate.
    pub fn getConditionAt(self: Field, coord: Coordinate) f32 {
        var condition = self.getConditionMultiplier();
        
        // Check wear areas
        for (self.metadata.wear_areas) |area| {
            const dist = std.math.sqrt(
                std.math.pow(f32, coord.x - area.center.x, 2) +
                std.math.pow(f32, coord.y - area.center.y, 2)
            );
            
            if (dist <= area.radius) {
                const wear_factor = 1.0 - (dist / area.radius);
                condition *= (1.0 - (area.severity * wear_factor));
            }
        }
        
        return condition;
    }
}
```

### Serialization Support
```zig
/// Serializes field metadata to JSON.
pub fn serializeMetadata(
    metadata: FieldMetadata,
    writer: anytype,
) !void {
    try std.json.stringify(metadata, .{}, writer);
}

/// Deserializes field metadata from JSON.
pub fn deserializeMetadata(
    allocator: std.mem.Allocator,
    reader: anytype,
) !FieldMetadata {
    const json = try reader.readAllAlloc(allocator, 1024 * 1024);
    defer allocator.free(json);
    
    return try std.json.parse(FieldMetadata, &.{}, json);
}
```

## Testing Requirements
- Test metadata structure initialization
- Test weather condition effects
- Test field condition multipliers
- Test wear area calculations
- Test wind vector calculations
- Test condition at coordinate calculations
- Test serialization/deserialization
- Verify edge cases and boundary conditions

## Estimated Time
2-2.5 hours

## Priority
🟡 High - Important for realistic field simulation

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*