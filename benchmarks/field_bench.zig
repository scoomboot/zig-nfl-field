// field_bench.zig — Performance benchmarks for NFL field module
//
// repo   : https://github.com/fisty/zig-nfl-field
// author : https://github.com/fisty
//
// Vibe coded by fisty.

// ╔═══════════════════════════════════════════════════════════════════════════════════════╗
// ║                                          IMPORTS                                         ║
// ╚═══════════════════════════════════════════════════════════════════════════════════════╝

    const std = @import("std");
    const field = @import("field");
    const time = std.time;
    const print = std.debug.print;

// ╔═══════════════════════════════════════════════════════════════════════════════════════╗
// ║                                   BENCHMARK UTILITIES                                    ║
// ╚═══════════════════════════════════════════════════════════════════════════════════════╝

    /// Simple benchmark timer
    const BenchTimer = struct {
        start: i128,
        
        pub fn init() BenchTimer {
            return BenchTimer{
                .start = time.nanoTimestamp(),
            };
        }
        
        pub fn lap(self: *BenchTimer) f64 {
            const end = time.nanoTimestamp();
            const elapsed = @as(f64, @floatFromInt(end - self.start));
            self.start = end;
            return elapsed / 1_000_000.0; // Convert to milliseconds
        }
    };
    
    /// Run a benchmark function multiple times and report timing
    fn benchmarkRun(name: []const u8, iterations: usize, func: fn() void) void {
        var timer = BenchTimer.init();
        
        // Warmup runs (10% of iterations)
        const warmup_count = @max(1, iterations / 10);
        for (0..warmup_count) |_| {
            func();
        }
        
        // Reset timer after warmup
        timer = BenchTimer.init();
        
        // Actual benchmark
        for (0..iterations) |_| {
            func();
        }
        
        const elapsed = timer.lap();
        const per_iter = elapsed / @as(f64, @floatFromInt(iterations));
        const per_iter_ns = per_iter * 1_000_000.0; // Convert to nanoseconds
        
        // Print with appropriate units
        if (per_iter_ns < 1000) {
            print("[BENCH] {s}: {d:.3}ms total, {d:.1}ns per iteration ({} iterations)\n", 
                  .{name, elapsed, per_iter_ns, iterations});
        } else if (per_iter < 1.0) {
            print("[BENCH] {s}: {d:.3}ms total, {d:.3}µs per iteration ({} iterations)\n", 
                  .{name, elapsed, per_iter * 1000.0, iterations});
        } else {
            print("[BENCH] {s}: {d:.3}ms total, {d:.3}ms per iteration ({} iterations)\n", 
                  .{name, elapsed, per_iter, iterations});
        }
    }

// ╔═══════════════════════════════════════════════════════════════════════════════════════╗
// ║                                    FIELD BENCHMARKS                                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════════════╝

    fn benchFieldInit() void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        
        var f = field.Field.init(allocator);
        defer f.deinit();
        // Prevent optimization by using the result
        std.mem.doNotOptimizeAway(&f);
    }
    
    fn benchFieldContains() void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        
        var f = field.Field.init(allocator);
        defer f.deinit();
        const result = f.contains(26.67, 60);
        std.mem.doNotOptimizeAway(result);
    }
    
    fn benchFieldEndzoneChecks() void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        
        var f = field.Field.init(allocator);
        defer f.deinit();
        const r1 = f.isInHomeEndzone(5);
        const r2 = f.isInAwayEndzone(115);
        const r3 = f.isInPlayingField(60);
        std.mem.doNotOptimizeAway(r1);
        std.mem.doNotOptimizeAway(r2);
        std.mem.doNotOptimizeAway(r3);
    }
    
    fn benchFieldMetadata() void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        
        var f = field.Field.init(allocator);
        defer f.deinit();
        // Access metadata fields
        const name = f.name;
        const surface = f.surface_type;
        std.mem.doNotOptimizeAway(name.ptr);
        std.mem.doNotOptimizeAway(&surface);
    }
    
    fn benchFieldBoundaries() void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        
        var f = field.Field.init(allocator);
        defer f.deinit();
        // Access all boundary fields
        const north = f.north_boundary;
        const south = f.south_boundary;
        const east = f.east_boundary;
        const west = f.west_boundary;
        std.mem.doNotOptimizeAway(north);
        std.mem.doNotOptimizeAway(south);
        std.mem.doNotOptimizeAway(east);
        std.mem.doNotOptimizeAway(west);
    }
    
    fn benchFieldHashMarks() void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        
        var f = field.Field.init(allocator);
        defer f.deinit();
        // Access hash mark positions
        const left_hash = f.left_hash_x;
        const right_hash = f.right_hash_x;
        const center = f.center_x;
        std.mem.doNotOptimizeAway(left_hash);
        std.mem.doNotOptimizeAway(right_hash);
        std.mem.doNotOptimizeAway(center);
    }

// ╔═══════════════════════════════════════════════════════════════════════════════════════╗
// ║                                  COORDINATE BENCHMARKS                                   ║
// ╚═══════════════════════════════════════════════════════════════════════════════════════╝

    fn benchCoordinateInit() void {
        const c = field.Coordinate.init(26.67, 50.5);
        std.mem.doNotOptimizeAway(&c);
    }
    
    fn benchCoordinateDistance() void {
        const c1 = field.Coordinate.init(0, 0);
        const c2 = field.Coordinate.init(26.67, 60);
        const dist = c1.distanceTo(c2);
        std.mem.doNotOptimizeAway(dist);
    }
    
    fn benchCoordinateValidation() void {
        const c = field.Coordinate.init(26.67, 60);
        const valid = c.isValid();
        std.mem.doNotOptimizeAway(valid);
    }

// ╔═══════════════════════════════════════════════════════════════════════════════════════╗
// ║                                      ENTRY POINT                                         ║
// ╚═══════════════════════════════════════════════════════════════════════════════════════╝

    pub fn main() !void {
        print("\n=== NFL Field Module Benchmarks ===\n\n", .{});
        
        // Field benchmarks
        print("Field Operations:\n", .{});
        print("-----------------\n", .{});
        benchmarkRun("Field.init", 100_000, benchFieldInit);
        benchmarkRun("Field.contains", 1_000_000, benchFieldContains);
        benchmarkRun("Field.endzone checks", 1_000_000, benchFieldEndzoneChecks);
        benchmarkRun("Field.metadata access", 1_000_000, benchFieldMetadata);
        benchmarkRun("Field.boundaries access", 1_000_000, benchFieldBoundaries);
        benchmarkRun("Field.hash marks access", 1_000_000, benchFieldHashMarks);
        
        print("\n", .{});
        
        // Coordinate benchmarks
        print("Coordinate Operations:\n", .{});
        print("----------------------\n", .{});
        benchmarkRun("Coordinate.init", 1_000_000, benchCoordinateInit);
        benchmarkRun("Coordinate.distanceTo", 1_000_000, benchCoordinateDistance);
        benchmarkRun("Coordinate.isValid", 1_000_000, benchCoordinateValidation);
        
        print("\n=== Benchmarks Complete ===\n\n", .{});
    }

// ╔═══════════════════════════════════════════════════════════════════════════════════════╗
// ║                                          TEST                                            ║
// ╚═══════════════════════════════════════════════════════════════════════════════════════╝

    test "unit: BenchTimer: timer works correctly" {
        var timer = BenchTimer.init();
        time.sleep(10 * time.ns_per_ms); // Sleep for 10ms
        const elapsed = timer.lap();
        
        // Should be roughly 10ms (allow some variance)
        try std.testing.expect(elapsed >= 9.0);
        try std.testing.expect(elapsed <= 15.0);
    }
    
    test "unit: Benchmarks: functions compile and run" {
        // Just verify the benchmark functions compile and can execute
        // Note: These now allocate memory internally
        benchFieldInit();
        benchFieldContains();
        benchFieldEndzoneChecks();
        benchFieldMetadata();
        benchFieldBoundaries();
        benchFieldHashMarks();
        benchCoordinateInit();
        benchCoordinateDistance();
        benchCoordinateValidation();
    }