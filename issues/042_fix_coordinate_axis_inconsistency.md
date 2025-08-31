# Issue #042: Fix Coordinate System Axis Inconsistency

## Summary
Critical inconsistency between coordinate system documentation and implementation causing potential API confusion.

## Description
The coordinate system has conflicting definitions between the constants documentation and the actual implementation. The constants section claims X is east-west and Y is north-south, but the code validates X against field length (north-south) and Y against field width (east-west). This fundamental inconsistency needs immediate resolution.

## Evidence of Inconsistency

### Constants Documentation (lib/field.zig:15-16)
```
/// X-axis: East-west (0 to 53.33 yards)
/// Y-axis: North-south (0 to 120 yards)
```

### Coordinate Implementation (lib/field.zig:134-138, 170-172)
```zig
/// X position (0-120 yards, 0 is home endzone back line)
x: f32,

/// Y position (0-53.33 yards, 0 is left sideline)  
y: f32,

// Validation code:
return self.x >= 0 and self.x <= FIELD_LENGTH_YARDS and 
       self.y >= 0 and self.y <= FIELD_WIDTH_YARDS;
```

### Test Usage (lib/field.test.zig:100, 159-160)
```zig
// Hash mark at 50-yard line
const hash_coord = field.Coordinate.init(50, field.HASH_FROM_SIDELINE_YARDS);

// Ball placement suggests X is yard line (north-south)
const left_hash = field.Coordinate.init(50, field.HASH_FROM_SIDELINE_YARDS);
```

## Impact
- **API Confusion**: Users reading documentation will expect X to be horizontal, but code treats it as vertical
- **Potential Bugs**: Coordinate calculations may be incorrect if users follow documentation
- **Test Reliability**: Tests may be validating incorrect behavior

## Acceptance Criteria
- [ ] Decide on standard coordinate convention (recommend: X=horizontal/east-west, Y=vertical/north-south)
- [ ] Update either documentation or implementation to match chosen convention
- [ ] Ensure all coordinate-related functions follow consistent convention
- [ ] Update tests to validate correct axis orientation
- [ ] Add explicit documentation about coordinate system orientation
- [ ] Consider adding diagram showing field with axis labels

## Proposed Solution

### Option 1: Follow Mathematical Convention (Recommended)
- X-axis = horizontal (east-west, 0 to 53.33 yards)
- Y-axis = vertical (north-south, 0 to 120 yards)
- Update implementation to swap current X/Y validation

### Option 2: Keep Current Implementation
- X-axis = vertical (north-south, 0 to 120 yards)
- Y-axis = horizontal (east-west, 0 to 53.33 yards)
- Update documentation to match implementation

## Dependencies
- May affect Issues #008, #009, and any other coordinate-related functionality
- Will require updating all tests using coordinates

## Testing Requirements
- Verify coordinate validation matches chosen convention
- Test field positions align with NFL field reality
- Ensure distance calculations remain correct
- Validate all boundary checks

## Estimated Time
1-2 hours (including test updates)

## Priority
🔴 Critical - Fundamental API inconsistency affecting all coordinate operations

## Category
Bug Fix / API Consistency

---
*Created: 2025-08-30*
*Status: ✅ **RESOLVED***
*Discovered during: Issue #007 resolution session*
*Resolved: 2025-08-30*

## Resolution Summary

**✅ ISSUE RESOLVED** - Coordinate system has been fixed to follow mathematical convention.

### Implementation Decision
Chose **Option 1: Follow Mathematical Convention** where:
- **X-axis** = horizontal (east-west, 0 to 53.33 yards)
- **Y-axis** = vertical (north-south, 0 to 120 yards)  
- **Origin (0,0)** = Southwest corner (home endzone back line, left sideline)

### Changes Made

#### Core Implementation (`lib/field.zig`)
- ✅ Added ASCII coordinate system diagram showing field layout with axes
- ✅ Fixed `Field.contains()`: X checks against width, Y against length
- ✅ Fixed all endzone methods to use Y coordinate (north-south)
- ✅ Fixed `Coordinate` struct documentation and validation
- ✅ Updated `isValid()` and `isInBounds()` methods

#### Tests (`lib/field.test.zig`)  
- ✅ Updated all coordinate initializations to match new convention
- ✅ Fixed endzone detection tests to use Y coordinate
- ✅ All 39 tests passing with new coordinate system

#### Benchmarks (`benchmarks/field_bench.zig`)
- ✅ Updated all coordinate parameters to match convention
- ✅ Fixed `isValid()` call signature
- ✅ Benchmarks running successfully

### Validation Results
- **All Tests**: ✅ 39/39 passing
- **Benchmarks**: ✅ Running without performance regression  
- **API Consistency**: ✅ Documentation matches implementation
- **MCS Compliance**: ✅ Follows all style guidelines

### Impact on Dependencies
- Issue #008: Will require Y-axis endzone check updates (noted for future)
- Issue #009: Will require coordinate conversion function updates (noted for future)

The coordinate system is now mathematically consistent and matches standard conventions.