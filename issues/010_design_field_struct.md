# Issue #010: Design Field struct layout

## Summary
Design and implement the main Field struct that represents the complete NFL field geometry.

## Description
Create the central Field struct that encapsulates all field-related data and provides the main interface for field operations. This struct will serve as the primary entry point for the library and will coordinate all field-related functionality.

## Acceptance Criteria
- [ ] Design Field struct with necessary fields
- [ ] Include field dimensions and boundaries
- [ ] Add metadata fields (name, surface type, etc.)
- [ ] Define field state management
- [ ] Create Field struct documentation
- [ ] Export Field as public API

## Dependencies
- #007: Implement Coordinate struct

## Implementation Notes

### Field Structure Design (lib/field.zig)
```zig
/// Represents a complete NFL football field with all geometry and metadata.
pub const Field = struct {
    // Dimensions
    length: f32 = FIELD_LENGTH_YARDS,
    width: f32 = FIELD_WIDTH_YARDS,
    end_zone_length: f32 = END_ZONE_LENGTH_YARDS,
    
    // Metadata
    name: []const u8 = "NFL Field",
    surface_type: SurfaceType = .turf,
    
    // Boundaries
    north_boundary: f32 = FIELD_LENGTH_YARDS,
    south_boundary: f32 = 0.0,
    east_boundary: f32 = FIELD_WIDTH_YARDS,
    west_boundary: f32 = 0.0,
    
    // Hash marks
    left_hash_x: f32 = HASH_FROM_SIDELINE_YARDS,
    right_hash_x: f32 = FIELD_WIDTH_YARDS - HASH_FROM_SIDELINE_YARDS,
    center_x: f32 = FIELD_WIDTH_YARDS / 2.0,
    
    // Allocator for dynamic operations
    allocator: std.mem.Allocator,
};

/// Surface types for the field.
pub const SurfaceType = enum {
    grass,
    turf,
    hybrid,
};

/// Field orientation.
pub const Orientation = enum {
    north_south,  // Standard orientation
    east_west,    // Rotated 90 degrees
};

/// Field-specific errors.
pub const FieldError = error{
    InvalidDimensions,
    AllocationError,
};
```

### Export Configuration
```zig
// Module exports
pub const Field = @This().Field;
pub const SurfaceType = @This().SurfaceType;
pub const Orientation = @This().Orientation;
pub const FieldError = @This().FieldError;
```

## Testing Requirements
- Test Field struct initialization
- Verify default values are correct
- Test field dimension access
- Test metadata storage
- Verify proper module exports
- Test error conditions

## Estimated Time
1-1.5 hours

## Priority
🟡 High - Central data structure for the library

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*