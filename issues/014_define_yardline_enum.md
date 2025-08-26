# Issue #014: Define YardLine enum

## Summary
Create the YardLine enum to represent all 101 yard line positions on the field (0-100).

## Description
Implement a comprehensive YardLine enum that represents every yard line on the field from goal line to goal line. This enum will provide type-safe yard line representation and conversion utilities between yard lines and coordinates.

## Acceptance Criteria
- [ ] Define YardLine enum with values 0-100
- [ ] Add special named values (midfield, goal lines, etc.)
- [ ] Implement conversion to Y coordinate
- [ ] Implement conversion from Y coordinate
- [ ] Add yard line arithmetic functions
- [ ] Create display formatting functions

## Dependencies
- #009: Create coordinate conversion utilities

## Implementation Notes

### YardLine Enum Definition (lib/field.zig)
```zig
/// Represents yard lines on the field (0-100).
pub const YardLine = enum(u8) {
    // Special positions
    south_goal = 0,
    north_goal = 100,
    midfield = 50,
    
    // Generate all yard lines (0-100)
    _, // Allow any u8 value from 0-100
    
    /// Creates a YardLine from a value.
    pub fn fromInt(value: u8) !YardLine {
        if (value > 100) return error.InvalidYardLine;
        return @enumFromInt(value);
    }
    
    /// Converts yard line to Y coordinate on field.
    pub fn toYCoordinate(self: YardLine) f32 {
        const yard_value = @intFromEnum(self);
        return END_ZONE_LENGTH_YARDS + @as(f32, @floatFromInt(yard_value));
    }
    
    /// Creates YardLine from Y coordinate.
    pub fn fromYCoordinate(y: f32) !YardLine {
        // Check if in end zone
        if (y < END_ZONE_LENGTH_YARDS or 
            y > FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS) {
            return error.InEndZone;
        }
        
        const yard_value = @as(u8, @intFromFloat(
            @round(y - END_ZONE_LENGTH_YARDS)
        ));
        
        return YardLine.fromInt(yard_value);
    }
    
    /// Moves yard line by specified yards.
    pub fn advance(self: YardLine, yards: i8) !YardLine {
        const current = @as(i16, @intFromEnum(self));
        const new_value = current + yards;
        
        if (new_value < 0 or new_value > 100) {
            return error.OutOfBounds;
        }
        
        return YardLine.fromInt(@intCast(new_value));
    }
    
    /// Gets distance to another yard line.
    pub fn distanceTo(self: YardLine, other: YardLine) i8 {
        const self_value = @as(i8, @intFromEnum(self));
        const other_value = @as(i8, @intFromEnum(other));
        return other_value - self_value;
    }
    
    /// Formats yard line for display.
    pub fn format(
        self: YardLine,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const value = @intFromEnum(self);
        
        if (value == 50) {
            try writer.writeAll("Midfield");
        } else if (value < 50) {
            try writer.print("Own {d}", .{value});
        } else {
            try writer.print("Opp {d}", .{100 - value});
        }
    }
    
    /// Gets the side of field for this yard line.
    pub fn getFieldSide(self: YardLine) FieldSide {
        const value = @intFromEnum(self);
        if (value < 50) return .own;
        if (value > 50) return .opponent;
        return .midfield;
    }
};

/// Represents which side of the field.
pub const FieldSide = enum {
    own,
    midfield,
    opponent,
};
```

## Testing Requirements
- Test enum creation from valid values (0-100)
- Test rejection of invalid values (>100)
- Test Y coordinate conversion both directions
- Test yard line advancement (positive and negative)
- Test distance calculations
- Test display formatting for all field positions
- Test field side determination
- Verify special positions (goal lines, midfield)

## Estimated Time
1-1.5 hours

## Priority
🟡 High - Core field positioning system

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*