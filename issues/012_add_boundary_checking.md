# Issue #012: Add field boundary checking

## Summary
Implement comprehensive boundary checking functions for the Field struct to validate positions and areas.

**NOTE**: Basic contains() function and boundary fields were implemented in issue #010. This issue now focuses on advanced boundary checking features.

## Description
Add methods to the Field struct that check if coordinates, areas, and movements are within field boundaries. These functions will be essential for game logic and ensuring valid field positions during simulation.

## Acceptance Criteria
- [x] Add function to check if coordinate is within field (COMPLETED in #010 - contains())
- [ ] Add function to check if area/rectangle is within field
- [ ] Add function to check if line segment is within field
- [ ] Add function to get boundary violations
- [ ] Add function to calculate distance to nearest boundary
- [ ] Implement boundary intersection detection

## Dependencies
- #010: Design Field struct layout

## Implementation Notes

### Boundary Checking Functions (lib/field.zig)
```zig
impl Field {
    /// Checks if a coordinate is within field boundaries.
    pub fn contains(self: Field, coord: Coordinate) bool {
        return coord.x >= self.west_boundary and
               coord.x <= self.east_boundary and
               coord.y >= self.south_boundary and
               coord.y <= self.north_boundary;
    }
    
    /// Checks if a coordinate is within playing field (excludes end zones).
    pub fn containsInPlay(self: Field, coord: Coordinate) bool {
        return coord.x > self.west_boundary and
               coord.x < self.east_boundary and
               coord.y >= self.end_zone_length and
               coord.y <= (self.length - self.end_zone_length);
    }
    
    /// Checks if a rectangular area is completely within field.
    pub fn containsArea(
        self: Field,
        top_left: Coordinate,
        bottom_right: Coordinate,
    ) bool {
        return self.contains(top_left) and
               self.contains(bottom_right) and
               self.contains(Coordinate.init(top_left.x, bottom_right.y)) and
               self.contains(Coordinate.init(bottom_right.x, top_left.y));
    }
    
    /// Checks if a line segment is completely within field.
    pub fn containsLine(
        self: Field,
        start: Coordinate,
        end: Coordinate,
    ) bool {
        // Check endpoints first
        if (!self.contains(start) or !self.contains(end)) {
            return false;
        }
        
        // For a line to be contained, all points must be within bounds
        // Since field is rectangular, if endpoints are valid, line is valid
        return true;
    }
    
    /// Gets the type of boundary violation for a coordinate.
    pub fn getBoundaryViolation(self: Field, coord: Coordinate) ?BoundaryViolation {
        if (coord.x < self.west_boundary) return .west_out_of_bounds;
        if (coord.x > self.east_boundary) return .east_out_of_bounds;
        if (coord.y < self.south_boundary) return .south_out_of_bounds;
        if (coord.y > self.north_boundary) return .north_out_of_bounds;
        return null;
    }
    
    /// Calculates distance to nearest boundary.
    pub fn distanceToBoundary(self: Field, coord: Coordinate) f32 {
        if (!self.contains(coord)) return 0.0;
        
        const dist_west = coord.x - self.west_boundary;
        const dist_east = self.east_boundary - coord.x;
        const dist_south = coord.y - self.south_boundary;
        const dist_north = self.north_boundary - coord.y;
        
        return @min(@min(dist_west, dist_east), @min(dist_south, dist_north));
    }
    
    /// Calculates distance to nearest sideline.
    pub fn distanceToSideline(self: Field, coord: Coordinate) f32 {
        const dist_west = @abs(coord.x - self.west_boundary);
        const dist_east = @abs(coord.x - self.east_boundary);
        return @min(dist_west, dist_east);
    }
    
    /// Calculates distance to nearest end zone.
    pub fn distanceToEndZone(self: Field, coord: Coordinate) f32 {
        const south_endzone_line = self.end_zone_length;
        const north_endzone_line = self.length - self.end_zone_length;
        
        if (coord.y < south_endzone_line) {
            return south_endzone_line - coord.y;
        } else if (coord.y > north_endzone_line) {
            return coord.y - north_endzone_line;
        } else {
            // In playing field, return distance to nearest end zone
            return @min(
                coord.y - south_endzone_line,
                north_endzone_line - coord.y
            );
        }
    }
}

/// Types of boundary violations.
pub const BoundaryViolation = enum {
    west_out_of_bounds,
    east_out_of_bounds,
    south_out_of_bounds,
    north_out_of_bounds,
};
```

## Testing Requirements
- Test contains function with various coordinates
- Test containsInPlay excludes end zones correctly
- Test area containment checking
- Test line segment containment
- Test boundary violation detection
- Test distance calculations to boundaries
- Test distance to sideline calculations
- Test distance to end zone calculations
- Verify edge cases (exact boundaries, corners)

## Estimated Time
1.5-2 hours

## Priority
🟡 High - Essential for position validation

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*