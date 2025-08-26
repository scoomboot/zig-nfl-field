# Issue #007: Implement Coordinate struct

## Summary
Create the fundamental Coordinate struct for representing positions on the football field.

## Description
Implement a Coordinate struct that represents a position on the field using Cartesian coordinates. This struct will be the foundation for all position-based calculations and will include basic initialization and validation methods.

## Acceptance Criteria
- [ ] Create Coordinate struct with x and y fields (f32)
- [ ] Implement init function for creating coordinates
- [ ] Add isValid function to check if coordinate is within field bounds
- [ ] Document coordinate system (origin at southwest corner)
- [ ] Export Coordinate as public API
- [ ] Follow MCS naming conventions

## Dependencies
- #006: Define coordinate system constants

## Implementation Notes

### Coordinate Structure (lib/field.zig)
```zig
/// Represents a position on the football field using Cartesian coordinates.
/// Origin (0,0) is at the southwest corner of the field.
pub const Coordinate = struct {
    x: f32, // East-west position (0 = west sideline, 53.33 = east sideline)
    y: f32, // North-south position (0 = south end zone, 120 = north end zone)
    
    /// Creates a new coordinate.
    pub fn init(x: f32, y: f32) Coordinate {
        return Coordinate{ .x = x, .y = y };
    }
    
    /// Validates that coordinate is within field bounds.
    pub fn isValid(self: Coordinate) bool {
        return self.x >= 0.0 and self.x <= FIELD_WIDTH_YARDS and
               self.y >= 0.0 and self.y <= FIELD_LENGTH_YARDS;
    }
    
    /// Checks if coordinate is in bounds (playing field only).
    pub fn isInBounds(self: Coordinate) bool {
        return self.x > 0.0 and self.x < FIELD_WIDTH_YARDS and
               self.y >= END_ZONE_LENGTH_YARDS and 
               self.y <= FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS;
    }
};
```

### Export in Module
```zig
pub const Coordinate = @This().Coordinate;
```

## Testing Requirements
- Test coordinate initialization
- Test boundary validation (valid/invalid positions)
- Test in-bounds vs out-of-bounds detection
- Test edge cases (exact boundaries, negative values)
- Verify proper export in module

## Estimated Time
45 minutes - 1 hour

## Priority
🟡 High - Core data structure for position tracking

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*