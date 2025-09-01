# Issue #011: Implement field initialization

## Summary
Implement initialization functions for the Field struct with various configuration options.

**NOTE**: Basic init() and deinit() functions were implemented in issue #010. This issue now focuses on advanced initialization features like custom dimensions and builder patterns.

## Description
Create initialization functions that allow creating Field instances with default NFL specifications or custom configurations. Include builder pattern support for flexible field creation and validation of field parameters.

## Acceptance Criteria
- [x] Implement default init function with NFL specifications (COMPLETED in #010)
- [ ] Add custom init function with parameter validation
- [ ] Create builder pattern for field configuration
- [ ] Add field validation during initialization
- [x] Implement deinit for cleanup (COMPLETED in #010)
- [ ] Add field reset functionality

## Dependencies
- #010: Design Field struct layout

## Implementation Notes

### Initialization Functions (lib/field.zig)
```zig
impl Field {
    /// Creates a new Field with default NFL specifications.
    pub fn init(allocator: std.mem.Allocator) Field {
        return Field{
            .allocator = allocator,
            .length = FIELD_LENGTH_YARDS,
            .width = FIELD_WIDTH_YARDS,
            .end_zone_length = END_ZONE_LENGTH_YARDS,
            .name = "NFL Field",
            .surface_type = .turf,
            .north_boundary = FIELD_LENGTH_YARDS,
            .south_boundary = 0.0,
            .east_boundary = FIELD_WIDTH_YARDS,
            .west_boundary = 0.0,
            .left_hash_x = HASH_FROM_SIDELINE_YARDS,
            .right_hash_x = FIELD_WIDTH_YARDS - HASH_FROM_SIDELINE_YARDS,
            .center_x = FIELD_WIDTH_YARDS / 2.0,
        };
    }
    
    /// Creates a custom field with specified dimensions.
    pub fn initCustom(
        allocator: std.mem.Allocator,
        length: f32,
        width: f32,
        end_zone_length: f32,
    ) !Field {
        // Validate dimensions
        if (length <= 0 or width <= 0 or end_zone_length < 0) {
            return FieldError.InvalidDimensions;
        }
        if (end_zone_length * 2 >= length) {
            return FieldError.InvalidDimensions;
        }
        
        return Field{
            .allocator = allocator,
            .length = length,
            .width = width,
            .end_zone_length = end_zone_length,
            .name = "Custom Field",
            .surface_type = .turf,
            .north_boundary = length,
            .south_boundary = 0.0,
            .east_boundary = width,
            .west_boundary = 0.0,
            .left_hash_x = width * 0.28, // Proportional positioning
            .right_hash_x = width * 0.72,
            .center_x = width / 2.0,
        };
    }
    
    /// Deinitializes the field and frees resources.
    pub fn deinit(self: *Field) void {
        // Free any allocated memory if needed
        // Currently no dynamic allocations in basic field
    }
    
    /// Resets field to default state.
    pub fn reset(self: *Field) void {
        self.* = Field.init(self.allocator);
    }
}

/// Builder pattern for field construction.
pub const FieldBuilder = struct {
    field: Field,
    
    pub fn init(allocator: std.mem.Allocator) FieldBuilder {
        return FieldBuilder{
            .field = Field.init(allocator),
        };
    }
    
    pub fn setName(self: *FieldBuilder, name: []const u8) *FieldBuilder {
        self.field.name = name;
        return self;
    }
    
    pub fn setSurface(self: *FieldBuilder, surface: SurfaceType) *FieldBuilder {
        self.field.surface_type = surface;
        return self;
    }
    
    pub fn setDimensions(
        self: *FieldBuilder,
        length: f32,
        width: f32,
    ) !*FieldBuilder {
        if (length <= 0 or width <= 0) {
            return FieldError.InvalidDimensions;
        }
        self.field.length = length;
        self.field.width = width;
        self.field.north_boundary = length;
        self.field.east_boundary = width;
        return self;
    }
    
    pub fn build(self: FieldBuilder) Field {
        return self.field;
    }
};
```

## Testing Requirements
- Test default initialization creates valid NFL field
- Test custom initialization with valid dimensions
- Test custom initialization rejects invalid dimensions
- Test builder pattern functionality
- Test field reset restores defaults
- Test memory management (init/deinit cycle)
- Verify all field properties are correctly initialized

## Estimated Time
1.5-2 hours

## Priority
🟡 High - Required for field instantiation

## Category
Core Implementation

---
*Created: 2025-08-25*
*Status: Pending*