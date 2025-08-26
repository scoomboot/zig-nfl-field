# Issue #006: Define coordinate system constants

## Summary
Define all NFL field dimension constants and coordinate system origin following official specifications.

## Description
Establish the foundational constants for the NFL field geometry including field dimensions, end zone sizes, hash mark positions, and the coordinate system origin. These constants will be used throughout the library for position calculations and validations.

## Acceptance Criteria
- [ ] Define field length constants (120 yards total, 100 yards playing field)
- [ ] Define field width constants (53⅓ yards / 160 feet)
- [ ] Define end zone dimensions (10 yards each)
- [ ] Define hash mark separation (70'9" / 23.583333 yards)
- [ ] Define hash mark distance from sidelines (14.875 yards)
- [ ] Document coordinate system origin (southwest corner at 0,0)
- [ ] Add conversion constants between yards and feet

## Dependencies
- #002: Implement build.zig configuration

## Implementation Notes

### Required Constants (lib/field.zig)
```zig
// Field dimensions in yards
pub const FIELD_LENGTH_YARDS: f32 = 120.0;
pub const PLAYING_FIELD_LENGTH_YARDS: f32 = 100.0;
pub const END_ZONE_LENGTH_YARDS: f32 = 10.0;
pub const FIELD_WIDTH_YARDS: f32 = 53.333333;
pub const FIELD_WIDTH_FEET: f32 = 160.0;

// Hash mark positioning
pub const HASH_SEPARATION_YARDS: f32 = 23.583333;
pub const HASH_FROM_SIDELINE_YARDS: f32 = 14.875;

// Conversion factors
pub const YARDS_TO_FEET: f32 = 3.0;
pub const FEET_TO_YARDS: f32 = 0.333333;
```

### Coordinate System
- Origin (0,0): Southwest corner of field
- X-axis: East-west (0 to 53.33 yards)
- Y-axis: North-south (0 to 120 yards)
- Units: Yards (f32 for precision)

## Testing Requirements
- Verify all constants match NFL specifications
- Test dimensional accuracy calculations
- Validate conversion factors
- Ensure constants are properly exported

## Estimated Time
30-45 minutes

## Priority
🟡 High - Foundation for all coordinate calculations

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*