# Issue #045: Add setEndZoneLength() to FieldBuilder

## Summary
Enhance the FieldBuilder pattern by adding a method to configure custom endzone lengths.

## Description
The current FieldBuilder implementation lacks the ability to set custom endzone lengths. While users can create fields with custom endzone lengths using `initCustom()`, the builder pattern doesn't provide this flexibility. Adding a `setEndZoneLength()` method would make the builder pattern more complete and consistent with the customization capabilities of `initCustom()`.

## Acceptance Criteria
- [ ] Add `setEndZoneLength()` method to FieldBuilder
- [ ] Validate endzone length is positive
- [ ] Validate endzone_length * 2 < field length
- [ ] Update boundaries when endzone length changes
- [ ] Add tests for the new method
- [ ] Ensure method chaining works correctly

## Dependencies
- #011: Implement field initialization (COMPLETED)

## Implementation Notes

### FieldBuilder Enhancement (lib/field.zig)
```zig
/// Set custom endzone length for the field
///
/// __Parameters__
///
/// - `endzone_length`: Length of each endzone in yards
///
/// __Return__
///
/// - Pointer to this builder for method chaining, or FieldError.InvalidDimensions
pub fn setEndZoneLength(self: *FieldBuilder, endzone_length: f32) FieldError!*FieldBuilder {
    // Validate endzone length is positive
    if (endzone_length <= 0) {
        return FieldError.InvalidDimensions;
    }
    
    // Validate endzones don't exceed field length
    if (endzone_length * 2 >= self.field.length) {
        return FieldError.InvalidDimensions;
    }
    
    // Update endzone length
    self.field.endzone_length = endzone_length;
    
    return self;
}
```

## Testing Requirements
- Test setting valid endzone lengths
- Test validation of negative/zero endzone lengths
- Test validation against field length constraint
- Test method chaining with other builder methods
- Test that setEndZoneLength works correctly with setDimensions

## Estimated Time
0.5-1 hour

## Priority
🔵 Low - Enhancement to existing functionality

## Category
Enhancement

---
*Created: 2025-09-01*
*Status: Pending*
*Related: #011 (Field initialization)*