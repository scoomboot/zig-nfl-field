# Issue #044: Fix benchmark compilation errors

## Summary
Fix compilation errors in field_bench.zig caused by Field.init() signature change requiring allocator parameter.

## Description
After the Field struct enhancement in issue #010, the benchmark suite fails to compile because Field.init() now requires an allocator parameter. The benchmarks still call init() without arguments, causing build failures when running `zig build benchmark`.

## Acceptance Criteria
- [ ] Update all Field.init() calls in benchmarks to pass allocator
- [ ] Add benchmarks for new Field struct features (metadata, boundaries, hash marks)
- [ ] Ensure benchmarks compile and run successfully
- [ ] Verify benchmark performance metrics are reasonable
- [ ] Update benchmark tests to match new signatures

## Dependencies
- #010: Design Field struct layout (COMPLETED)

## Error Details
```
benchmarks/field_bench.zig:63:24: error: expected 1 argument(s), found 0
        _ = field.Field.init();
            ~~~~~~~~~~~^~~~~
lib/field.zig:128:13: note: function declared here
        pub fn init(allocator: std.mem.Allocator) Field {
```

## Implementation Notes

### Required Changes (benchmarks/field_bench.zig)

1. **Update Field initialization**:
```zig
fn benchFieldInit() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var f = field.Field.init(allocator);
    defer f.deinit();
}
```

2. **Add new benchmarks for enhanced features**:
```zig
fn benchFieldMetadata() void {
    // Benchmark accessing metadata fields
}

fn benchFieldBoundaries() void {
    // Benchmark boundary field access
}

fn benchFieldHashMarks() void {
    // Benchmark hash mark position calculations
}
```

## Testing Requirements
- Verify all benchmarks compile without errors
- Run benchmark suite and confirm reasonable timings
- Ensure memory is properly managed in benchmarks
- Test both debug and release builds

## Estimated Time
30 minutes - 1 hour

## Priority
🔴 **Critical** - Benchmarks currently fail to build, blocking performance testing

## Category
Bug Fix / Build Issue

---
*Created: 2025-09-01*
*Status: Pending*