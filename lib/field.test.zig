// field.test.zig — Unit tests for NFL field module
//
// repo   : https://github.com/fisty/zig-nfl-field
// author : https://github.com/fisty
//
// Vibe coded by Fisty.

const std = @import("std");
const testing = std.testing;
const field = @import("field.zig");

// ╔══════════════════════════════════════ FIELD TESTS ════════════════════════════════════════════╗

    test "unit: Field: init creates field with correct dimensions" {
        const f = field.Field.init();
        
        try testing.expectEqual(@as(f32, field.FIELD_WIDTH), f.width);
        try testing.expectEqual(@as(f32, field.FIELD_LENGTH), f.length);
        try testing.expectEqual(@as(f32, field.ENDZONE_LENGTH), f.endzone_length);
    }
    
    test "unit: Field: contains validates boundaries correctly" {
        const f = field.Field.init();
        
        // Test valid coordinates
        try testing.expect(f.contains(0, 0));
        try testing.expect(f.contains(60, 26.67));
        try testing.expect(f.contains(120, 53.33));
        
        // Test invalid coordinates
        try testing.expect(!f.contains(-1, 26.67));
        try testing.expect(!f.contains(121, 26.67));
        try testing.expect(!f.contains(60, -1));
        try testing.expect(!f.contains(60, 54));
    }
    
    test "unit: Field: endzone detection works correctly" {
        const f = field.Field.init();
        
        // Home endzone tests
        try testing.expect(f.isInHomeEndzone(5));
        try testing.expect(f.isInHomeEndzone(0));
        try testing.expect(f.isInHomeEndzone(9.99));
        try testing.expect(!f.isInHomeEndzone(10));
        try testing.expect(!f.isInHomeEndzone(50));
        
        // Away endzone tests
        try testing.expect(f.isInAwayEndzone(115));
        try testing.expect(f.isInAwayEndzone(120));
        try testing.expect(f.isInAwayEndzone(110.01));
        try testing.expect(!f.isInAwayEndzone(110));
        try testing.expect(!f.isInAwayEndzone(50));
        
        // Playing field tests
        try testing.expect(f.isInPlayingField(10));
        try testing.expect(f.isInPlayingField(60));
        try testing.expect(f.isInPlayingField(110));
        try testing.expect(!f.isInPlayingField(5));
        try testing.expect(!f.isInPlayingField(115));
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ COORDINATE TESTS ═══════════════════════════════════════╗

    test "unit: Coordinate: init creates coordinate correctly" {
        const c = field.Coordinate.init(50.5, 26.67);
        
        try testing.expectEqual(@as(f32, 50.5), c.x);
        try testing.expectEqual(@as(f32, 26.67), c.y);
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
        
        // Valid coordinates
        const valid = field.Coordinate.init(60, 26.67);
        try testing.expect(valid.isValid(f));
        
        // Invalid X coordinate
        const invalidX = field.Coordinate.init(130, 26.67);
        try testing.expect(!invalidX.isValid(f));
        
        // Invalid Y coordinate  
        const invalidY = field.Coordinate.init(60, 60);
        try testing.expect(!invalidY.isValid(f));
        
        // Negative coordinates
        const negative = field.Coordinate.init(-5, -5);
        try testing.expect(!negative.isValid(f));
    }

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝