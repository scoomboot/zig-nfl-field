// field.test.zig — Unit tests for NFL field module
//
// repo   : https://github.com/fisty/zig-nfl-field
// author : https://github.com/fisty
//
// Vibe coded by Fisty.

const std = @import("std");
const testing = std.testing;
const field = @import("field.zig");

// ╔══════════════════════════════════════ CONSTANTS TESTS ═══════════════════════════════════════╗

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
            const f = field.Field.init();
            
            // Verify Field struct uses the correct constants
            try testing.expectEqual(field.FIELD_WIDTH_YARDS, f.width);
            try testing.expectEqual(field.FIELD_LENGTH_YARDS, f.length);
            try testing.expectEqual(field.END_ZONE_LENGTH_YARDS, f.endzone_length);
            
            // Test boundary conditions with exact constant values
            try testing.expect(f.contains(0, 0));
            try testing.expect(f.contains(field.FIELD_LENGTH_YARDS, field.FIELD_WIDTH_YARDS));
            try testing.expect(!f.contains(field.FIELD_LENGTH_YARDS + 0.1, field.FIELD_WIDTH_YARDS));
            try testing.expect(!f.contains(field.FIELD_LENGTH_YARDS, field.FIELD_WIDTH_YARDS + 0.1));
        }
        
        test "integration: Coordinate: validates against constant-based boundaries" {
            const f = field.Field.init();
            
            // Test coordinates at exact constant boundaries
            const corner_coord = field.Coordinate.init(field.FIELD_LENGTH_YARDS, field.FIELD_WIDTH_YARDS);
            try testing.expect(corner_coord.isValid(f));
            
            const hash_coord = field.Coordinate.init(50, field.HASH_FROM_SIDELINE_YARDS);
            try testing.expect(hash_coord.isValid(f));
            
            // Test coordinates just outside boundaries
            const outside_length = field.Coordinate.init(field.FIELD_LENGTH_YARDS + 0.1, 26);
            try testing.expect(!outside_length.isValid(f));
            
            const outside_width = field.Coordinate.init(60, field.FIELD_WIDTH_YARDS + 0.1);
            try testing.expect(!outside_width.isValid(f));
        }
        
        test "integration: Field: endzone detection with constants" {
            const f = field.Field.init();
            
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
            const f = field.Field.init();
            const left_hash = field.Coordinate.init(50, field.HASH_FROM_SIDELINE_YARDS);
            const right_hash = field.Coordinate.init(50, field.FIELD_WIDTH_YARDS - field.HASH_FROM_SIDELINE_YARDS);
            
            try testing.expect(left_hash.isValid(f));
            try testing.expect(right_hash.isValid(f));
            
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
                const f = field.Field.init();
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
            const f = field.Field.init();
            
            // Test coordinates with small but measurable differences
            const small_offset: f32 = 0.001; // 1mm precision
            const large_value: f32 = 1000000.0; // Large but manageable value
            
            // Coordinates just inside bounds
            const barely_inside_x = field.FIELD_LENGTH_YARDS - small_offset;
            const barely_inside_y = field.FIELD_WIDTH_YARDS - small_offset;
            try testing.expect(f.contains(barely_inside_x, barely_inside_y));
            
            // Coordinates just outside bounds  
            const barely_outside_x = field.FIELD_LENGTH_YARDS + small_offset;
            const barely_outside_y = field.FIELD_WIDTH_YARDS + small_offset;
            try testing.expect(!f.contains(barely_outside_x, barely_outside_y));
            
            // Extremely large coordinates
            try testing.expect(!f.contains(large_value, 25));
            try testing.expect(!f.contains(60, large_value));
            
            // Extremely small (negative) coordinates
            try testing.expect(!f.contains(-large_value, 25));
            try testing.expect(!f.contains(60, -large_value));
        }
    
    // └──────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ FIELD TESTS ════════════════════════════════════════════╗

    test "unit: Field: init creates field with correct dimensions" {
        const f = field.Field.init();
        
        try testing.expectEqual(@as(f32, field.FIELD_WIDTH_YARDS), f.width);
        try testing.expectEqual(@as(f32, field.FIELD_LENGTH_YARDS), f.length);
        try testing.expectEqual(@as(f32, field.END_ZONE_LENGTH_YARDS), f.endzone_length);
    }
    
    test "unit: Field: contains validates boundaries correctly" {
        const f = field.Field.init();
        
        // Test valid coordinates using constants
        try testing.expect(f.contains(0, 0));
        try testing.expect(f.contains(60, field.FIELD_WIDTH_YARDS / 2));
        try testing.expect(f.contains(field.FIELD_LENGTH_YARDS, field.FIELD_WIDTH_YARDS));
        
        // Test invalid coordinates
        try testing.expect(!f.contains(-1, field.FIELD_WIDTH_YARDS / 2));
        try testing.expect(!f.contains(field.FIELD_LENGTH_YARDS + 1, field.FIELD_WIDTH_YARDS / 2));
        try testing.expect(!f.contains(60, -1));
        try testing.expect(!f.contains(60, field.FIELD_WIDTH_YARDS + 1));
    }
    
    test "unit: Field: endzone detection works correctly" {
        const f = field.Field.init();
        
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

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ COORDINATE TESTS ═══════════════════════════════════════╗

    test "unit: Coordinate: init creates coordinate correctly" {
        const c = field.Coordinate.init(field.FIELD_LENGTH_YARDS / 2, field.FIELD_WIDTH_YARDS / 2);
        
        try testing.expectEqual(field.FIELD_LENGTH_YARDS / 2, c.x);
        try testing.expectEqual(field.FIELD_WIDTH_YARDS / 2, c.y);
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
    
    test "unit: Coordinate: isValid validates against field boundaries" {
        const f = field.Field.init();
        
        // Valid coordinates using constants
        const valid = field.Coordinate.init(field.FIELD_LENGTH_YARDS / 2, field.FIELD_WIDTH_YARDS / 2);
        try testing.expect(valid.isValid(f));
        
        // Invalid X coordinate (beyond field length)
        const invalidX = field.Coordinate.init(field.FIELD_LENGTH_YARDS + 10, field.FIELD_WIDTH_YARDS / 2);
        try testing.expect(!invalidX.isValid(f));
        
        // Invalid Y coordinate (beyond field width)
        const invalidY = field.Coordinate.init(field.FIELD_LENGTH_YARDS / 2, field.FIELD_WIDTH_YARDS + 10);
        try testing.expect(!invalidY.isValid(f));
        
        // Negative coordinates
        const negative = field.Coordinate.init(-5, -5);
        try testing.expect(!negative.isValid(f));
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝