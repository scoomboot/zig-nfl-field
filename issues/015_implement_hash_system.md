# Issue #015: Implement Hash positioning system

## Summary
Create the Hash enum and positioning system for hash marks on the field.

## Description
Implement a Hash enum that represents the three primary lateral positions on the field (left hash, right hash, middle) and provide utilities for converting between hash positions and coordinates.

## Acceptance Criteria
- [ ] Define Hash enum (left, right, middle)
- [ ] Implement hash to X coordinate conversion
- [ ] Add nearest hash calculation from coordinate
- [ ] Create hash mark line generation
- [ ] Add hash position validation
- [ ] Implement hash-based alignment functions

## Dependencies
- #009: Create coordinate conversion utilities

## Implementation Notes

### Hash System Implementation (lib/field.zig)
```zig
/// Represents hash mark positions on the field.
pub const Hash = enum {
    left,
    right,
    middle,
    
    /// Converts hash position to X coordinate.
    pub fn toXCoordinate(self: Hash) f32 {
        return switch (self) {
            .left => HASH_FROM_SIDELINE_YARDS,
            .right => FIELD_WIDTH_YARDS - HASH_FROM_SIDELINE_YARDS,
            .middle => FIELD_WIDTH_YARDS / 2.0,
        };
    }
    
    /// Gets nearest hash mark from X coordinate.
    pub fn fromXCoordinate(x: f32) Hash {
        const left_dist = @abs(x - Hash.left.toXCoordinate());
        const right_dist = @abs(x - Hash.right.toXCoordinate());
        const middle_dist = @abs(x - Hash.middle.toXCoordinate());
        
        const min_dist = @min(@min(left_dist, right_dist), middle_dist);
        
        if (min_dist == left_dist) return .left;
        if (min_dist == right_dist) return .right;
        return .middle;
    }
    
    /// Gets coordinate for hash at specific yard line.
    pub fn getCoordinate(self: Hash, yard_line: YardLine) Coordinate {
        return Coordinate.init(
            self.toXCoordinate(),
            yard_line.toYCoordinate()
        );
    }
};
```

## Testing Requirements
- Test hash to X coordinate conversion
- Test nearest hash calculation
- Test coordinate generation at yard lines
- Verify hash positions match NFL specifications

## Estimated Time
1 hour

## Priority
🟡 High - Required for ball placement

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*