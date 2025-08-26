# Issue #008: Add coordinate validation functions

## Summary
Implement comprehensive validation functions for coordinate positions and boundary checking.

## Description
Extend the coordinate system with additional validation functions that check for specific field areas, boundary conditions, and provide detailed position information. These functions will be used throughout the library for ensuring valid positions and game state.

## Acceptance Criteria
- [ ] Add function to check if coordinate is in end zone
- [ ] Add function to check if coordinate is on sideline
- [ ] Add function to check if coordinate is on goal line
- [ ] Add function to validate coordinate ranges
- [ ] Add function to clamp coordinates to field boundaries
- [ ] Implement detailed error information for invalid coordinates

## Dependencies
- #007: Implement Coordinate struct

## Implementation Notes

### Additional Validation Functions (lib/field.zig)
```zig
// Extension methods for Coordinate struct
impl Coordinate {
    /// Checks if coordinate is in either end zone.
    pub fn isInEndZone(self: Coordinate) bool {
        if (!self.isValid()) return false;
        return self.y < END_ZONE_LENGTH_YARDS or 
               self.y > (FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS);
    }
    
    /// Checks if coordinate is in the south end zone.
    pub fn isInSouthEndZone(self: Coordinate) bool {
        return self.isValid() and self.y < END_ZONE_LENGTH_YARDS;
    }
    
    /// Checks if coordinate is in the north end zone.
    pub fn isInNorthEndZone(self: Coordinate) bool {
        return self.isValid() and 
               self.y > (FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS);
    }
    
    /// Checks if coordinate is on a sideline.
    pub fn isOnSideline(self: Coordinate) bool {
        const epsilon = 0.01; // Tolerance for floating point comparison
        return self.isValid() and 
               (@abs(self.x) < epsilon or 
                @abs(self.x - FIELD_WIDTH_YARDS) < epsilon);
    }
    
    /// Checks if coordinate is on a goal line.
    pub fn isOnGoalLine(self: Coordinate) bool {
        const epsilon = 0.01;
        return self.isValid() and
               (@abs(self.y - END_ZONE_LENGTH_YARDS) < epsilon or
                @abs(self.y - (FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS)) < epsilon);
    }
    
    /// Clamps coordinate to field boundaries.
    pub fn clamp(self: Coordinate) Coordinate {
        return Coordinate.init(
            std.math.clamp(self.x, 0.0, FIELD_WIDTH_YARDS),
            std.math.clamp(self.y, 0.0, FIELD_LENGTH_YARDS)
        );
    }
}
```

### Validation Error Types
```zig
pub const CoordinateError = error{
    OutOfBoundsX,
    OutOfBoundsY,
    InvalidCoordinate,
};

/// Validates coordinate with detailed error information.
pub fn validateCoordinate(coord: Coordinate) CoordinateError!void {
    if (coord.x < 0.0 or coord.x > FIELD_WIDTH_YARDS) {
        return CoordinateError.OutOfBoundsX;
    }
    if (coord.y < 0.0 or coord.y > FIELD_LENGTH_YARDS) {
        return CoordinateError.OutOfBoundsY;
    }
}
```

## Testing Requirements
- Test all validation functions with valid coordinates
- Test boundary conditions (exact edges)
- Test invalid coordinates (negative, too large)
- Test clamping function with various out-of-bounds values
- Test error reporting for invalid coordinates
- Verify floating-point tolerance in comparisons

## Estimated Time
1 hour

## Priority
🟡 High - Critical for position validation throughout library

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*