// field_bench.zig — Performance benchmarks for NFL field module
//
// repo   : https://github.com/fisty/zig-nfl-field
// author : https://github.com/fisty
//
// Vibe coded by Fisty.

const std = @import("std");
const field = @import("field");
const time = std.time;
const print = std.debug.print;

// ╔══════════════════════════════════════ BENCHMARK UTILITIES ══════════════════════════════════════╗

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
        
        // Warmup
        func();
        
        timer = BenchTimer.init();
        
        // Actual benchmark
        for (0..iterations) |_| {
            func();
        }
        
        const elapsed = timer.lap();
        const per_iter = elapsed / @as(f64, @floatFromInt(iterations));
        
        print("[BENCH] {s}: {d:.3}ms total, {d:.6}ms per iteration ({} iterations)\n", 
              .{name, elapsed, per_iter, iterations});
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ FIELD BENCHMARKS ═════════════════════════════════════════╗

    fn benchFieldInit() void {
        _ = field.Field.init();
    }
    
    fn benchFieldContains() void {
        const f = field.Field.init();
        _ = f.contains(60, 26.67);
    }
    
    fn benchFieldEndzoneChecks() void {
        const f = field.Field.init();
        _ = f.isInHomeEndzone(5);
        _ = f.isInAwayEndzone(115);
        _ = f.isInPlayingField(60);
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ COORDINATE BENCHMARKS ════════════════════════════════════╗

    fn benchCoordinateInit() void {
        _ = field.Coordinate.init(50.5, 26.67);
    }
    
    fn benchCoordinateDistance() void {
        const c1 = field.Coordinate.init(0, 0);
        const c2 = field.Coordinate.init(60, 26.67);
        _ = c1.distanceTo(c2);
    }
    
    fn benchCoordinateValidation() void {
        const f = field.Field.init();
        const c = field.Coordinate.init(60, 26.67);
        _ = c.isValid(f);
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ MAIN ═════════════════════════════════════════════════════╗

    pub fn main() !void {
        print("\n=== NFL Field Module Benchmarks ===\n\n", .{});
        
        // Field benchmarks
        print("Field Operations:\n", .{});
        print("-----------------\n", .{});
        benchmarkRun("Field.init", 1_000_000, benchFieldInit);
        benchmarkRun("Field.contains", 1_000_000, benchFieldContains);
        benchmarkRun("Field.endzone checks", 1_000_000, benchFieldEndzoneChecks);
        
        print("\n", .{});
        
        // Coordinate benchmarks
        print("Coordinate Operations:\n", .{});
        print("----------------------\n", .{});
        benchmarkRun("Coordinate.init", 1_000_000, benchCoordinateInit);
        benchmarkRun("Coordinate.distanceTo", 1_000_000, benchCoordinateDistance);
        benchmarkRun("Coordinate.isValid", 1_000_000, benchCoordinateValidation);
        
        print("\n=== Benchmarks Complete ===\n\n", .{});
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TESTS ════════════════════════════════════════════════════╗

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
        benchFieldInit();
        benchFieldContains();
        benchFieldEndzoneChecks();
        benchCoordinateInit();
        benchCoordinateDistance();
        benchCoordinateValidation();
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝