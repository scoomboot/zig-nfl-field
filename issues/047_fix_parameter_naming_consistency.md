# Issue #047: Fix parameter naming inconsistency for endzone_length

## Summary
Standardize parameter naming for endzone length across all Field methods to use consistent naming convention.

## Description
The Field API currently has an inconsistency in how the endzone length parameter is named:
- `Field.initCustom()` uses `end_zone_length` (with underscores)
- Field struct member is `endzone_length` (no underscores)
- `FieldBuilder.setEndZoneLength()` uses `endzone_length` (no underscores)

This inconsistency can confuse users and makes the API less intuitive. The codebase should standardize on one naming convention.

## Current State (RESOLVED)
```zig
// In Field struct (line 95)
endzone_length: f32 = END_ZONE_LENGTH_YARDS,

// In initCustom method (line 171) - NOW FIXED
pub fn initCustom(
    allocator: std.mem.Allocator,
    length: f32,
    width: f32,
    endzone_length: f32  // ← Now consistent, no underscores
) FieldError!Field {
    // ...
    .endzone_length = endzone_length,  // ← Now consistent
}

// In setEndZoneLength method (line 1145)
pub fn setEndZoneLength(self: *FieldBuilder, endzone_length: f32) FieldError!*FieldBuilder {
    // ...
    self.field.endzone_length = endzone_length;  // ← Consistent naming
}
```

## Acceptance Criteria
- [x] Change `initCustom` parameter from `end_zone_length` to `endzone_length`
- [x] Update all references in initCustom method body
- [x] Update documentation comments to reflect new parameter name
- [x] Verify all tests still pass
- [x] Check for any other instances of inconsistent naming

## Proposed Solution
Standardize on `endzone_length` (no underscores) throughout the codebase as this:
1. Matches the Field struct member name
2. Is consistent with other compound words in the codebase
3. Already used in the newer FieldBuilder methods

## Dependencies
- None (this is a simple refactoring)

## Impact
- **API Change**: Yes, but minor - only affects parameter name
- **Breaking Change**: No - Zig uses positional parameters
- **Test Updates**: None required - tests use positional arguments

## Priority
🔵 Low - API polish and consistency improvement

## Category
Enhancement

## Resolution

Successfully standardized parameter naming to `endzone_length` (no underscores) throughout the codebase:

### Changes Made:
1. **lib/field.zig:162** - Updated documentation comment from `end_zone_length` to `endzone_length`
2. **lib/field.zig:171** - Changed parameter name from `end_zone_length` to `endzone_length`
3. **lib/field.zig:174** - Updated validation reference to use `endzone_length`
4. **lib/field.zig:179** - Updated validation reference to use `endzone_length`
5. **lib/field.zig:190** - Updated assignment to use `endzone_length`
6. **lib/field.test.zig:472** - Updated comment from `// end_zone_length` to `// endzone_length`

### Verification:
- All tests pass successfully with `zig build test`
- No breaking changes since Zig uses positional parameters
- API now consistent across Field struct, initCustom, and FieldBuilder methods

---
*Created: 2025-09-02*
*Status: Resolved*
*Resolved: 2025-09-02*
*Related: #045 (setEndZoneLength implementation)*