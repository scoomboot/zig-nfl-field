# Issue #009: Create coordinate conversion utilities

## Summary
Implement utility functions for converting between different coordinate representations and units.

## Description
Create conversion utilities that allow transforming coordinates between different representations (yards to feet, field-relative to absolute positions, etc.) and provide helper functions for common coordinate operations.

## Acceptance Criteria
- [ ] Add conversion between yards and feet for coordinates
- [ ] Implement field-relative to absolute position conversion
- [ ] Add conversion from coordinate to nearest yard line
- [ ] Create conversion from coordinate to field position string
- [ ] Implement mirroring functions for coordinates
- [ ] Add rotation functions for play diagrams

## Dependencies
- #007: Implement Coordinate struct

## Implementation Notes

### Conversion Functions (lib/field.zig)
```zig
// Coordinate conversion utilities
impl Coordinate {
    /// Converts coordinate from yards to feet.
    pub fn toFeet(self: Coordinate) Coordinate {
        return Coordinate.init(
            self.x * YARDS_TO_FEET,
            self.y * YARDS_TO_FEET
        );
    }
    
    /// Converts coordinate from feet to yards.
    pub fn fromFeet(x_feet: f32, y_feet: f32) Coordinate {
        return Coordinate.init(
            x_feet * FEET_TO_YARDS,
            y_feet * FEET_TO_YARDS
        );
    }
    
    /// Gets the nearest yard line for this coordinate.
    pub fn nearestYardLine(self: Coordinate) ?u8 {
        if (!self.isValid()) return null;
        if (self.y < END_ZONE_LENGTH_YARDS or 
            self.y > FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS) {
            return null; // In end zone
        }
        
        const field_position = self.y - END_ZONE_LENGTH_YARDS;
        return @intFromFloat(@round(field_position));
    }
    
    /// Mirrors coordinate across the field centerline (x-axis).
    pub fn mirrorX(self: Coordinate) Coordinate {
        return Coordinate.init(
            FIELD_WIDTH_YARDS - self.x,
            self.y
        );
    }
    
    /// Mirrors coordinate across the midfield line (y-axis).
    pub fn mirrorY(self: Coordinate) Coordinate {
        return Coordinate.init(
            self.x,
            FIELD_LENGTH_YARDS - self.y
        );
    }
    
    /// Rotates coordinate 180 degrees around field center.
    pub fn rotate180(self: Coordinate) Coordinate {
        return Coordinate.init(
            FIELD_WIDTH_YARDS - self.x,
            FIELD_LENGTH_YARDS - self.y
        );
    }
}

/// Converts coordinate to field position string.
pub fn coordinateToFieldPosition(coord: Coordinate) ![]const u8 {
    if (!coord.isValid()) {
        return error.InvalidCoordinate;
    }
    
    // Determine which half of the field
    const yard_line = coord.nearestYardLine() orelse {
        if (coord.y < END_ZONE_LENGTH_YARDS) {
            return "South End Zone";
        } else {
            return "North End Zone";
        }
    };
    
    // Format based on field position
    if (yard_line == 50) {
        return "Midfield";
    } else if (yard_line < 50) {
        return std.fmt.allocPrint(allocator, "Own {d}", .{yard_line});
    } else {
        return std.fmt.allocPrint(allocator, "Opp {d}", .{100 - yard_line});
    }
}

/// Converts a relative field position to absolute coordinate.
pub fn fieldPositionToCoordinate(yard_line: u8, x_position: f32) !Coordinate {
    if (yard_line > 100) {
        return error.InvalidYardLine;
    }
    
    const y = END_ZONE_LENGTH_YARDS + @as(f32, @floatFromInt(yard_line));
    return Coordinate.init(x_position, y);
}
```

## Testing Requirements
- Test yards to feet conversion accuracy
- Test feet to yards conversion accuracy
- Test nearest yard line calculation
- Test field position string generation
- Test mirror operations (x, y, and 180° rotation)
- Test invalid coordinate handling
- Verify conversion precision and rounding

## Estimated Time
1-1.5 hours

## Priority
🟡 High - Essential for coordinate manipulation

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*