// field.zig — NFL field representation and coordinate system
//
// repo   : https://github.com/fisty/zig-nfl-field
// author : https://github.com/fisty
//
// Vibe coded by Fisty.

const std = @import("std");

// ╔══════════════════════════════════════ CONSTANTS ══════════════════════════════════════════════╗

    /// NFL field dimensions in yards
    pub const FIELD_LENGTH = 120;  // 100 yards playing field + 2x10 yard endzones
    pub const FIELD_WIDTH = 53.33;  // 53 1/3 yards wide
    pub const ENDZONE_LENGTH = 10;
    pub const PLAYING_FIELD_LENGTH = 100;

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ FIELD STRUCT ═══════════════════════════════════════════╗

    /// Represents an NFL field with coordinate system
    pub const Field = struct {
        /// Width of the field in yards
        width: f32 = FIELD_WIDTH,
        
        /// Total length including endzones in yards  
        length: f32 = FIELD_LENGTH,
        
        /// Length of each endzone in yards
        endzone_length: f32 = ENDZONE_LENGTH,
        
        /// Initialize a new field with default NFL dimensions
        pub fn init() Field {
            return Field{};
        }
        
        /// Check if a coordinate is within field boundaries
        pub fn contains(self: Field, x: f32, y: f32) bool {
            return x >= 0 and x <= self.length and 
                   y >= 0 and y <= self.width;
        }
        
        /// Check if a coordinate is in the home endzone
        pub fn isInHomeEndzone(self: Field, x: f32) bool {
            return x >= 0 and x < self.endzone_length;
        }
        
        /// Check if a coordinate is in the away endzone
        pub fn isInAwayEndzone(self: Field, x: f32) bool {
            return x > (self.length - self.endzone_length) and x <= self.length;
        }
        
        /// Check if a coordinate is in the playing field (not in endzones)
        pub fn isInPlayingField(self: Field, x: f32) bool {
            return x >= self.endzone_length and x <= (self.length - self.endzone_length);
        }
    };

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ COORDINATE STRUCT ══════════════════════════════════════╗

    /// Represents a position on the field
    pub const Coordinate = struct {
        /// X position (0-120 yards, 0 is home endzone back line)
        x: f32,
        
        /// Y position (0-53.33 yards, 0 is left sideline)
        y: f32,
        
        /// Create a new coordinate
        pub fn init(x: f32, y: f32) Coordinate {
            return Coordinate{ .x = x, .y = y };
        }
        
        /// Calculate distance to another coordinate
        pub fn distanceTo(self: Coordinate, other: Coordinate) f32 {
            const dx = other.x - self.x;
            const dy = other.y - self.y;
            return @sqrt(dx * dx + dy * dy);
        }
        
        /// Check if this coordinate is valid for the given field
        pub fn isValid(self: Coordinate, field: Field) bool {
            return field.contains(self.x, self.y);
        }
    };

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝