// field.test.zig — Unit tests for NFL field module
//
// repo   : https://github.com/fisty/zig-nfl-field
// author : https://github.com/fisty
//
// Vibe coded by fisty.

const std = @import("std");
const testing = std.testing;
const field = @import("field.zig");

// ╔══════════════════════════════════════ CONSTANTS TESTS ══════════════════════════════════════╗

    // ┌──────────────────────────── Unit Tests ────────────────────────────┐
    
        test "unit: Constants: field dimensions match NFL specifications" {
            // Total field length: 120 yards (100 playing + 2×10 endzones)
            try testing.expectEqual(@as(f32, 120.0), field.FIELD_LENGTH_YARDS);
            try testing.expectEqual(@as(f32, 100.0), field.PLAYING_FIELD_LENGTH_YARDS);
            try testing.expectEqual(@as(f32, 10.0), field.END_ZONE_LENGTH_YARDS);
            
            // Field width: 53⅓ yards / 160 feet exactly
            try testing.expectEqual(@as(f32, 53.333333), field.FIELD_WIDTH_YARDS);
            try testing.expectEqual(@as(f32, 160.0), field.FIELD_WIDTH_FEET);
            
            // Verify relationship: playing field + 2 endzones = total length
            const calculated_total = field.PLAYING_FIELD_LENGTH_YARDS + (2 * field.END_ZONE_LENGTH_YARDS);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, calculated_total);
        }
        
        test "unit: Constants: hash mark positioning is accurate" {
            // Hash mark separation: 23.583333 yards (70'9" exactly)
            try testing.expectEqual(@as(f32, 23.583333), field.HASH_SEPARATION_YARDS);
            
            // Distance from sideline: 14.875 yards  
            try testing.expectEqual(@as(f32, 14.875), field.HASH_FROM_SIDELINE_YARDS);
            
            // Verify hash marks are centered on field
            // 2 * hash_from_sideline + hash_separation should equal field width
            const calculated_width = (2 * field.HASH_FROM_SIDELINE_YARDS) + field.HASH_SEPARATION_YARDS;
            const expected_width = field.FIELD_WIDTH_YARDS;
            
            // Allow small floating point tolerance
            const tolerance = 0.001;
            try testing.expect(@abs(calculated_width - expected_width) < tolerance);
        }
        
        test "unit: Constants: conversion factors are precise" {
            // Yards to feet: exactly 3 feet per yard
            try testing.expectEqual(@as(f32, 3.0), field.YARDS_TO_FEET);
            
            // Feet to yards: exactly 1/3 yard per foot
            try testing.expectEqual(@as(f32, 0.333333), field.FEET_TO_YARDS);
            
            // Verify conversion consistency
            const test_yards: f32 = 53.333333;
            const converted_to_feet = test_yards * field.YARDS_TO_FEET;
            const back_to_yards = converted_to_feet * field.FEET_TO_YARDS;
            
            const tolerance = 0.001;
            try testing.expect(@abs(test_yards - back_to_yards) < tolerance);
        }
        
        test "unit: Constants: field width conversions are exact" {
            // NFL specification: field width is exactly 160 feet
            try testing.expectEqual(@as(f32, 160.0), field.FIELD_WIDTH_FEET);
            
            // Verify yards-to-feet conversion for field width
            const yards_converted_to_feet = field.FIELD_WIDTH_YARDS * field.YARDS_TO_FEET;
            
            // Should be very close to 160 feet (within floating point precision)
            const tolerance = 0.01;
            try testing.expect(@abs(yards_converted_to_feet - field.FIELD_WIDTH_FEET) < tolerance);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Integration Tests ────────────────────────────┐
    
        test "integration: Field: uses updated constants correctly" {
            const f = field.Field.init(std.testing.allocator);
            
            // Verify Field struct uses the correct constants
            try testing.expectEqual(field.FIELD_WIDTH_YARDS, f.width);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, f.length);
            try testing.expectEqual(field.END_ZONE_LENGTH_YARDS, f.endzone_length);
            
            // Test boundary conditions with exact constant values
            try testing.expect(f.contains(0, 0));
            try testing.expect(f.contains(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS));
            try testing.expect(!f.contains(field.FIELD_WIDTH_YARDS + 0.1, field.FIELD_LENGTH_YARDS));
            try testing.expect(!f.contains(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS + 0.1));
        }
        
        test "integration: Coordinate: validates against constant-based boundaries" {
            // Test coordinates at exact constant boundaries
            const corner_coord = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            try testing.expect(corner_coord.isValid());
            
            const hash_coord = field.Coordinate.init(field.HASH_FROM_SIDELINE_YARDS, 50);
            try testing.expect(hash_coord.isValid());
            
            // Test coordinates just outside boundaries
            const outside_length = field.Coordinate.init(26, field.FIELD_LENGTH_YARDS + 0.1);
            try testing.expect(!outside_length.isValid());
            
            const outside_width = field.Coordinate.init(field.FIELD_WIDTH_YARDS + 0.1, 60);
            try testing.expect(!outside_width.isValid());
        }
        
        test "integration: Field: endzone detection with constants" {
            const f = field.Field.init(std.testing.allocator);
            
            // Test endzone boundaries using constants
            try testing.expect(f.isInHomeEndzone(0));
            try testing.expect(f.isInHomeEndzone(field.END_ZONE_LENGTH_YARDS - 0.1));
            try testing.expect(!f.isInHomeEndzone(field.END_ZONE_LENGTH_YARDS));
            
            const away_endzone_start = field.FIELD_LENGTH_YARDS - field.END_ZONE_LENGTH_YARDS;
            try testing.expect(!f.isInAwayEndzone(away_endzone_start));
            try testing.expect(f.isInAwayEndzone(away_endzone_start + 0.1));
            try testing.expect(f.isInAwayEndzone(field.FIELD_LENGTH_YARDS));
            
            // Test playing field boundaries
            try testing.expect(!f.isInPlayingField(field.END_ZONE_LENGTH_YARDS - 0.1));
            try testing.expect(f.isInPlayingField(field.END_ZONE_LENGTH_YARDS));
            try testing.expect(f.isInPlayingField(away_endzone_start));
            try testing.expect(!f.isInPlayingField(away_endzone_start + 0.1));
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Scenario Tests ────────────────────────────┐
    
        test "scenario: NFL rule compliance: field dimensions" {
            // Scenario: Official NFL field measurements per rulebook
            // Rule: Playing field shall be 100 yards long between goal lines
            try testing.expectEqual(@as(f32, 100.0), field.PLAYING_FIELD_LENGTH_YARDS);
            
            // Rule: Field shall be 53⅓ yards wide (160 feet exactly)
            try testing.expectEqual(@as(f32, 160.0), field.FIELD_WIDTH_FEET);
            
            // Rule: Each end zone shall be 10 yards deep
            try testing.expectEqual(@as(f32, 10.0), field.END_ZONE_LENGTH_YARDS);
            
            // Scenario: Total field length for TV graphics and measurements
            try testing.expectEqual(@as(f32, 120.0), field.FIELD_LENGTH_YARDS);
        }
        
        test "scenario: NFL rule compliance: hash mark positioning" {
            // Scenario: Hash marks for ball placement per NFL rules
            // Rule: Hash marks shall be 70'9" apart (23.583333 yards)
            try testing.expectEqual(@as(f32, 23.583333), field.HASH_SEPARATION_YARDS);
            
            // Rule: Hash marks shall be 44'6" from each sideline
            try testing.expectEqual(@as(f32, 14.875), field.HASH_FROM_SIDELINE_YARDS);
            
            // Scenario: Ball placement at hash marks
            const left_hash = field.Coordinate.init(field.HASH_FROM_SIDELINE_YARDS, 50);
            const right_hash = field.Coordinate.init(field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS, 50);
            
            try testing.expect(left_hash.isValid());
            try testing.expect(right_hash.isValid());
            
            // Verify hash separation distance
            const separation = right_hash.distanceTo(left_hash);
            const tolerance = 0.001;
            try testing.expect(@abs(separation - field.HASH_SEPARATION_YARDS) < tolerance);
        }
        
        test "scenario: NFL rule compliance: measurement conversions" {
            // Scenario: Converting between yards and feet for official measurements
            const test_distance_yards: f32 = 10.0;
            const converted_feet = test_distance_yards * field.YARDS_TO_FEET;
            
            // 10 yards should equal exactly 30 feet
            try testing.expectEqual(@as(f32, 30.0), converted_feet);
            
            // Scenario: Field width measurement consistency
            const width_from_yards = field.FIELD_WIDTH_YARDS * field.YARDS_TO_FEET;
            const tolerance = 0.01;
            try testing.expect(@abs(width_from_yards - field.FIELD_WIDTH_FEET) < tolerance);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Performance Tests ────────────────────────────┐
    
        test "performance: Constants: access time is negligible" {
            // Performance requirement: Constant access should be compile-time optimized
            const start_time = std.time.nanoTimestamp();
            
            // Access all constants multiple times
            var sum: f32 = 0;
            var i: u32 = 0;
            while (i < 10000) : (i += 1) {
                sum += field.FIELD_LENGTH_YARDS;
                sum += field.FIELD_WIDTH_YARDS;
                sum += field.PLAYING_FIELD_LENGTH_YARDS;
                sum += field.END_ZONE_LENGTH_YARDS;
                sum += field.HASH_SEPARATION_YARDS;
                sum += field.HASH_FROM_SIDELINE_YARDS;
                sum += field.YARDS_TO_FEET;
                sum += field.FEET_TO_YARDS;
            }
            
            const end_time = std.time.nanoTimestamp();
            const elapsed_ns = end_time - start_time;
            
            // Should complete very quickly (under 1 millisecond for 10k iterations)
            try testing.expect(elapsed_ns < 1_000_000); // 1ms in nanoseconds
            
            // Prevent optimization from removing the loop
            try testing.expect(sum > 0);
        }
        
        test "performance: Field: initialization with constants" {
            // Performance requirement: Field initialization should be sub-microsecond
            const iterations = 1000;
            const start_time = std.time.nanoTimestamp();
            
            var i: u32 = 0;
            while (i < iterations) : (i += 1) {
                const f = field.Field.init(std.testing.allocator);
                // Use the field to prevent optimization
                _ = f.contains(50, 25);
            }
            
            const end_time = std.time.nanoTimestamp();
            const elapsed_ns = end_time - start_time;
            const avg_ns_per_init = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(iterations));
            
            // Average initialization should be under 1 microsecond
            try testing.expect(avg_ns_per_init < 1000); // 1μs in nanoseconds
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Stress Tests ────────────────────────────┐
    
        test "stress: Constants: precision under arithmetic operations" {
            // Stress test: Verify constants maintain precision under repeated operations
            var accumulator = field.FIELD_WIDTH_YARDS;
            
            // Perform 1,000 conversion operations (reduced for better precision)
            var i: u32 = 0;
            while (i < 1000) : (i += 1) {
                accumulator = accumulator * field.YARDS_TO_FEET * field.FEET_TO_YARDS;
            }
            
            // Should be very close to original value - allow larger tolerance for repeated float ops
            const tolerance = 0.1; // Allow 10cm tolerance after 1k operations due to f32 precision limits
            try testing.expect(@abs(accumulator - field.FIELD_WIDTH_YARDS) < tolerance);
        }
        
        test "stress: Constants: extreme coordinate validation" {
            const f = field.Field.init(std.testing.allocator);
            
            // Test coordinates with small but measurable differences
            const small_offset: f32 = 0.001; // 1mm precision
            const large_value: f32 = 1000000.0; // Large but manageable value
            
            // Coordinates just inside bounds
            const barely_inside_x = field.FIELD_WIDTH_YARDS - small_offset;
            const barely_inside_y = field.FIELD_LENGTH_YARDS - small_offset;
            try testing.expect(f.contains(barely_inside_x, barely_inside_y));
            
            // Coordinates just outside bounds  
            const barely_outside_x = field.FIELD_WIDTH_YARDS + small_offset;
            const barely_outside_y = field.FIELD_LENGTH_YARDS + small_offset;
            try testing.expect(!f.contains(barely_outside_x, barely_outside_y));
            
            // Extremely large coordinates
            try testing.expect(!f.contains(large_value, 25));
            try testing.expect(!f.contains(26.67, large_value));
            
            // Extremely small (negative) coordinates
            try testing.expect(!f.contains(-large_value, 25));
            try testing.expect(!f.contains(26.67, -large_value));
        }
    
    // └──────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ FIELD STRUCT TESTS ══════════════════════════════════════╗

    test "unit: Field: init creates field with correct dimensions" {
        const f = field.Field.init(std.testing.allocator);
        
        try testing.expectEqual(@as(f32, field.FIELD_WIDTH_YARDS), f.width);
        try testing.expectEqual(@as(f32, field.FIELD_LENGTH_YARDS), f.length);
        try testing.expectEqual(@as(f32, field.END_ZONE_LENGTH_YARDS), f.endzone_length);
    }
    
    test "unit: Field: contains validates boundaries correctly" {
        const f = field.Field.init(std.testing.allocator);
        
        // Test valid coordinates using constants
        try testing.expect(f.contains(0, 0));
        try testing.expect(f.contains(field.FIELD_WIDTH_YARDS / 2, 60));
        try testing.expect(f.contains(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS));
        
        // Test invalid coordinates
        try testing.expect(!f.contains(-1, field.FIELD_WIDTH_YARDS / 2));
        try testing.expect(!f.contains(field.FIELD_LENGTH_YARDS + 1, field.FIELD_WIDTH_YARDS / 2));
        try testing.expect(!f.contains(-1, 60));
        try testing.expect(!f.contains(field.FIELD_WIDTH_YARDS + 1, 60));
    }
    
    test "unit: Field: endzone detection works correctly" {
        const f = field.Field.init(std.testing.allocator);
        
        // Home endzone tests using constants
        try testing.expect(f.isInHomeEndzone(field.END_ZONE_LENGTH_YARDS / 2));
        try testing.expect(f.isInHomeEndzone(0));
        try testing.expect(f.isInHomeEndzone(field.END_ZONE_LENGTH_YARDS - 0.01));
        try testing.expect(!f.isInHomeEndzone(field.END_ZONE_LENGTH_YARDS));
        try testing.expect(!f.isInHomeEndzone(field.FIELD_LENGTH_YARDS / 2));
        
        // Away endzone tests using constants  
        const away_start = field.FIELD_LENGTH_YARDS - field.END_ZONE_LENGTH_YARDS;
        try testing.expect(f.isInAwayEndzone(away_start + field.END_ZONE_LENGTH_YARDS / 2));
        try testing.expect(f.isInAwayEndzone(field.FIELD_LENGTH_YARDS));
        try testing.expect(f.isInAwayEndzone(away_start + 0.01));
        try testing.expect(!f.isInAwayEndzone(away_start));
        try testing.expect(!f.isInAwayEndzone(field.FIELD_LENGTH_YARDS / 2));
        
        // Playing field tests using constants
        try testing.expect(f.isInPlayingField(field.END_ZONE_LENGTH_YARDS));
        try testing.expect(f.isInPlayingField(field.FIELD_LENGTH_YARDS / 2));
        try testing.expect(f.isInPlayingField(away_start));
        try testing.expect(!f.isInPlayingField(field.END_ZONE_LENGTH_YARDS - 0.01));
        try testing.expect(!f.isInPlayingField(away_start + 0.01));
    }
    
    test "unit: Field: enhanced metadata fields initialized correctly" {
        const f = field.Field.init(std.testing.allocator);
        defer {
            var mutable_f = f;
            mutable_f.deinit();
        }
        
        // Test metadata fields
        try testing.expectEqualStrings("NFL Field", f.name);
        try testing.expectEqual(field.SurfaceType.turf, f.surface_type);
        
        // Test boundary fields
        try testing.expectEqual(field.FIELD_LENGTH_YARDS, f.north_boundary);
        try testing.expectEqual(@as(f32, 0.0), f.south_boundary);
        try testing.expectEqual(field.FIELD_WIDTH_YARDS, f.east_boundary);
        try testing.expectEqual(@as(f32, 0.0), f.west_boundary);
        
        // Test hash mark and center positions
        try testing.expectEqual(field.HASH_FROM_SIDELINE_YARDS, f.left_hash_x);
        try testing.expectEqual(field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS, f.right_hash_x);
        try testing.expectEqual(field.FIELD_WIDTH_YARDS / 2.0, f.center_x);
        
        // Verify allocator is stored
        try testing.expectEqual(std.testing.allocator, f.allocator);
    }
    
    test "unit: Field: all SurfaceType enum values are valid" {
        // Test that we can create fields with each surface type
        var grass_field = field.Field.init(std.testing.allocator);
        grass_field.surface_type = field.SurfaceType.grass;
        defer grass_field.deinit();
        try testing.expectEqual(field.SurfaceType.grass, grass_field.surface_type);
        
        var turf_field = field.Field.init(std.testing.allocator);
        turf_field.surface_type = field.SurfaceType.turf;
        defer turf_field.deinit();
        try testing.expectEqual(field.SurfaceType.turf, turf_field.surface_type);
        
        var hybrid_field = field.Field.init(std.testing.allocator);
        hybrid_field.surface_type = field.SurfaceType.hybrid;
        defer hybrid_field.deinit();
        try testing.expectEqual(field.SurfaceType.hybrid, hybrid_field.surface_type);
    }
    
    test "unit: Field: all Orientation enum values are valid" {
        // Test that Orientation enum values exist and are distinct
        const north_south = field.Orientation.north_south;
        const east_west = field.Orientation.east_west;
        
        // Enums should be distinct values
        try testing.expect(north_south != east_west);
    }
    
    test "unit: Field: deinit can be called safely" {
        var f = field.Field.init(std.testing.allocator);
        
        // Deinit should be safe to call even without dynamic allocations
        f.deinit();
        
        // Should be able to call deinit multiple times without issue
        f.deinit();
        f.deinit();
        
        // Field should still be usable after deinit (currently no state change)
        try testing.expect(f.contains(26.67, 60));
    }
    
    test "unit: Field: hash mark positions calculated correctly" {
        const f = field.Field.init(std.testing.allocator);
        defer {
            var mutable_f = f;
            mutable_f.deinit();
        }
        
        // Left hash should be at exact distance from west sideline
        try testing.expectEqual(field.HASH_FROM_SIDELINE_YARDS, f.left_hash_x);
        
        // Right hash should be at exact distance from east sideline
        const expected_right_hash = field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS;
        try testing.expectEqual(expected_right_hash, f.right_hash_x);
        
        // Distance between hashes should match NFL specification
        const hash_separation = f.right_hash_x - f.left_hash_x;
        const tolerance = 0.001;
        try testing.expect(@abs(hash_separation - field.HASH_SEPARATION_YARDS) < tolerance);
        
        // Center should be exactly at field midpoint
        try testing.expectEqual(field.FIELD_WIDTH_YARDS / 2.0, f.center_x);
        
        // Center should be equidistant from both hashes
        const left_to_center = f.center_x - f.left_hash_x;
        const center_to_right = f.right_hash_x - f.center_x;
        try testing.expect(@abs(left_to_center - center_to_right) < tolerance);
    }
    
    test "unit: Field: boundary fields match field dimensions" {
        const f = field.Field.init(std.testing.allocator);
        defer {
            var mutable_f = f;
            mutable_f.deinit();
        }
        
        // North boundary should equal field length
        try testing.expectEqual(f.length, f.north_boundary);
        
        // East boundary should equal field width
        try testing.expectEqual(f.width, f.east_boundary);
        
        // South and west boundaries should be zero
        try testing.expectEqual(@as(f32, 0.0), f.south_boundary);
        try testing.expectEqual(@as(f32, 0.0), f.west_boundary);
        
        // Boundaries should define valid field area
        const boundary_width = f.east_boundary - f.west_boundary;
        const boundary_length = f.north_boundary - f.south_boundary;
        try testing.expectEqual(f.width, boundary_width);
        try testing.expectEqual(f.length, boundary_length);
    }
    
    test "unit: Field: FieldError types are distinct" {
        // Test that error types exist and can be used
        const err1: field.FieldError = field.FieldError.InvalidDimensions;
        const err2: field.FieldError = field.FieldError.AllocationError;
        
        // Errors should be distinct
        try testing.expect(err1 != err2);
    }
    
    test "integration: Field: existing methods work with enhanced struct" {
        const f = field.Field.init(std.testing.allocator);
        defer {
            var mutable_f = f;
            mutable_f.deinit();
        }
        
        // Test that contains still works correctly
        try testing.expect(f.contains(f.center_x, 60));
        try testing.expect(f.contains(f.left_hash_x, 50));
        try testing.expect(f.contains(f.right_hash_x, 50));
        try testing.expect(!f.contains(f.east_boundary + 1, 60));
        try testing.expect(!f.contains(26.67, f.north_boundary + 1));
        
        // Test endzone detection with boundary fields
        try testing.expect(f.isInHomeEndzone(f.south_boundary + 5));
        try testing.expect(!f.isInHomeEndzone(f.endzone_length + 1));
        try testing.expect(f.isInAwayEndzone(f.north_boundary - 5));
        try testing.expect(!f.isInAwayEndzone(f.north_boundary - f.endzone_length - 1));
        
        // Test playing field detection
        const playing_field_start = f.south_boundary + f.endzone_length;
        const playing_field_end = f.north_boundary - f.endzone_length;
        try testing.expect(f.isInPlayingField(playing_field_start));
        try testing.expect(f.isInPlayingField(playing_field_end));
        try testing.expect(f.isInPlayingField((playing_field_start + playing_field_end) / 2));
    }
    
    test "integration: Field: coordinates interact correctly with enhanced boundaries" {
        const f = field.Field.init(std.testing.allocator);
        defer {
            var mutable_f = f;
            mutable_f.deinit();
        }
        
        // Test coordinates at hash marks
        const left_hash_coord = field.Coordinate.init(f.left_hash_x, 50);
        const right_hash_coord = field.Coordinate.init(f.right_hash_x, 50);
        const center_coord = field.Coordinate.init(f.center_x, 50);
        
        try testing.expect(left_hash_coord.isValidForField(f));
        try testing.expect(right_hash_coord.isValidForField(f));
        try testing.expect(center_coord.isValidForField(f));
        
        // Test coordinates at boundaries
        const sw_corner = field.Coordinate.init(f.west_boundary, f.south_boundary);
        const ne_corner = field.Coordinate.init(f.east_boundary, f.north_boundary);
        
        try testing.expect(sw_corner.isValidForField(f));
        try testing.expect(ne_corner.isValidForField(f));
        
        // Test coordinates beyond boundaries
        const beyond_north = field.Coordinate.init(f.center_x, f.north_boundary + 1);
        const beyond_east = field.Coordinate.init(f.east_boundary + 1, 60);
        
        try testing.expect(!beyond_north.isValidForField(f));
        try testing.expect(!beyond_east.isValidForField(f));
    }
    
    test "scenario: Field: NFL regulation field with grass surface" {
        var grass_field = field.Field.init(std.testing.allocator);
        grass_field.surface_type = field.SurfaceType.grass;
        grass_field.name = "Lambeau Field";
        defer grass_field.deinit();
        
        // Verify field meets NFL specifications
        try testing.expectEqual(field.FIELD_WIDTH_YARDS, grass_field.width);
        try testing.expectEqual(field.FIELD_LENGTH_YARDS, grass_field.length);
        try testing.expectEqual(field.SurfaceType.grass, grass_field.surface_type);
        try testing.expectEqualStrings("Lambeau Field", grass_field.name);
        
        // Verify hash marks are regulation distance
        const hash_separation = grass_field.right_hash_x - grass_field.left_hash_x;
        const tolerance = 0.001;
        try testing.expect(@abs(hash_separation - field.HASH_SEPARATION_YARDS) < tolerance);
        
        // Verify field boundaries for game play
        const kickoff_spot = field.Coordinate.init(grass_field.center_x, 35);
        try testing.expect(kickoff_spot.isValidForField(grass_field));
        try testing.expect(grass_field.isInPlayingField(35));
    }
    
    test "scenario: Field: indoor stadium with turf surface" {
        var turf_field = field.Field.init(std.testing.allocator);
        turf_field.surface_type = field.SurfaceType.turf;
        turf_field.name = "US Bank Stadium";
        defer turf_field.deinit();
        
        // Indoor stadiums typically use turf
        try testing.expectEqual(field.SurfaceType.turf, turf_field.surface_type);
        
        // All standard dimensions should still apply
        try testing.expectEqual(field.FIELD_WIDTH_YARDS, turf_field.width);
        try testing.expectEqual(field.FIELD_LENGTH_YARDS, turf_field.length);
        
        // Hash marks and center line should be standard
        try testing.expectEqual(field.HASH_FROM_SIDELINE_YARDS, turf_field.left_hash_x);
        try testing.expectEqual(field.FIELD_WIDTH_YARDS / 2.0, turf_field.center_x);
    }
    
    test "scenario: Field: modern hybrid surface field" {
        var hybrid_field = field.Field.init(std.testing.allocator);
        hybrid_field.surface_type = field.SurfaceType.hybrid;
        hybrid_field.name = "State Farm Stadium";
        defer hybrid_field.deinit();
        
        // Hybrid surfaces combine natural and synthetic materials
        try testing.expectEqual(field.SurfaceType.hybrid, hybrid_field.surface_type);
        
        // Field play characteristics remain the same
        const punt_location = field.Coordinate.init(hybrid_field.center_x, 45);
        try testing.expect(punt_location.isValidForField(hybrid_field));
        try testing.expect(hybrid_field.isInPlayingField(45));
        
        // Boundaries are standard regardless of surface
        try testing.expectEqual(field.FIELD_LENGTH_YARDS, hybrid_field.north_boundary);
        try testing.expectEqual(field.FIELD_WIDTH_YARDS, hybrid_field.east_boundary);
    }
    
    test "performance: Field: initialization with allocator is fast" {
        const iterations = 10000;
        const start_time = std.time.nanoTimestamp();
        
        var i: u32 = 0;
        while (i < iterations) : (i += 1) {
            var f = field.Field.init(std.testing.allocator);
            defer f.deinit();
            
            // Use the field to prevent optimization
            _ = f.contains(f.center_x, 50);
        }
        
        const end_time = std.time.nanoTimestamp();
        const elapsed_ns = end_time - start_time;
        const avg_ns_per_init = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(iterations));
        
        // Initialization with allocator should still be sub-microsecond
        try testing.expect(avg_ns_per_init < 1000); // 1μs in nanoseconds
    }
    
    test "performance: Field: accessing hash marks and boundaries is fast" {
        const f = field.Field.init(std.testing.allocator);
        defer {
            var mutable_f = f;
            mutable_f.deinit();
        }
        
        const iterations = 100000;
        const start_time = std.time.nanoTimestamp();
        
        var sum: f32 = 0;
        var i: u32 = 0;
        while (i < iterations) : (i += 1) {
            // Access all new fields
            sum += f.left_hash_x;
            sum += f.right_hash_x;
            sum += f.center_x;
            sum += f.north_boundary;
            sum += f.south_boundary;
            sum += f.east_boundary;
            sum += f.west_boundary;
        }
        
        const end_time = std.time.nanoTimestamp();
        const elapsed_ns = end_time - start_time;
        
        // Should complete very quickly (under 10 milliseconds for 100k iterations)
        try testing.expect(elapsed_ns < 10_000_000); // 10ms in nanoseconds
        
        // Prevent optimization from removing the loop
        try testing.expect(sum > 0);
    }
    
    test "stress: Field: multiple field instances with different surfaces" {
        const allocator = std.testing.allocator;
        
        // Create many fields with different configurations
        var fields: [100]field.Field = undefined;
        
        for (&fields, 0..) |*f, i| {
            f.* = field.Field.init(allocator);
            
            // Cycle through surface types
            f.surface_type = switch (i % 3) {
                0 => field.SurfaceType.grass,
                1 => field.SurfaceType.turf,
                2 => field.SurfaceType.hybrid,
                else => unreachable,
            };
        }
        
        // Clean up all fields
        defer {
            for (&fields) |*f| {
                f.deinit();
            }
        }
        
        // Verify all fields maintain correct dimensions
        for (fields) |f| {
            try testing.expectEqual(field.FIELD_WIDTH_YARDS, f.width);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, f.length);
            try testing.expectEqual(field.HASH_FROM_SIDELINE_YARDS, f.left_hash_x);
        }
    }
    
    test "stress: Field: boundary validation under extreme coordinates" {
        const f = field.Field.init(std.testing.allocator);
        defer {
            var mutable_f = f;
            mutable_f.deinit();
        }
        
        // Test with very large coordinates
        const huge_value: f32 = 1e10;
        try testing.expect(!f.contains(huge_value, 50));
        try testing.expect(!f.contains(50, huge_value));
        try testing.expect(!f.contains(huge_value, huge_value));
        
        // Test with very small positive coordinates
        const tiny_value: f32 = 1e-10;
        try testing.expect(f.contains(tiny_value, tiny_value));
        
        // Test boundary precision
        const just_inside_east = f.east_boundary - 0.0001;
        const just_outside_east = f.east_boundary + 0.0001;
        const just_inside_north = f.north_boundary - 0.0001;
        const just_outside_north = f.north_boundary + 0.0001;
        
        try testing.expect(f.contains(just_inside_east, 50));
        try testing.expect(!f.contains(just_outside_east, 50));
        try testing.expect(f.contains(26.67, just_inside_north));
        try testing.expect(!f.contains(26.67, just_outside_north));
        
        // Test hash mark positions remain valid under all conditions
        try testing.expect(f.contains(f.left_hash_x, 0));
        try testing.expect(f.contains(f.left_hash_x, f.north_boundary));
        try testing.expect(f.contains(f.right_hash_x, 0));
        try testing.expect(f.contains(f.right_hash_x, f.north_boundary));
        try testing.expect(f.contains(f.center_x, 0));
        try testing.expect(f.contains(f.center_x, f.north_boundary));
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ COORDINATE STRUCT TESTS ══════════════════════════════════════╗

    // ┌──────────────────────────── Unit Tests ────────────────────────────┐
    
        test "unit: Coordinate: init creates coordinate correctly" {
            const c = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.FIELD_LENGTH_YARDS / 2);
            
            try testing.expectEqual(field.FIELD_WIDTH_YARDS / 2, c.x);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS / 2, c.y);
        }
        
        test "unit: Coordinate: distanceTo calculates distance correctly" {
            const c1 = field.Coordinate.init(0, 0);
            const c2 = field.Coordinate.init(3, 4);
            
            // 3-4-5 triangle
            try testing.expectEqual(@as(f32, 5), c1.distanceTo(c2));
            
            // Test symmetry
            try testing.expectEqual(c1.distanceTo(c2), c2.distanceTo(c1));
            
            // Test distance to self
            try testing.expectEqual(@as(f32, 0), c1.distanceTo(c1));
        }
        
        test "unit: Coordinate: isValid validates standard field boundaries" {
            // Test valid coordinates at center
            const center = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.FIELD_LENGTH_YARDS / 2);
            try testing.expect(center.isValid());
            
            // Test exact corner boundaries (all valid)
            const southwest = field.Coordinate.init(0, 0);
            const southeast = field.Coordinate.init(field.FIELD_WIDTH_YARDS, 0);
            const northwest = field.Coordinate.init(0, field.FIELD_LENGTH_YARDS);
            const northeast = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            
            try testing.expect(southwest.isValid());
            try testing.expect(southeast.isValid());
            try testing.expect(northwest.isValid());
            try testing.expect(northeast.isValid());
        }
        
        test "unit: Coordinate: isValid rejects out-of-bounds coordinates" {
            // Test coordinates beyond field length
            const beyond_length = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.FIELD_LENGTH_YARDS + 0.1);
            try testing.expect(!beyond_length.isValid());
            
            // Test coordinates beyond field width
            const beyond_width = field.Coordinate.init(field.FIELD_WIDTH_YARDS + 0.1, field.FIELD_LENGTH_YARDS / 2);
            try testing.expect(!beyond_width.isValid());
            
            // Test negative X coordinate
            const negative_x = field.Coordinate.init(-0.1, field.FIELD_LENGTH_YARDS / 2);
            try testing.expect(!negative_x.isValid());
            
            // Test negative Y coordinate
            const negative_y = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, -0.1);
            try testing.expect(!negative_y.isValid());
            
            // Test both negative
            const both_negative = field.Coordinate.init(-5, -10);
            try testing.expect(!both_negative.isValid());
        }
        
        test "unit: Coordinate: isInBounds validates playing field only" {
            // Test coordinates in playing field center
            const midfield = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 60);
            try testing.expect(midfield.isInBounds());
            
            // Test at playing field boundaries (10 and 110 yards for y)
            const playing_field_start = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.END_ZONE_LENGTH_YARDS);
            const playing_field_end = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.FIELD_LENGTH_YARDS - field.END_ZONE_LENGTH_YARDS);
            
            try testing.expect(playing_field_start.isInBounds());
            try testing.expect(playing_field_end.isInBounds());
        }
        
        test "unit: Coordinate: isInBounds excludes endzone coordinates" {
            // Test home endzone (0-10 yards)
            const home_endzone_back = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 0);
            const home_endzone_middle = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 5);
            const home_endzone_front = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 9.99);
            
            try testing.expect(!home_endzone_back.isInBounds());
            try testing.expect(!home_endzone_middle.isInBounds());
            try testing.expect(!home_endzone_front.isInBounds());
            
            // Test away endzone (110-120 yards)
            const away_endzone_front = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 110.01);
            const away_endzone_middle = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 115);
            const away_endzone_back = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 120);
            
            try testing.expect(!away_endzone_front.isInBounds());
            try testing.expect(!away_endzone_middle.isInBounds());
            try testing.expect(!away_endzone_back.isInBounds());
        }
        
        test "unit: Coordinate: isInBounds requires X within sidelines" {
            // Test coordinates on exact sidelines (should be out of bounds)
            const left_sideline = field.Coordinate.init(0, 50);
            const right_sideline = field.Coordinate.init(field.FIELD_WIDTH_YARDS, 50);
            
            try testing.expect(!left_sideline.isInBounds());
            try testing.expect(!right_sideline.isInBounds());
            
            // Test just inside sidelines (should be in bounds)
            const just_inside_left = field.Coordinate.init(0.01, 50);
            const just_inside_right = field.Coordinate.init(field.FIELD_WIDTH_YARDS - 0.01, 50);
            
            try testing.expect(just_inside_left.isInBounds());
            try testing.expect(just_inside_right.isInBounds());
            
            // Test beyond sidelines
            const beyond_left = field.Coordinate.init(-1, 50);
            const beyond_right = field.Coordinate.init(field.FIELD_WIDTH_YARDS + 1, 50);
            
            try testing.expect(!beyond_left.isInBounds());
            try testing.expect(!beyond_right.isInBounds());
        }
        
        test "unit: Coordinate: isValidForField delegates to Field.contains" {
            const f = field.Field.init(std.testing.allocator);
            
            // Test coordinates that should be valid for field
            const valid_coord = field.Coordinate.init(26.67, 60);
            try testing.expect(valid_coord.isValidForField(f));
            
            // Test coordinates at field corners
            const corner = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            try testing.expect(corner.isValidForField(f));
            
            // Test coordinates outside field
            const outside = field.Coordinate.init(30, 150);
            try testing.expect(!outside.isValidForField(f));
            
            const negative = field.Coordinate.init(20, -10);
            try testing.expect(!negative.isValidForField(f));
        }
        
        test "unit: Coordinate: edge cases for isValid" {
            // Test extremely small positive values
            const tiny_positive = field.Coordinate.init(0.0001, 0.0001);
            try testing.expect(tiny_positive.isValid());
            
            // Test exact boundary values
            const exact_max = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            try testing.expect(exact_max.isValid());
            
            // Test just beyond boundaries with small but measurable increments  
            const epsilon: f32 = 0.01; // Use larger epsilon for f32 precision
            const just_over_x = field.Coordinate.init(field.FIELD_WIDTH_YARDS + epsilon, 30);
            const just_over_y = field.Coordinate.init(26.67, field.FIELD_LENGTH_YARDS + epsilon);
            
            try testing.expect(!just_over_x.isValid());
            try testing.expect(!just_over_y.isValid());
        }
        
        test "unit: Coordinate: edge cases for isInBounds" {
            // Test exact playing field boundaries
            const exact_start_y = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS);
            const exact_end_y = field.Coordinate.init(26.67, field.FIELD_LENGTH_YARDS - field.END_ZONE_LENGTH_YARDS);
            
            try testing.expect(exact_start_y.isInBounds());
            try testing.expect(exact_end_y.isInBounds());
            
            // Test just outside playing field with tiny offset
            const epsilon: f32 = 0.0001;
            const just_in_home_endzone = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS - epsilon);
            const just_in_away_endzone = field.Coordinate.init(26.67, field.FIELD_LENGTH_YARDS - field.END_ZONE_LENGTH_YARDS + epsilon);
            
            try testing.expect(!just_in_home_endzone.isInBounds());
            try testing.expect(!just_in_away_endzone.isInBounds());
            
            // Test Y boundary conditions with tiny values
            const just_off_left = field.Coordinate.init(epsilon, 50);
            const just_off_right = field.Coordinate.init(field.FIELD_WIDTH_YARDS - epsilon, 50);
            
            try testing.expect(just_off_left.isInBounds());
            try testing.expect(just_off_right.isInBounds());
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Integration Tests ────────────────────────────┐
    
        test "integration: Coordinate with Field: validation consistency" {
            const f = field.Field.init(std.testing.allocator);
            
            // Test that isValidForField matches Field.contains for various coordinates
            const test_coords = [_]field.Coordinate{
                field.Coordinate.init(0, 0),
                field.Coordinate.init(26.67, 60),
                field.Coordinate.init(53.333333, 120),
                field.Coordinate.init(25, -1),
                field.Coordinate.init(-1, 50),
                field.Coordinate.init(25, 121),
                field.Coordinate.init(54, 50),
            };
            
            for (test_coords) |coord| {
                const field_contains = f.contains(coord.x, coord.y);
                const coord_valid_for_field = coord.isValidForField(f);
                try testing.expectEqual(field_contains, coord_valid_for_field);
            }
        }
        
        test "integration: Coordinate with Field: endzone detection alignment" {
            const f = field.Field.init(std.testing.allocator);
            
            // Test coordinates in home endzone
            const home_endzone_coords = [_]field.Coordinate{
                field.Coordinate.init(26.67, 0),
                field.Coordinate.init(26.67, 5),
                field.Coordinate.init(26.67, 9.99),
            };
            
            for (home_endzone_coords) |coord| {
                try testing.expect(coord.isValid());
                try testing.expect(!coord.isInBounds());
                try testing.expect(f.isInHomeEndzone(coord.y));
                try testing.expect(!f.isInPlayingField(coord.y));
            }
            
            // Test coordinates in away endzone
            const away_endzone_coords = [_]field.Coordinate{
                field.Coordinate.init(26.67, 110.01),
                field.Coordinate.init(26.67, 115),
                field.Coordinate.init(26.67, 120),
            };
            
            for (away_endzone_coords) |coord| {
                try testing.expect(coord.isValid());
                try testing.expect(!coord.isInBounds());
                try testing.expect(f.isInAwayEndzone(coord.y));
                try testing.expect(!f.isInPlayingField(coord.y));
            }
            
            // Test coordinates in playing field
            const playing_field_coords = [_]field.Coordinate{
                field.Coordinate.init(26.67, 10),
                field.Coordinate.init(26.67, 50),
                field.Coordinate.init(26.67, 110),
            };
            
            for (playing_field_coords) |coord| {
                try testing.expect(coord.isValid());
                try testing.expect(coord.isInBounds());
                try testing.expect(f.isInPlayingField(coord.y));
                try testing.expect(!f.isInHomeEndzone(coord.y));
                try testing.expect(!f.isInAwayEndzone(coord.y));
            }
        }
        
        test "integration: Coordinate with Field: hash mark positioning" {
            const f = field.Field.init(std.testing.allocator);
            
            // Create coordinates at hash marks
            const left_hash = field.Coordinate.init(field.HASH_FROM_SIDELINE_YARDS, 50);
            const right_hash = field.Coordinate.init(field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS, 50);
            const center_field = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 50);
            
            // All hash mark positions should be valid and in bounds
            try testing.expect(left_hash.isValid());
            try testing.expect(left_hash.isInBounds());
            try testing.expect(left_hash.isValidForField(f));
            
            try testing.expect(right_hash.isValid());
            try testing.expect(right_hash.isInBounds());
            try testing.expect(right_hash.isValidForField(f));
            
            try testing.expect(center_field.isValid());
            try testing.expect(center_field.isInBounds());
            try testing.expect(center_field.isValidForField(f));
            
            // Verify hash mark separation
            const hash_distance = left_hash.distanceTo(right_hash);
            const tolerance: f32 = 0.001;
            try testing.expect(@abs(hash_distance - field.HASH_SEPARATION_YARDS) < tolerance);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Scenario Tests ────────────────────────────┐
    
        test "scenario: NFL ball placement: valid positions on field" {
            // Scenario: Ball can be placed anywhere in playing field
            const ball_positions = [_]field.Coordinate{
                // Kickoff position
                field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 35),
                // After touchback
                field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 25),
                // Red zone
                field.Coordinate.init(field.HASH_FROM_SIDELINE_YARDS, 15),
                // Midfield
                field.Coordinate.init(field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS, 60),
                // Goal line
                field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 10),
            };
            
            for (ball_positions) |pos| {
                try testing.expect(pos.isValid());
                try testing.expect(pos.isInBounds());
            }
        }
        
        test "scenario: NFL player positions: boundary validation" {
            // Scenario: Players can be anywhere on the field including endzones
            
            // Wide receiver in endzone corner
            const wr_endzone = field.Coordinate.init(1, 5);
            try testing.expect(wr_endzone.isValid());
            try testing.expect(!wr_endzone.isInBounds()); // In endzone, not playing field
            
            // Running back at line of scrimmage
            const rb_los = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 30);
            try testing.expect(rb_los.isValid());
            try testing.expect(rb_los.isInBounds());
            
            // Defensive back near sideline
            const db_sideline = field.Coordinate.init(0.5, 45);
            try testing.expect(db_sideline.isValid());
            try testing.expect(db_sideline.isInBounds());
            
            // Kicker at kickoff position
            const kicker = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 35);
            try testing.expect(kicker.isValid());
            try testing.expect(kicker.isInBounds());
        }
        
        test "scenario: NFL out of bounds: sideline and endzone detection" {
            // Scenario: Determine when player steps out of bounds
            
            // Player steps on sideline
            const on_sideline = field.Coordinate.init(0, 50);
            try testing.expect(on_sideline.isValid()); // Still on field
            try testing.expect(!on_sideline.isInBounds()); // But out of bounds
            
            // Player beyond sideline
            const beyond_sideline = field.Coordinate.init(-0.5, 50);
            try testing.expect(!beyond_sideline.isValid());
            try testing.expect(!beyond_sideline.isInBounds());
            
            // Player in back of endzone
            const endzone_back = field.Coordinate.init(26.67, 0);
            try testing.expect(endzone_back.isValid()); // Valid field position
            try testing.expect(!endzone_back.isInBounds()); // But not in playing field
            
            // Player beyond endzone
            const beyond_endzone = field.Coordinate.init(26.67, -1);
            try testing.expect(!beyond_endzone.isValid());
            try testing.expect(!beyond_endzone.isInBounds());
        }
        
        test "scenario: NFL field goal: kicker to uprights distance" {
            // Scenario: Calculate field goal distance from various positions
            
            // Standard NFL goalposts are at back of endzone (0 and 120 yard lines)
            const left_upright_home = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2 - 3, 0); // ~3 yards from center
            const right_upright_home = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2 + 3, 0);
            
            // Kicker at various positions
            const kick_positions = [_]struct {
                pos: field.Coordinate,
                yard_line: f32,
            }{
                .{ .pos = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 17), .yard_line = 17 }, // ~27 yard FG
                .{ .pos = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 25), .yard_line = 25 }, // ~35 yard FG
                .{ .pos = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 40), .yard_line = 40 }, // ~50 yard FG
            };
            
            for (kick_positions) |kick| {
                try testing.expect(kick.pos.isValid());
                try testing.expect(kick.pos.isInBounds());
                
                // Calculate distance to uprights
                const dist_to_left = kick.pos.distanceTo(left_upright_home);
                const dist_to_right = kick.pos.distanceTo(right_upright_home);
                
                // Both distances should be similar (within tolerance)
                const tolerance: f32 = 0.5;
                try testing.expect(@abs(dist_to_left - dist_to_right) < tolerance);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Performance Tests ────────────────────────────┐
    
        test "performance: Coordinate: validation functions are sub-microsecond" {
            const iterations = 10000;
            const coords = [_]field.Coordinate{
                field.Coordinate.init(0, 0),
                field.Coordinate.init(26.67, 60),
                field.Coordinate.init(53.333333, 120),
                field.Coordinate.init(25, 50),
            };
            
            // Test isValid performance
            const start_valid = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                for (coords) |coord| {
                    _ = coord.isValid();
                }
            }
            const end_valid = std.time.nanoTimestamp();
            const avg_valid_ns = @divFloor(end_valid - start_valid, iterations * coords.len);
            
            // Test isInBounds performance
            const start_bounds = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                for (coords) |coord| {
                    _ = coord.isInBounds();
                }
            }
            const end_bounds = std.time.nanoTimestamp();
            const avg_bounds_ns = @divFloor(end_bounds - start_bounds, iterations * coords.len);
            
            // Both functions should be sub-microsecond
            try testing.expect(avg_valid_ns < 1000);
            try testing.expect(avg_bounds_ns < 1000);
        }
        
        test "performance: Coordinate: distance calculation is efficient" {
            const iterations = 10000;
            const c1 = field.Coordinate.init(0, 0);
            const c2 = field.Coordinate.init(26.67, 60);
            
            const start = std.time.nanoTimestamp();
            var total_distance: f32 = 0;
            for (0..iterations) |_| {
                total_distance += c1.distanceTo(c2);
            }
            const end = std.time.nanoTimestamp();
            
            const avg_ns = @divFloor(end - start, iterations);
            
            // Distance calculation should be sub-microsecond
            try testing.expect(avg_ns < 1000);
            
            // Prevent optimization from removing the calculation
            try testing.expect(total_distance > 0);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Stress Tests ────────────────────────────┐
    
        test "stress: Coordinate: handles extreme values correctly" {
            // Test very large positive values
            const huge_positive = field.Coordinate.init(1_000_000, 1_000_000);
            try testing.expect(!huge_positive.isValid());
            try testing.expect(!huge_positive.isInBounds());
            
            // Test very large negative values
            const huge_negative = field.Coordinate.init(-1_000_000, -1_000_000);
            try testing.expect(!huge_negative.isValid());
            try testing.expect(!huge_negative.isInBounds());
            
            // Test infinity (if supported)
            const inf = std.math.inf(f32);
            const inf_coord = field.Coordinate.init(inf, inf);
            try testing.expect(!inf_coord.isValid());
            try testing.expect(!inf_coord.isInBounds());
            
            // Test negative infinity
            const neg_inf_coord = field.Coordinate.init(-inf, -inf);
            try testing.expect(!neg_inf_coord.isValid());
            try testing.expect(!neg_inf_coord.isInBounds());
        }
        
        test "stress: Coordinate: maintains precision under repeated operations" {
            var coord = field.Coordinate.init(25, 50);
            const original_x = coord.x;
            const original_y = coord.y;
            
            // Perform many small movements
            const iterations = 1000;
            const small_delta: f32 = 0.001;
            
            for (0..iterations) |_| {
                coord.x += small_delta;
                coord.y += small_delta;
            }
            
            for (0..iterations) |_| {
                coord.x -= small_delta;
                coord.y -= small_delta;
            }
            
            // Should be close to original position
            const tolerance: f32 = 0.01;
            try testing.expect(@abs(coord.x - original_x) < tolerance);
            try testing.expect(@abs(coord.y - original_y) < tolerance);
            
            // Should still be valid
            try testing.expect(coord.isValid());
            try testing.expect(coord.isInBounds());
        }
        
        test "stress: Coordinate: distance calculation with extreme coordinates" {
            // Test distance between very far points
            const far1 = field.Coordinate.init(0, 0);
            const far2 = field.Coordinate.init(1000, 1000);
            
            const distance = far1.distanceTo(far2);
            
            // Should calculate correctly even for large distances
            const expected = @sqrt(2000000.0); // sqrt(1000^2 + 1000^2)
            const tolerance: f32 = 1.0;
            try testing.expect(@abs(distance - expected) < tolerance);
            
            // Test distance with negative coordinates
            const neg1 = field.Coordinate.init(-100, -100);
            const pos1 = field.Coordinate.init(100, 100);
            
            const neg_distance = neg1.distanceTo(pos1);
            const expected_neg = @sqrt(80000.0); // sqrt(200^2 + 200^2)
            try testing.expect(@abs(neg_distance - expected_neg) < tolerance);
        }
    
    // └──────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝
// ╔══════════════════════════════════════ VALIDATION UTILITIES TESTS ══════════════════════════════════════╗

    // ┌──────────────────────────── Unit Tests ────────────────────────────┐
    
        test "unit: Coordinate: isInEndZone detects both endzones" {
            // Test coordinates in home endzone (y < 10)
            const home_back = field.Coordinate.init(26.67, 0);
            const home_middle = field.Coordinate.init(26.67, 5);
            const home_front = field.Coordinate.init(26.67, 9.99);
            
            try testing.expect(home_back.isInEndZone());
            try testing.expect(home_middle.isInEndZone());
            try testing.expect(home_front.isInEndZone());
            
            // Test coordinates in away endzone (y > 110)
            const away_front = field.Coordinate.init(26.67, 110.01);
            const away_middle = field.Coordinate.init(26.67, 115);
            const away_back = field.Coordinate.init(26.67, 120);
            
            try testing.expect(away_front.isInEndZone());
            try testing.expect(away_middle.isInEndZone());
            try testing.expect(away_back.isInEndZone());
            
            // Test coordinates NOT in endzones (playing field)
            const playing_start = field.Coordinate.init(26.67, 10);
            const midfield = field.Coordinate.init(26.67, 60);
            const playing_end = field.Coordinate.init(26.67, 110);
            
            try testing.expect(!playing_start.isInEndZone());
            try testing.expect(!midfield.isInEndZone());
            try testing.expect(!playing_end.isInEndZone());
        }
        
        test "unit: Coordinate: isInEndZone returns false for invalid coordinates" {
            // Test invalid coordinates return false
            const negative_x = field.Coordinate.init(-1, 5);
            const negative_y = field.Coordinate.init(26.67, -5);
            const beyond_width = field.Coordinate.init(60, 5);
            const beyond_length = field.Coordinate.init(26.67, 130);
            
            try testing.expect(!negative_x.isInEndZone());
            try testing.expect(!negative_y.isInEndZone());
            try testing.expect(!beyond_width.isInEndZone());
            try testing.expect(!beyond_length.isInEndZone());
        }
        
        test "unit: Coordinate: isInSouthEndZone detects home endzone" {
            // Test coordinates in south/home endzone (y < 10)
            const back_line = field.Coordinate.init(26.67, 0);
            const one_yard = field.Coordinate.init(26.67, 1);
            const five_yard = field.Coordinate.init(26.67, 5);
            const nine_yard = field.Coordinate.init(26.67, 9);
            const just_before_goal = field.Coordinate.init(26.67, 9.99);
            
            try testing.expect(back_line.isInSouthEndZone());
            try testing.expect(one_yard.isInSouthEndZone());
            try testing.expect(five_yard.isInSouthEndZone());
            try testing.expect(nine_yard.isInSouthEndZone());
            try testing.expect(just_before_goal.isInSouthEndZone());
            
            // Test coordinates NOT in south endzone
            const goal_line = field.Coordinate.init(26.67, 10);
            const midfield = field.Coordinate.init(26.67, 60);
            const away_endzone = field.Coordinate.init(26.67, 115);
            
            try testing.expect(!goal_line.isInSouthEndZone());
            try testing.expect(!midfield.isInSouthEndZone());
            try testing.expect(!away_endzone.isInSouthEndZone());
        }
        
        test "unit: Coordinate: isInSouthEndZone validates coordinate first" {
            // Invalid coordinates should return false
            const invalid_x = field.Coordinate.init(-1, 5);
            const invalid_y = field.Coordinate.init(26.67, -1);
            const beyond_field = field.Coordinate.init(100, 5);
            
            try testing.expect(!invalid_x.isInSouthEndZone());
            try testing.expect(!invalid_y.isInSouthEndZone());
            try testing.expect(!beyond_field.isInSouthEndZone());
        }
        
        test "unit: Coordinate: isInNorthEndZone detects away endzone" {
            // Test coordinates in north/away endzone (y > 110)
            const just_past_goal = field.Coordinate.init(26.67, 110.01);
            const one_yard_in = field.Coordinate.init(26.67, 111);
            const five_yard_line = field.Coordinate.init(26.67, 115);
            const nine_yard_line = field.Coordinate.init(26.67, 119);
            const back_line = field.Coordinate.init(26.67, 120);
            
            try testing.expect(just_past_goal.isInNorthEndZone());
            try testing.expect(one_yard_in.isInNorthEndZone());
            try testing.expect(five_yard_line.isInNorthEndZone());
            try testing.expect(nine_yard_line.isInNorthEndZone());
            try testing.expect(back_line.isInNorthEndZone());
            
            // Test coordinates NOT in north endzone
            const goal_line = field.Coordinate.init(26.67, 110);
            const midfield = field.Coordinate.init(26.67, 60);
            const home_endzone = field.Coordinate.init(26.67, 5);
            
            try testing.expect(!goal_line.isInNorthEndZone());
            try testing.expect(!midfield.isInNorthEndZone());
            try testing.expect(!home_endzone.isInNorthEndZone());
        }
        
        test "unit: Coordinate: isInNorthEndZone validates coordinate first" {
            // Invalid coordinates should return false
            const invalid_x = field.Coordinate.init(60, 115);
            const invalid_y = field.Coordinate.init(26.67, 130);
            const negative = field.Coordinate.init(-1, 115);
            
            try testing.expect(!invalid_x.isInNorthEndZone());
            try testing.expect(!invalid_y.isInNorthEndZone());
            try testing.expect(!negative.isInNorthEndZone());
        }
        
        test "unit: Coordinate: isOnSideline detects sideline positions" {
            // Test left/west sideline (x ≈ 0)
            const left_exact = field.Coordinate.init(0, 50);
            const left_within_epsilon = field.Coordinate.init(0.005, 50);
            const left_at_epsilon = field.Coordinate.init(0.009, 50);
            
            try testing.expect(left_exact.isOnSideline());
            try testing.expect(left_within_epsilon.isOnSideline());
            try testing.expect(left_at_epsilon.isOnSideline());
            
            // Test right/east sideline (x ≈ 53.333333)
            const right_exact = field.Coordinate.init(field.FIELD_WIDTH_YARDS, 50);
            const right_within_epsilon = field.Coordinate.init(field.FIELD_WIDTH_YARDS - 0.005, 50);
            const right_at_epsilon = field.Coordinate.init(field.FIELD_WIDTH_YARDS - 0.009, 50);
            
            try testing.expect(right_exact.isOnSideline());
            try testing.expect(right_within_epsilon.isOnSideline());
            try testing.expect(right_at_epsilon.isOnSideline());
            
            // Test coordinates NOT on sidelines
            const just_off_left = field.Coordinate.init(0.011, 50);
            const center = field.Coordinate.init(26.67, 50);
            const just_off_right = field.Coordinate.init(field.FIELD_WIDTH_YARDS - 0.011, 50);
            
            try testing.expect(!just_off_left.isOnSideline());
            try testing.expect(!center.isOnSideline());
            try testing.expect(!just_off_right.isOnSideline());
        }
        
        test "unit: Coordinate: isOnSideline validates coordinate first" {
            // Invalid coordinates should return false
            const negative_x = field.Coordinate.init(-0.005, 50);
            const beyond_width = field.Coordinate.init(field.FIELD_WIDTH_YARDS + 0.005, 50);
            const invalid_y = field.Coordinate.init(0, -10);
            
            try testing.expect(!negative_x.isOnSideline());
            try testing.expect(!beyond_width.isOnSideline());
            try testing.expect(!invalid_y.isOnSideline());
        }
        
        test "unit: Coordinate: isOnGoalLine detects goal line positions" {
            // Test south/home goal line (y ≈ 10)
            const south_exact = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS);
            const south_within_epsilon = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS + 0.005);
            const south_at_epsilon = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS - 0.009);
            
            try testing.expect(south_exact.isOnGoalLine());
            try testing.expect(south_within_epsilon.isOnGoalLine());
            try testing.expect(south_at_epsilon.isOnGoalLine());
            
            // Test north/away goal line (y ≈ 110)
            const north_y = field.FIELD_LENGTH_YARDS - field.END_ZONE_LENGTH_YARDS;
            const north_exact = field.Coordinate.init(26.67, north_y);
            const north_within_epsilon = field.Coordinate.init(26.67, north_y + 0.005);
            const north_at_epsilon = field.Coordinate.init(26.67, north_y - 0.009);
            
            try testing.expect(north_exact.isOnGoalLine());
            try testing.expect(north_within_epsilon.isOnGoalLine());
            try testing.expect(north_at_epsilon.isOnGoalLine());
            
            // Test coordinates NOT on goal lines
            const endzone = field.Coordinate.init(26.67, 5);
            const midfield = field.Coordinate.init(26.67, 60);
            const just_off_south = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS + 0.011);
            const just_off_north = field.Coordinate.init(26.67, north_y - 0.011);
            
            try testing.expect(!endzone.isOnGoalLine());
            try testing.expect(!midfield.isOnGoalLine());
            try testing.expect(!just_off_south.isOnGoalLine());
            try testing.expect(!just_off_north.isOnGoalLine());
        }
        
        test "unit: Coordinate: isOnGoalLine validates coordinate first" {
            // Invalid coordinates should return false
            const invalid_x = field.Coordinate.init(-1, 10);
            const invalid_y = field.Coordinate.init(26.67, -10);
            const beyond_field = field.Coordinate.init(100, 110);
            
            try testing.expect(!invalid_x.isOnGoalLine());
            try testing.expect(!invalid_y.isOnGoalLine());
            try testing.expect(!beyond_field.isOnGoalLine());
        }
        
        test "unit: Coordinate: clamp restricts to field boundaries" {
            // Test clamping negative X values
            const negative_x = field.Coordinate.init(-10, 50);
            const clamped_neg_x = negative_x.clamp();
            try testing.expectEqual(@as(f32, 0), clamped_neg_x.x);
            try testing.expectEqual(@as(f32, 50), clamped_neg_x.y);
            
            // Test clamping X beyond width
            const beyond_width = field.Coordinate.init(100, 50);
            const clamped_width = beyond_width.clamp();
            try testing.expectEqual(field.FIELD_WIDTH_YARDS, clamped_width.x);
            try testing.expectEqual(@as(f32, 50), clamped_width.y);
            
            // Test clamping negative Y values
            const negative_y = field.Coordinate.init(26.67, -20);
            const clamped_neg_y = negative_y.clamp();
            try testing.expectEqual(@as(f32, 26.67), clamped_neg_y.x);
            try testing.expectEqual(@as(f32, 0), clamped_neg_y.y);
            
            // Test clamping Y beyond length
            const beyond_length = field.Coordinate.init(26.67, 150);
            const clamped_length = beyond_length.clamp();
            try testing.expectEqual(@as(f32, 26.67), clamped_length.x);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, clamped_length.y);
            
            // Test clamping both coordinates
            const both_invalid = field.Coordinate.init(-5, 200);
            const clamped_both = both_invalid.clamp();
            try testing.expectEqual(@as(f32, 0), clamped_both.x);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, clamped_both.y);
        }
        
        test "unit: Coordinate: clamp preserves valid coordinates" {
            // Test that valid coordinates remain unchanged
            const valid_center = field.Coordinate.init(26.67, 60);
            const clamped_center = valid_center.clamp();
            try testing.expectEqual(valid_center.x, clamped_center.x);
            try testing.expectEqual(valid_center.y, clamped_center.y);
            
            // Test corner coordinates
            const corner = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            const clamped_corner = corner.clamp();
            try testing.expectEqual(corner.x, clamped_corner.x);
            try testing.expectEqual(corner.y, clamped_corner.y);
            
            // Test origin
            const origin = field.Coordinate.init(0, 0);
            const clamped_origin = origin.clamp();
            try testing.expectEqual(origin.x, clamped_origin.x);
            try testing.expectEqual(origin.y, clamped_origin.y);
        }
        
        test "unit: validateCoordinate: returns OutOfBoundsX for invalid X" {
            // Test negative X
            const negative_x = field.Coordinate.init(-1, 50);
            const err_neg = field.validateCoordinate(negative_x);
            try testing.expectError(field.CoordinateError.OutOfBoundsX, err_neg);
            
            // Test X beyond field width
            const beyond_width = field.Coordinate.init(field.FIELD_WIDTH_YARDS + 0.01, 50);
            const err_beyond = field.validateCoordinate(beyond_width);
            try testing.expectError(field.CoordinateError.OutOfBoundsX, err_beyond);
            
            // Test large X value
            const large_x = field.Coordinate.init(1000, 50);
            const err_large = field.validateCoordinate(large_x);
            try testing.expectError(field.CoordinateError.OutOfBoundsX, err_large);
        }
        
        test "unit: validateCoordinate: returns OutOfBoundsY for invalid Y" {
            // Test negative Y
            const negative_y = field.Coordinate.init(26.67, -1);
            const err_neg = field.validateCoordinate(negative_y);
            try testing.expectError(field.CoordinateError.OutOfBoundsY, err_neg);
            
            // Test Y beyond field length
            const beyond_length = field.Coordinate.init(26.67, field.FIELD_LENGTH_YARDS + 0.01);
            const err_beyond = field.validateCoordinate(beyond_length);
            try testing.expectError(field.CoordinateError.OutOfBoundsY, err_beyond);
            
            // Test large Y value
            const large_y = field.Coordinate.init(26.67, 1000);
            const err_large = field.validateCoordinate(large_y);
            try testing.expectError(field.CoordinateError.OutOfBoundsY, err_large);
        }
        
        test "unit: validateCoordinate: validates valid coordinates successfully" {
            // Test valid coordinates
            const valid_coords = [_]field.Coordinate{
                field.Coordinate.init(0, 0),
                field.Coordinate.init(26.67, 60),
                field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS),
                field.Coordinate.init(field.HASH_FROM_SIDELINE_YARDS, 50),
                field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.FIELD_LENGTH_YARDS / 2),
            };
            
            for (valid_coords) |coord| {
                try field.validateCoordinate(coord);
            }
        }
        
        test "unit: validateCoordinate: prioritizes X error over Y error" {
            // When both X and Y are invalid, X error should be returned first
            const both_invalid = field.Coordinate.init(-10, -20);
            const err = field.validateCoordinate(both_invalid);
            try testing.expectError(field.CoordinateError.OutOfBoundsX, err);
            
            // Another case with both invalid
            const both_beyond = field.Coordinate.init(100, 200);
            const err_beyond = field.validateCoordinate(both_beyond);
            try testing.expectError(field.CoordinateError.OutOfBoundsX, err_beyond);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Integration Tests ────────────────────────────┐
    
        test "integration: Coordinate validation: combined zone checks" {
            // Test that endzone functions work together correctly
            const home_endzone = field.Coordinate.init(26.67, 5);
            
            try testing.expect(home_endzone.isInEndZone());
            try testing.expect(home_endzone.isInSouthEndZone());
            try testing.expect(!home_endzone.isInNorthEndZone());
            try testing.expect(!home_endzone.isOnGoalLine());
            
            const away_endzone = field.Coordinate.init(26.67, 115);
            
            try testing.expect(away_endzone.isInEndZone());
            try testing.expect(!away_endzone.isInSouthEndZone());
            try testing.expect(away_endzone.isInNorthEndZone());
            try testing.expect(!away_endzone.isOnGoalLine());
            
            const playing_field = field.Coordinate.init(26.67, 60);
            
            try testing.expect(!playing_field.isInEndZone());
            try testing.expect(!playing_field.isInSouthEndZone());
            try testing.expect(!playing_field.isInNorthEndZone());
            try testing.expect(!playing_field.isOnGoalLine());
        }
        
        test "integration: Coordinate validation: boundary line detection" {
            // Test coordinates on multiple boundaries
            const corner_sw = field.Coordinate.init(0, 0);
            
            try testing.expect(corner_sw.isValid());
            try testing.expect(corner_sw.isOnSideline());
            try testing.expect(!corner_sw.isOnGoalLine());
            try testing.expect(corner_sw.isInSouthEndZone());
            
            const goal_sideline = field.Coordinate.init(0, 10);
            
            try testing.expect(goal_sideline.isValid());
            try testing.expect(goal_sideline.isOnSideline());
            try testing.expect(goal_sideline.isOnGoalLine());
            try testing.expect(!goal_sideline.isInEndZone());
            
            const corner_ne = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            
            try testing.expect(corner_ne.isValid());
            try testing.expect(corner_ne.isOnSideline());
            try testing.expect(!corner_ne.isOnGoalLine());
            try testing.expect(corner_ne.isInNorthEndZone());
        }
        
        test "integration: Coordinate validation: clamp with validation" {
            // Test clamping invalid coordinates and then validating
            const invalid = field.Coordinate.init(-10, 150);
            
            // Original should fail validation
            const err = field.validateCoordinate(invalid);
            try testing.expectError(field.CoordinateError.OutOfBoundsX, err);
            
            // Clamped should pass validation
            const clamped = invalid.clamp();
            try field.validateCoordinate(clamped);
            try testing.expect(clamped.isValid());
            
            // Test multiple invalid coordinates
            const test_coords = [_]field.Coordinate{
                field.Coordinate.init(-5, -10),
                field.Coordinate.init(100, 200),
                field.Coordinate.init(-100, 60),
                field.Coordinate.init(26.67, -50),
            };
            
            for (test_coords) |coord| {
                const clamped_coord = coord.clamp();
                try field.validateCoordinate(clamped_coord);
                try testing.expect(clamped_coord.isValid());
            }
        }
        
        test "integration: Coordinate validation: epsilon tolerance consistency" {
            // Verify epsilon tolerance is consistent across functions
            const epsilon = 0.01;
            
            // Test sideline epsilon
            const near_left = field.Coordinate.init(epsilon - 0.001, 50);
            const past_left = field.Coordinate.init(epsilon + 0.001, 50);
            
            try testing.expect(near_left.isOnSideline());
            try testing.expect(!past_left.isOnSideline());
            
            // Test goal line epsilon
            const near_south_goal = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS + epsilon - 0.001);
            const past_south_goal = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS + epsilon + 0.001);
            
            try testing.expect(near_south_goal.isOnGoalLine());
            try testing.expect(!past_south_goal.isOnGoalLine());
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Performance Tests ────────────────────────────┐
    
        test "performance: Coordinate validation: sub-microsecond execution" {
            const iterations = 10000;
            const test_coord = field.Coordinate.init(26.67, 60);
            
            // Test isInEndZone performance
            const start_endzone = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                _ = test_coord.isInEndZone();
            }
            const end_endzone = std.time.nanoTimestamp();
            const avg_endzone_ns = @divFloor(end_endzone - start_endzone, iterations);
            
            // Test isOnSideline performance
            const start_sideline = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                _ = test_coord.isOnSideline();
            }
            const end_sideline = std.time.nanoTimestamp();
            const avg_sideline_ns = @divFloor(end_sideline - start_sideline, iterations);
            
            // Test isOnGoalLine performance
            const start_goalline = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                _ = test_coord.isOnGoalLine();
            }
            const end_goalline = std.time.nanoTimestamp();
            const avg_goalline_ns = @divFloor(end_goalline - start_goalline, iterations);
            
            // Test clamp performance
            const start_clamp = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                _ = test_coord.clamp();
            }
            const end_clamp = std.time.nanoTimestamp();
            const avg_clamp_ns = @divFloor(end_clamp - start_clamp, iterations);
            
            // All validation functions should be sub-microsecond
            try testing.expect(avg_endzone_ns < 1000);
            try testing.expect(avg_sideline_ns < 1000);
            try testing.expect(avg_goalline_ns < 1000);
            try testing.expect(avg_clamp_ns < 1000);
        }
        
        test "performance: validateCoordinate: efficient error checking" {
            const iterations = 10000;
            
            // Test with valid coordinate
            const valid = field.Coordinate.init(26.67, 60);
            const start_valid = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                _ = field.validateCoordinate(valid) catch {};
            }
            const end_valid = std.time.nanoTimestamp();
            const avg_valid_ns = @divFloor(end_valid - start_valid, iterations);
            
            // Test with invalid X
            const invalid_x = field.Coordinate.init(-10, 60);
            const start_invalid_x = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                _ = field.validateCoordinate(invalid_x) catch {};
            }
            const end_invalid_x = std.time.nanoTimestamp();
            const avg_invalid_x_ns = @divFloor(end_invalid_x - start_invalid_x, iterations);
            
            // Test with invalid Y
            const invalid_y = field.Coordinate.init(26.67, 200);
            const start_invalid_y = std.time.nanoTimestamp();
            for (0..iterations) |_| {
                _ = field.validateCoordinate(invalid_y) catch {};
            }
            const end_invalid_y = std.time.nanoTimestamp();
            const avg_invalid_y_ns = @divFloor(end_invalid_y - start_invalid_y, iterations);
            
            // All validation paths should be sub-microsecond
            try testing.expect(avg_valid_ns < 1000);
            try testing.expect(avg_invalid_x_ns < 1000);
            try testing.expect(avg_invalid_y_ns < 1000);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Stress Tests ────────────────────────────┐
    
        test "stress: Coordinate validation: extreme values" {
            // Test with extreme positive values
            const huge = field.Coordinate.init(1_000_000, 1_000_000);
            try testing.expect(!huge.isInEndZone());
            try testing.expect(!huge.isInSouthEndZone());
            try testing.expect(!huge.isInNorthEndZone());
            try testing.expect(!huge.isOnSideline());
            try testing.expect(!huge.isOnGoalLine());
            
            // Clamp should handle extreme values
            const clamped_huge = huge.clamp();
            try testing.expectEqual(field.FIELD_WIDTH_YARDS, clamped_huge.x);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, clamped_huge.y);
            
            // Test with extreme negative values
            const huge_neg = field.Coordinate.init(-1_000_000, -1_000_000);
            try testing.expect(!huge_neg.isInEndZone());
            try testing.expect(!huge_neg.isOnSideline());
            try testing.expect(!huge_neg.isOnGoalLine());
            
            const clamped_neg = huge_neg.clamp();
            try testing.expectEqual(@as(f32, 0), clamped_neg.x);
            try testing.expectEqual(@as(f32, 0), clamped_neg.y);
            
            // Test with infinity
            const inf = std.math.inf(f32);
            const inf_coord = field.Coordinate.init(inf, inf);
            try testing.expect(!inf_coord.isInEndZone());
            try testing.expect(!inf_coord.isOnSideline());
            
            // Test with NaN (should handle gracefully)
            const nan = std.math.nan(f32);
            const nan_coord = field.Coordinate.init(nan, nan);
            try testing.expect(!nan_coord.isInEndZone());
            try testing.expect(!nan_coord.isOnSideline());
        }
        
        test "stress: Coordinate validation: precision limits" {
            // Test epsilon boundary precision
            const epsilon = 0.01;
            
            // Test values just at the edge of epsilon
            const almost_epsilon = field.Coordinate.init(epsilon - 0.0001, 50);
            const past_epsilon = field.Coordinate.init(epsilon + 0.0001, 50);
            
            try testing.expect(almost_epsilon.isOnSideline());
            try testing.expect(!past_epsilon.isOnSideline());
            
            // Test repeated clamping maintains precision
            var coord = field.Coordinate.init(-10, 150);
            for (0..100) |_| {
                coord = coord.clamp();
            }
            try testing.expectEqual(@as(f32, 0), coord.x);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, coord.y);
            
            // Test validation with tiny increments
            const tiny_over = field.Coordinate.init(field.FIELD_WIDTH_YARDS + 0.001, 60);
            const err = field.validateCoordinate(tiny_over);
            try testing.expectError(field.CoordinateError.OutOfBoundsX, err);
        }
        
        test "stress: Coordinate validation: rapid state changes" {
            // Simulate rapid movement across boundaries
            var coord = field.Coordinate.init(0, 0);
            var endzone_count: u32 = 0;
            var sideline_count: u32 = 0;
            var goalline_count: u32 = 0;
            
            // Move coordinate rapidly across field
            const step = 0.5;
            var y: f32 = 0;
            while (y <= field.FIELD_LENGTH_YARDS) : (y += step) {
                var x: f32 = 0;
                while (x <= field.FIELD_WIDTH_YARDS) : (x += step) {
                    coord = field.Coordinate.init(x, y);
                    
                    if (coord.isInEndZone()) endzone_count += 1;
                    if (coord.isOnSideline()) sideline_count += 1;
                    if (coord.isOnGoalLine()) goalline_count += 1;
                    
                    // Validate and clamp
                    _ = field.validateCoordinate(coord) catch {
                        coord = coord.clamp();
                    };
                }
            }
            
            // Should have detected boundaries multiple times
            try testing.expect(endzone_count > 0);
            try testing.expect(sideline_count > 0);
            try testing.expect(goalline_count > 0);
        }
    
    // └──────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ CONVERSION UTILITIES TESTS ══════════════════════════════════════╗

    // ┌──────────────────────────── Unit Tests ────────────────────────────┐
    
        test "unit: Coordinate: toFeet conversion accuracy" {
            // Test basic conversion from yards to feet
            const coord_yards = field.Coordinate.init(10, 20);
            const coord_feet = coord_yards.toFeet();
            
            try testing.expectEqual(@as(f32, 30), coord_feet.x); // 10 * 3 = 30
            try testing.expectEqual(@as(f32, 60), coord_feet.y); // 20 * 3 = 60
            
            // Test field dimensions conversion
            const field_corner = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            const corner_feet = field_corner.toFeet();
            
            try testing.expectEqual(@as(f32, 160), corner_feet.x); // 53.333333 * 3 ≈ 160
            try testing.expectEqual(@as(f32, 360), corner_feet.y); // 120 * 3 = 360
            
            // Test zero values
            const origin = field.Coordinate.init(0, 0);
            const origin_feet = origin.toFeet();
            
            try testing.expectEqual(@as(f32, 0), origin_feet.x);
            try testing.expectEqual(@as(f32, 0), origin_feet.y);
            
            // Test fractional yards
            const fractional = field.Coordinate.init(1.5, 2.5);
            const fractional_feet = fractional.toFeet();
            
            try testing.expectEqual(@as(f32, 4.5), fractional_feet.x); // 1.5 * 3 = 4.5
            try testing.expectEqual(@as(f32, 7.5), fractional_feet.y); // 2.5 * 3 = 7.5
        }
        
        test "unit: Coordinate: fromFeet creates valid coordinates" {
            // Test basic conversion from feet to yards
            const coord = field.Coordinate.fromFeet(30, 60);
            
            // Allow small tolerance for floating point operations
            const tolerance: f32 = 0.01;
            try testing.expect(@abs(coord.x - 10) < tolerance); // 30 * 0.333333 ≈ 10
            try testing.expect(@abs(coord.y - 20) < tolerance); // 60 * 0.333333 ≈ 20
            
            // Test field width conversion (160 feet = 53.333333 yards)
            const field_width = field.Coordinate.fromFeet(160, 360);
            try testing.expect(@abs(field_width.x - field.FIELD_WIDTH_YARDS) < tolerance);
            try testing.expect(@abs(field_width.y - field.FIELD_LENGTH_YARDS) < tolerance);
            
            // Test zero values
            const origin = field.Coordinate.fromFeet(0, 0);
            try testing.expectEqual(@as(f32, 0), origin.x);
            try testing.expectEqual(@as(f32, 0), origin.y);
            
            // Test fractional feet
            const fractional = field.Coordinate.fromFeet(4.5, 7.5);
            try testing.expect(@abs(fractional.x - 1.5) < tolerance); // 4.5 * 0.333333 ≈ 1.5
            try testing.expect(@abs(fractional.y - 2.5) < tolerance); // 7.5 * 0.333333 ≈ 2.5
            
            // Test that fromFeet creates valid field coordinates
            const valid_coord = field.Coordinate.fromFeet(80, 180); // Center of field
            try testing.expect(valid_coord.isValid());
        }
        
        test "unit: Coordinate: nearestYardLine calculation" {
            // Test exact yard line positions
            const on_20_yard = field.Coordinate.init(26.67, 30); // 20 yards from home goal
            try testing.expectEqual(@as(?u8, 20), on_20_yard.nearestYardLine());
            
            const on_50_yard = field.Coordinate.init(26.67, 60); // Midfield
            try testing.expectEqual(@as(?u8, 50), on_50_yard.nearestYardLine());
            
            const on_goal_line_home = field.Coordinate.init(26.67, 10); // Home goal line
            try testing.expectEqual(@as(?u8, 0), on_goal_line_home.nearestYardLine());
            
            const on_goal_line_away = field.Coordinate.init(26.67, 110); // Away goal line (100 yards from home)
            try testing.expectEqual(@as(?u8, 100), on_goal_line_away.nearestYardLine());
            
            // Test rounding to nearest yard
            const near_25_low = field.Coordinate.init(26.67, 34.4); // Should round down to 24
            try testing.expectEqual(@as(?u8, 24), near_25_low.nearestYardLine());
            
            const near_25_high = field.Coordinate.init(26.67, 35.6); // Should round up to 26
            try testing.expectEqual(@as(?u8, 26), near_25_high.nearestYardLine());
            
            const exactly_25_5 = field.Coordinate.init(26.67, 35.5); // Exactly 25.5, should round to 26
            try testing.expectEqual(@as(?u8, 26), exactly_25_5.nearestYardLine());
            
            // Test endzone positions (should return null)
            const in_home_endzone = field.Coordinate.init(26.67, 5);
            try testing.expectEqual(@as(?u8, null), in_home_endzone.nearestYardLine());
            
            const in_away_endzone = field.Coordinate.init(26.67, 115);
            try testing.expectEqual(@as(?u8, null), in_away_endzone.nearestYardLine());
            
            const on_endzone_back = field.Coordinate.init(26.67, 0);
            try testing.expectEqual(@as(?u8, null), on_endzone_back.nearestYardLine());
            
            const on_far_endzone_back = field.Coordinate.init(26.67, 120);
            try testing.expectEqual(@as(?u8, null), on_far_endzone_back.nearestYardLine());
        }
        
        test "unit: Coordinate: mirrorX operation" {
            // Test mirroring across vertical center line (x = 26.67)
            const left_side = field.Coordinate.init(10, 50);
            const mirrored_left = left_side.mirrorX();
            
            const tolerance: f32 = 0.01;
            const expected_x = field.FIELD_WIDTH_YARDS - 10; // 53.333333 - 10 = 43.333333
            try testing.expect(@abs(mirrored_left.x - expected_x) < tolerance);
            try testing.expectEqual(@as(f32, 50), mirrored_left.y); // Y unchanged
            
            // Test center point (should stay at center)
            const center = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, 60);
            const mirrored_center = center.mirrorX();
            try testing.expect(@abs(mirrored_center.x - field.FIELD_WIDTH_YARDS / 2) < tolerance);
            try testing.expectEqual(@as(f32, 60), mirrored_center.y);
            
            // Test left sideline to right sideline
            const left_sideline = field.Coordinate.init(0, 30);
            const mirrored_sideline = left_sideline.mirrorX();
            try testing.expect(@abs(mirrored_sideline.x - field.FIELD_WIDTH_YARDS) < tolerance);
            try testing.expectEqual(@as(f32, 30), mirrored_sideline.y);
            
            // Test double mirror (should return to original)
            const original = field.Coordinate.init(15, 40);
            const double_mirrored = original.mirrorX().mirrorX();
            try testing.expect(@abs(double_mirrored.x - original.x) < tolerance);
            try testing.expect(@abs(double_mirrored.y - original.y) < tolerance);
            
            // Test hash mark positions
            const left_hash = field.Coordinate.init(field.HASH_FROM_SIDELINE_YARDS, 50);
            const mirrored_hash = left_hash.mirrorX();
            const expected_hash_x = field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS;
            try testing.expect(@abs(mirrored_hash.x - expected_hash_x) < tolerance);
        }
        
        test "unit: Coordinate: mirrorY operation" {
            // Test mirroring across horizontal center line (y = 60)
            const home_side = field.Coordinate.init(26.67, 20);
            const mirrored_home = home_side.mirrorY();
            
            const tolerance: f32 = 0.01;
            try testing.expectEqual(@as(f32, 26.67), mirrored_home.x); // X unchanged
            try testing.expect(@abs(mirrored_home.y - 100) < tolerance); // 120 - 20 = 100
            
            // Test midfield (should stay at midfield)
            const midfield = field.Coordinate.init(26.67, field.FIELD_LENGTH_YARDS / 2);
            const mirrored_midfield = midfield.mirrorY();
            try testing.expectEqual(@as(f32, 26.67), mirrored_midfield.x);
            try testing.expect(@abs(mirrored_midfield.y - field.FIELD_LENGTH_YARDS / 2) < tolerance);
            
            // Test goal line to goal line
            const home_goal = field.Coordinate.init(26.67, 10);
            const mirrored_goal = home_goal.mirrorY();
            try testing.expectEqual(@as(f32, 26.67), mirrored_goal.x);
            try testing.expect(@abs(mirrored_goal.y - 110) < tolerance); // 120 - 10 = 110
            
            // Test double mirror (should return to original)
            const original = field.Coordinate.init(20, 35);
            const double_mirrored = original.mirrorY().mirrorY();
            try testing.expect(@abs(double_mirrored.x - original.x) < tolerance);
            try testing.expect(@abs(double_mirrored.y - original.y) < tolerance);
            
            // Test endzone to endzone
            const home_endzone = field.Coordinate.init(26.67, 5);
            const mirrored_endzone = home_endzone.mirrorY();
            try testing.expect(@abs(mirrored_endzone.y - 115) < tolerance); // 120 - 5 = 115
        }
        
        test "unit: Coordinate: rotate180 operation" {
            // Test 180° rotation around field center
            const corner_sw = field.Coordinate.init(0, 0);
            const rotated_sw = corner_sw.rotate180();
            
            const tolerance: f32 = 0.01;
            try testing.expect(@abs(rotated_sw.x - field.FIELD_WIDTH_YARDS) < tolerance);
            try testing.expect(@abs(rotated_sw.y - field.FIELD_LENGTH_YARDS) < tolerance);
            
            // Test center point (should stay at center)
            const center = field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.FIELD_LENGTH_YARDS / 2);
            const rotated_center = center.rotate180();
            try testing.expect(@abs(rotated_center.x - center.x) < tolerance);
            try testing.expect(@abs(rotated_center.y - center.y) < tolerance);
            
            // Test that rotate180 equals mirrorX + mirrorY
            const test_coord = field.Coordinate.init(15, 30);
            const rotated = test_coord.rotate180();
            const mirrored_both = test_coord.mirrorX().mirrorY();
            try testing.expect(@abs(rotated.x - mirrored_both.x) < tolerance);
            try testing.expect(@abs(rotated.y - mirrored_both.y) < tolerance);
            
            // Test double rotation (should return to original)
            const original = field.Coordinate.init(20, 40);
            const double_rotated = original.rotate180().rotate180();
            try testing.expect(@abs(double_rotated.x - original.x) < tolerance);
            try testing.expect(@abs(double_rotated.y - original.y) < tolerance);
            
            // Test diagonal opposite corners
            const corner_ne = field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS);
            const rotated_ne = corner_ne.rotate180();
            try testing.expect(@abs(rotated_ne.x - 0) < tolerance);
            try testing.expect(@abs(rotated_ne.y - 0) < tolerance);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Integration Tests ────────────────────────────┐
    
        test "integration: Conversions: field position string generation" {
            const allocator = testing.allocator;
            
            // Test endzone positions
            const home_endzone = field.Coordinate.init(26.67, 5);
            const home_str = try field.coordinateToFieldPosition(home_endzone, allocator);
            defer allocator.free(home_str);
            try testing.expectEqualStrings("South End Zone", home_str);
            
            const away_endzone = field.Coordinate.init(26.67, 115);
            const away_str = try field.coordinateToFieldPosition(away_endzone, allocator);
            defer allocator.free(away_str);
            try testing.expectEqualStrings("North End Zone", away_str);
            
            // Test midfield
            const midfield = field.Coordinate.init(26.67, 60);
            const midfield_str = try field.coordinateToFieldPosition(midfield, allocator);
            defer allocator.free(midfield_str);
            try testing.expectEqualStrings("Midfield", midfield_str);
            
            // Test own territory
            const own_30 = field.Coordinate.init(26.67, 40); // 30 yards from home goal
            const own_30_str = try field.coordinateToFieldPosition(own_30, allocator);
            defer allocator.free(own_30_str);
            try testing.expectEqualStrings("Own 30", own_30_str);
            
            const own_10 = field.Coordinate.init(26.67, 20); // 10 yards from home goal
            const own_10_str = try field.coordinateToFieldPosition(own_10, allocator);
            defer allocator.free(own_10_str);
            try testing.expectEqualStrings("Own 10", own_10_str);
            
            // Test opponent territory
            const opp_45 = field.Coordinate.init(26.67, 65); // 55 yards from home = Opp 45
            const opp_45_str = try field.coordinateToFieldPosition(opp_45, allocator);
            defer allocator.free(opp_45_str);
            try testing.expectEqualStrings("Opp 45", opp_45_str);
            
            const opp_20 = field.Coordinate.init(26.67, 90); // 80 yards from home = Opp 20
            const opp_20_str = try field.coordinateToFieldPosition(opp_20, allocator);
            defer allocator.free(opp_20_str);
            try testing.expectEqualStrings("Opp 20", opp_20_str);
            
            // Test goal lines
            const home_goal = field.Coordinate.init(26.67, 10);
            const home_goal_str = try field.coordinateToFieldPosition(home_goal, allocator);
            defer allocator.free(home_goal_str);
            try testing.expectEqualStrings("Own Goal", home_goal_str);
            
            const away_goal = field.Coordinate.init(26.67, 110);
            const away_goal_str = try field.coordinateToFieldPosition(away_goal, allocator);
            defer allocator.free(away_goal_str);
            try testing.expectEqualStrings("Opp Goal", away_goal_str);
        }
        
        test "integration: Conversions: field position to coordinate" {
            // Test basic yard line conversions
            const yard_20 = field.fieldPositionToCoordinate(20, 26.67);
            try testing.expectEqual(@as(f32, 26.67), yard_20.x);
            try testing.expectEqual(@as(f32, 30), yard_20.y); // 20 + 10 (endzone) = 30
            try testing.expect(yard_20.isValid());
            try testing.expect(yard_20.isInBounds());
            
            const yard_50 = field.fieldPositionToCoordinate(50, field.FIELD_WIDTH_YARDS / 2);
            try testing.expectEqual(field.FIELD_WIDTH_YARDS / 2, yard_50.x);
            try testing.expectEqual(@as(f32, 60), yard_50.y); // 50 + 10 = 60
            try testing.expect(yard_50.isValid());
            try testing.expect(yard_50.isInBounds());
            
            // Test goal line positions
            const home_goal = field.fieldPositionToCoordinate(0, 26.67);
            try testing.expectEqual(@as(f32, 26.67), home_goal.x);
            try testing.expectEqual(@as(f32, 10), home_goal.y); // 0 + 10 = 10
            try testing.expect(home_goal.isValid());
            try testing.expect(home_goal.isInBounds());
            
            const away_goal = field.fieldPositionToCoordinate(100, 26.67);
            try testing.expectEqual(@as(f32, 26.67), away_goal.x);
            try testing.expectEqual(@as(f32, 110), away_goal.y); // 100 + 10 = 110
            try testing.expect(away_goal.isValid());
            try testing.expect(away_goal.isInBounds());
            
            // Test hash mark positions
            const left_hash_30 = field.fieldPositionToCoordinate(30, field.HASH_FROM_SIDELINE_YARDS);
            try testing.expectEqual(field.HASH_FROM_SIDELINE_YARDS, left_hash_30.x);
            try testing.expectEqual(@as(f32, 40), left_hash_30.y); // 30 + 10 = 40
            try testing.expect(left_hash_30.isValid());
            
            const right_hash_70 = field.fieldPositionToCoordinate(70, field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS);
            try testing.expectEqual(field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS, right_hash_70.x);
            try testing.expectEqual(@as(f32, 80), right_hash_70.y); // 70 + 10 = 80
            try testing.expect(right_hash_70.isValid());
            
            // Test sideline positions
            const left_sideline_25 = field.fieldPositionToCoordinate(25, 0);
            try testing.expectEqual(@as(f32, 0), left_sideline_25.x);
            try testing.expectEqual(@as(f32, 35), left_sideline_25.y); // 25 + 10 = 35
            try testing.expect(left_sideline_25.isValid());
            
            const right_sideline_75 = field.fieldPositionToCoordinate(75, field.FIELD_WIDTH_YARDS);
            try testing.expectEqual(field.FIELD_WIDTH_YARDS, right_sideline_75.x);
            try testing.expectEqual(@as(f32, 85), right_sideline_75.y); // 75 + 10 = 85
            try testing.expect(right_sideline_75.isValid());
        }
        
        test "integration: Conversions: round-trip conversion consistency" {
            const allocator = testing.allocator;
            
            // Test that conversions are consistent
            const test_positions = [_]struct { yard: u8, x: f32 }{
                .{ .yard = 25, .x = 26.67 },
                .{ .yard = 50, .x = field.FIELD_WIDTH_YARDS / 2 },
                .{ .yard = 75, .x = field.HASH_FROM_SIDELINE_YARDS },
            };
            
            for (test_positions) |pos| {
                // Create coordinate from yard line
                const coord = field.fieldPositionToCoordinate(pos.yard, pos.x);
                
                // Get nearest yard line
                const nearest = coord.nearestYardLine();
                try testing.expectEqual(@as(?u8, pos.yard), nearest);
                
                // Verify position string is reasonable
                const pos_str = try field.coordinateToFieldPosition(coord, allocator);
                defer allocator.free(pos_str);
                try testing.expect(pos_str.len > 0);
            }
            
            // Test feet conversion round-trip
            const original = field.Coordinate.init(15.5, 35.5);
            const to_feet = original.toFeet();
            const back_to_yards = field.Coordinate.fromFeet(to_feet.x, to_feet.y);
            
            const tolerance: f32 = 0.01;
            try testing.expect(@abs(back_to_yards.x - original.x) < tolerance);
            try testing.expect(@abs(back_to_yards.y - original.y) < tolerance);
            
            // Test mirror operations are reversible
            const test_coord = field.Coordinate.init(20, 40);
            const mirror_x_twice = test_coord.mirrorX().mirrorX();
            const mirror_y_twice = test_coord.mirrorY().mirrorY();
            const rotate_twice = test_coord.rotate180().rotate180();
            
            try testing.expect(@abs(mirror_x_twice.x - test_coord.x) < tolerance);
            try testing.expect(@abs(mirror_x_twice.y - test_coord.y) < tolerance);
            try testing.expect(@abs(mirror_y_twice.x - test_coord.x) < tolerance);
            try testing.expect(@abs(mirror_y_twice.y - test_coord.y) < tolerance);
            try testing.expect(@abs(rotate_twice.x - test_coord.x) < tolerance);
            try testing.expect(@abs(rotate_twice.y - test_coord.y) < tolerance);
        }
        
        test "integration: Conversions: transformation combinations" {
            // Test that rotate180 equals mirrorX + mirrorY (in any order)
            const test_coords = [_]field.Coordinate{
                field.Coordinate.init(10, 20),
                field.Coordinate.init(0, 0),
                field.Coordinate.init(field.FIELD_WIDTH_YARDS, field.FIELD_LENGTH_YARDS),
                field.Coordinate.init(field.FIELD_WIDTH_YARDS / 2, field.FIELD_LENGTH_YARDS / 2),
            };
            
            const tolerance: f32 = 0.001;
            
            for (test_coords) |coord| {
                const rotated = coord.rotate180();
                const mirror_xy = coord.mirrorX().mirrorY();
                const mirror_yx = coord.mirrorY().mirrorX();
                
                // All three should be equivalent
                try testing.expect(@abs(rotated.x - mirror_xy.x) < tolerance);
                try testing.expect(@abs(rotated.y - mirror_xy.y) < tolerance);
                try testing.expect(@abs(rotated.x - mirror_yx.x) < tolerance);
                try testing.expect(@abs(rotated.y - mirror_yx.y) < tolerance);
            }
            
            // Test transformation preserves validity
            const valid_coord = field.Coordinate.init(20, 50);
            try testing.expect(valid_coord.isValid());
            try testing.expect(valid_coord.mirrorX().isValid());
            try testing.expect(valid_coord.mirrorY().isValid());
            try testing.expect(valid_coord.rotate180().isValid());
            
            // Test transformations maintain distance relationships
            const coord1 = field.Coordinate.init(10, 30);
            const coord2 = field.Coordinate.init(20, 40);
            const original_distance = coord1.distanceTo(coord2);
            
            // Distance should be preserved after same transformation
            const mirror_x_distance = coord1.mirrorX().distanceTo(coord2.mirrorX());
            const mirror_y_distance = coord1.mirrorY().distanceTo(coord2.mirrorY());
            const rotate_distance = coord1.rotate180().distanceTo(coord2.rotate180());
            
            try testing.expect(@abs(original_distance - mirror_x_distance) < tolerance);
            try testing.expect(@abs(original_distance - mirror_y_distance) < tolerance);
            try testing.expect(@abs(original_distance - rotate_distance) < tolerance);
        }
    
    // └──────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Stress Tests ────────────────────────────┐
    
        test "stress: Conversions: precision and rounding behavior" {
            const tolerance: f32 = 0.01;
            
            // Test nearestYardLine with precise fractional positions
            const exactly_half = field.Coordinate.init(26.67, 35.5); // Exactly between 25 and 26
            try testing.expectEqual(@as(?u8, 26), exactly_half.nearestYardLine()); // Should round up
            
            const just_below_half = field.Coordinate.init(26.67, 35.49);
            try testing.expectEqual(@as(?u8, 25), just_below_half.nearestYardLine());
            
            const just_above_half = field.Coordinate.init(26.67, 35.51);
            try testing.expectEqual(@as(?u8, 26), just_above_half.nearestYardLine());
            
            // Test feet conversion precision with field width (53.333333 yards = 160 feet)
            const field_width_feet = field.FIELD_WIDTH_YARDS * field.YARDS_TO_FEET;
            try testing.expect(@abs(field_width_feet - 160) < tolerance);
            
            const field_width_back = 160 * field.FEET_TO_YARDS;
            try testing.expect(@abs(field_width_back - field.FIELD_WIDTH_YARDS) < tolerance);
            
            // Test repeated conversions maintain reasonable precision
            var coord = field.Coordinate.init(26.666667, 60);
            for (0..10) |_| {
                coord = coord.toFeet();
                coord = field.Coordinate.fromFeet(coord.x, coord.y);
            }
            // After 10 round trips, should still be close to original
            try testing.expect(@abs(coord.x - 26.666667) < 0.1);
            try testing.expect(@abs(coord.y - 60) < 0.1);
            
            // Test mirror operations with precise center calculations
            const center_x = field.FIELD_WIDTH_YARDS / 2;
            const center_y = field.FIELD_LENGTH_YARDS / 2;
            
            // Points exactly at center should not move
            const at_center_x = field.Coordinate.init(center_x, 30);
            const mirrored_center_x = at_center_x.mirrorX();
            try testing.expect(@abs(mirrored_center_x.x - center_x) < tolerance);
            
            const at_center_y = field.Coordinate.init(30, center_y);
            const mirrored_center_y = at_center_y.mirrorY();
            try testing.expect(@abs(mirrored_center_y.y - center_y) < tolerance);
            
            // Test string allocation with memory tracking
            const allocator = testing.allocator;
            
            // Generate many position strings to test memory management
            for (0..100) |i| {
                const y = @as(f32, @floatFromInt(i)) * 1.2; // 0 to 120 in steps
                const test_coord = field.Coordinate.init(26.67, y);
                const str = try field.coordinateToFieldPosition(test_coord, allocator);
                defer allocator.free(str);
                try testing.expect(str.len > 0);
            }
        }
        
        test "stress: Conversions: boundary conditions" {
            const allocator = testing.allocator;
            const tolerance: f32 = 0.001;
            
            // Test nearestYardLine at exact boundaries
            const at_10_boundary = field.Coordinate.init(26.67, 10); // Exactly at goal line
            try testing.expectEqual(@as(?u8, 0), at_10_boundary.nearestYardLine());
            
            const just_past_10 = field.Coordinate.init(26.67, 10.001); // Just into playing field
            try testing.expectEqual(@as(?u8, 0), just_past_10.nearestYardLine());
            
            const just_before_10 = field.Coordinate.init(26.67, 9.999); // Just in endzone
            try testing.expectEqual(@as(?u8, null), just_before_10.nearestYardLine());
            
            const at_110_boundary = field.Coordinate.init(26.67, 110); // Exactly at far goal line
            try testing.expectEqual(@as(?u8, 100), at_110_boundary.nearestYardLine());
            
            const just_before_110 = field.Coordinate.init(26.67, 109.999);
            try testing.expectEqual(@as(?u8, 100), just_before_110.nearestYardLine());
            
            const just_past_110 = field.Coordinate.init(26.67, 110.001); // Just in endzone
            try testing.expectEqual(@as(?u8, null), just_past_110.nearestYardLine());
            
            // Test position strings at boundaries
            const endzone_boundary = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS - 0.001);
            const endzone_str = try field.coordinateToFieldPosition(endzone_boundary, allocator);
            defer allocator.free(endzone_str);
            try testing.expectEqualStrings("South End Zone", endzone_str);
            
            const playing_boundary = field.Coordinate.init(26.67, field.END_ZONE_LENGTH_YARDS);
            const playing_str = try field.coordinateToFieldPosition(playing_boundary, allocator);
            defer allocator.free(playing_str);
            try testing.expectEqualStrings("Own Goal", playing_str);
            
            // Test transformations at field boundaries
            const corner_nw = field.Coordinate.init(0, field.FIELD_LENGTH_YARDS);
            const mirrored_nw = corner_nw.mirrorX();
            try testing.expect(@abs(mirrored_nw.x - field.FIELD_WIDTH_YARDS) < tolerance);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, mirrored_nw.y);
            
            const rotated_nw = corner_nw.rotate180();
            try testing.expect(@abs(rotated_nw.x - field.FIELD_WIDTH_YARDS) < tolerance);
            try testing.expect(@abs(rotated_nw.y - 0) < tolerance);
            
            // Test extreme values don't cause issues
            const huge_coord = field.Coordinate.init(1000, 1000);
            const huge_feet = huge_coord.toFeet();
            try testing.expectEqual(@as(f32, 3000), huge_feet.x);
            try testing.expectEqual(@as(f32, 3000), huge_feet.y);
            
            // Negative coordinates
            const negative = field.Coordinate.init(-10, -20);
            const neg_feet = negative.toFeet();
            try testing.expectEqual(@as(f32, -30), neg_feet.x);
            try testing.expectEqual(@as(f32, -60), neg_feet.y);
            
            const neg_mirrored = negative.mirrorX();
            const neg_rotated = negative.rotate180();
            // These should produce coordinates, even if invalid
            _ = neg_mirrored;
            _ = neg_rotated;
            
            // Test fieldPositionToCoordinate with boundary yard lines
            const yard_0 = field.fieldPositionToCoordinate(0, 26.67);
            try testing.expectEqual(@as(f32, 10), yard_0.y); // Should be at goal line
            
            const yard_100 = field.fieldPositionToCoordinate(100, 26.67);
            try testing.expectEqual(@as(f32, 110), yard_100.y); // Should be at far goal line
            
            // Test with maximum yard line values
            const yard_255 = field.fieldPositionToCoordinate(255, 26.67); // Max u8
            try testing.expectEqual(@as(f32, 265), yard_255.y); // 255 + 10
            // This will be invalid but shouldn't crash
            try testing.expect(!yard_255.isValid());
        }
    
    // └──────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝
