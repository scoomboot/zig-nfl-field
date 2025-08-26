// build.zig — Build configuration for zig-nfl-field library
//
// repo   : https://github.com/fisty/zig-nfl-field
// author : https://github.com/fisty
//
// Vibe coded by Fisty.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ╔══════════════════════════════════════ MODULE DEFINITION ══════════════════════════════════════╗
    
    // Create the field module for external consumption
    const field_module = b.addModule("field", .{
        .root_source_file = b.path("lib/field.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝

    // ╔══════════════════════════════════════ LIBRARY ARTIFACT ═══════════════════════════════════════╗

    // Create static library artifact
    const field_lib = b.addStaticLibrary(.{
        .name = "nflField",
        .root_source_file = b.path("lib/field.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Install the library artifact
    b.installArtifact(field_lib);

    // ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝

    // ╔══════════════════════════════════════ TESTING CONFIGURATION ══════════════════════════════════╗

    // Add unit tests
    const field_tests = b.addTest(.{
        .root_source_file = b.path("lib/field.test.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create test running step
    const run_tests = b.addRunArtifact(field_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝

    // ╔══════════════════════════════════════ BENCHMARK CONFIGURATION ════════════════════════════════╗

    // Add benchmark executable
    const field_bench = b.addExecutable(.{
        .name = "field_bench",
        .root_source_file = b.path("benchmarks/field_bench.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    // Import field module into benchmarks
    field_bench.root_module.addImport("field", field_module);

    // Create benchmark running step
    const run_bench = b.addRunArtifact(field_bench);
    const bench_step = b.step("benchmark", "Run benchmarks");
    bench_step.dependOn(&run_bench.step);

    // Add benchmark tests (for testing benchmark code itself)
    const bench_tests = b.addTest(.{
        .root_source_file = b.path("benchmarks/field_bench.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    bench_tests.root_module.addImport("field", field_module);

    const run_bench_tests = b.addRunArtifact(bench_tests);
    const bench_test_step = b.step("test:benchmark", "Run benchmark tests");
    bench_test_step.dependOn(&run_bench_tests.step);

    // ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝
}