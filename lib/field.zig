// field.zig — NFL field representation and coordinate system
//
// repo   : https://github.com/fisty/zig-nfl-field
// docs   : https://fisty.github.io/zig-nfl-field/field
// author : https://github.com/fisty
//
// Vibe coded by Fisty.

const std = @import("std");

// ╔══════════════════════════════════════ CONSTANTS ══════════════════════════════════════════════╗

    /// NFL field coordinate system constants
    /// Origin (0,0): Southwest corner of field
    /// X-axis: East-west (0 to 53.33 yards)
    /// Y-axis: North-south (0 to 120 yards)
    /// Units: Yards (f32 for precision)

    // ┌─── Field Dimensions ───┐
    
        /// Total field length including both endzones (in yards)
        pub const FIELD_LENGTH_YARDS: f32 = 120.0;
        
        /// Playing field length excluding endzones (in yards)
        pub const PLAYING_FIELD_LENGTH_YARDS: f32 = 100.0;
        
        /// Length of each endzone (in yards)
        pub const END_ZONE_LENGTH_YARDS: f32 = 10.0;
        
        /// Field width in yards (53 1/3 yards)
        pub const FIELD_WIDTH_YARDS: f32 = 53.333333;
        
        /// Field width in feet
        pub const FIELD_WIDTH_FEET: f32 = 160.0;
    
    // ┌─── Hash Mark Positioning ───┐
    
        /// Distance between hash marks (in yards)
        pub const HASH_SEPARATION_YARDS: f32 = 23.583333;
        
        /// Distance from sideline to nearest hash mark (in yards)
        pub const HASH_FROM_SIDELINE_YARDS: f32 = 14.875;
    
    // ┌─── Conversion Factors ───┐
    
        /// Yards to feet conversion factor
        pub const YARDS_TO_FEET: f32 = 3.0;
        
        /// Feet to yards conversion factor
        pub const FEET_TO_YARDS: f32 = 0.333333;

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ FIELD STRUCT ═══════════════════════════════════════════╗

    /// Represents an NFL field with coordinate system
    pub const Field = struct {
        /// Width of the field in yards
        width: f32 = FIELD_WIDTH_YARDS,
        
        /// Total length including endzones in yards  
        length: f32 = FIELD_LENGTH_YARDS,
        
        /// Length of each endzone in yards
        endzone_length: f32 = END_ZONE_LENGTH_YARDS,
        
        /// Initialize a new field with default NFL dimensions
        pub fn init() Field {
            return Field{};
        }
        
        /// Check if a coordinate is within field boundaries
        ///
        /// __Parameters__
        ///
        /// - `x`: X coordinate in yards (0 to field length)
        /// - `y`: Y coordinate in yards (0 to field width)
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is within field boundaries, `false` otherwise
        pub fn contains(self: Field, x: f32, y: f32) bool {
            return x >= 0 and x <= self.length and 
                   y >= 0 and y <= self.width;
        }
        
        /// Check if a coordinate is in the home endzone
        ///
        /// __Parameters__
        ///
        /// - `x`: X coordinate in yards
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in home endzone (0 to 10 yards), `false` otherwise
        pub fn isInHomeEndzone(self: Field, x: f32) bool {
            return x >= 0 and x < self.endzone_length;
        }
        
        /// Check if a coordinate is in the away endzone
        ///
        /// __Parameters__
        ///
        /// - `x`: X coordinate in yards
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in away endzone (110 to 120 yards), `false` otherwise
        pub fn isInAwayEndzone(self: Field, x: f32) bool {
            return x > (self.length - self.endzone_length) and x <= self.length;
        }
        
        /// Check if a coordinate is in the playing field (not in endzones)
        ///
        /// __Parameters__
        ///
        /// - `x`: X coordinate in yards
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in playing field (10 to 110 yards), `false` otherwise
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
        ///
        /// Uses Euclidean distance formula: sqrt((x2-x1)² + (y2-y1)²)
        ///
        /// __Parameters__
        ///
        /// - `other`: Target coordinate to calculate distance to
        ///
        /// __Return__
        ///
        /// - Distance in yards as f32
        pub fn distanceTo(self: Coordinate, other: Coordinate) f32 {
            const dx = other.x - self.x;
            const dy = other.y - self.y;
            return @sqrt(dx * dx + dy * dy);
        }
        
        /// Check if this coordinate is valid for the given field
        ///
        /// __Parameters__
        ///
        /// - `field`: Field instance to validate against
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is within field boundaries, `false` otherwise
        pub fn isValid(self: Coordinate, field: Field) bool {
            return field.contains(self.x, self.y);
        }
    };

// ╚══════════════════════════════════════════════════════════════════════════════════════════════╝