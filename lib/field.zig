// field.zig — NFL field representation and coordinate system
//
// repo   : https://github.com/fisty/zig-nfl-field
// docs   : https://fisty.github.io/zig-nfl-field/field
// author : https://github.com/fisty
//
// Vibe coded by Fisty.

const std = @import("std");

// ╔═══ CONSTANTS ═══╗

    /// NFL field coordinate system constants
    /// Origin (0,0): Southwest corner of field
    /// X-axis: East-west (0 to 53.33 yards)
    /// Y-axis: North-south (0 to 120 yards)
    /// Units: Yards (f32 for precision)
    ///
    /// Field Layout Diagram:
    /// ```
    ///     (0,120) ← Away Endzone → (53.33,120)
    ///        ↑                          ↑
    ///        │      AWAY ENDZONE       │
    ///        │    (110-120 yards)      │  
    ///        ├──────────────────────────┤ Y=110
    ///        │                          │
    ///     Y  │     PLAYING FIELD       │  North
    ///     ↑  │    (10-110 yards)       │    ↑
    ///     │  │                          │    │
    ///        ├──────────────────────────┤ Y=10
    ///        │      HOME ENDZONE       │
    ///        │     (0-10 yards)        │
    ///        ↓                          ↓
    ///      (0,0) ← Home Endzone → (53.33,0)
    ///        └──────────────────────────┘
    ///        ←─────── X-axis ──────────→
    ///              (0-53.33 yards)
    ///                 East-West
    /// ```

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

// ╚═════════════════╝

// ╔═══ FIELD STRUCT ═══╗

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
        /// - `x`: X coordinate in yards (0 to field width)
        /// - `y`: Y coordinate in yards (0 to field length)
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is within field boundaries, `false` otherwise
        pub fn contains(self: Field, x: f32, y: f32) bool {
            return x >= 0 and x <= self.width and 
                   y >= 0 and y <= self.length;
        }
        
        /// Check if a coordinate is in the home endzone
        ///
        /// __Parameters__
        ///
        /// - `y`: Y coordinate in yards
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in home endzone (0 to 10 yards), `false` otherwise
        pub fn isInHomeEndzone(self: Field, y: f32) bool {
            return y >= 0 and y < self.endzone_length;
        }
        
        /// Check if a coordinate is in the away endzone
        ///
        /// __Parameters__
        ///
        /// - `y`: Y coordinate in yards
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in away endzone (110 to 120 yards), `false` otherwise
        pub fn isInAwayEndzone(self: Field, y: f32) bool {
            return y > (self.length - self.endzone_length) and y <= self.length;
        }
        
        /// Check if a coordinate is in the playing field (not in endzones)
        ///
        /// __Parameters__
        ///
        /// - `y`: Y coordinate in yards
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in playing field (10 to 110 yards), `false` otherwise
        pub fn isInPlayingField(self: Field, y: f32) bool {
            return y >= self.endzone_length and y <= (self.length - self.endzone_length);
        }
    };

// ╚═════════════════╝

// ╔═══ COORDINATE STRUCT ═══╗

    /// Represents a position on the field
    /// Origin (0,0) is at the southwest corner of the field
    pub const Coordinate = struct {
        /// X position (0-53.33 yards, 0 is left/west sideline)
        x: f32,
        
        /// Y position (0-120 yards, 0 is home endzone back line)
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
        
        /// Check if this coordinate is valid within NFL field boundaries
        ///
        /// Validates against standard NFL field dimensions without requiring a Field instance
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is within field boundaries (0 to FIELD_WIDTH_YARDS for x,
        ///   0 to FIELD_LENGTH_YARDS for y), `false` otherwise
        pub fn isValid(self: Coordinate) bool {
            return self.x >= 0 and self.x <= FIELD_WIDTH_YARDS and 
                   self.y >= 0 and self.y <= FIELD_LENGTH_YARDS;
        }
        
        /// Check if this coordinate is within the playing field boundaries (excluding endzones)
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in the playing field (not in endzones), `false` otherwise
        pub fn isInBounds(self: Coordinate) bool {
            return self.y >= END_ZONE_LENGTH_YARDS and 
                   self.y <= (FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS) and
                   self.x > 0 and self.x < FIELD_WIDTH_YARDS;
        }
        
        /// Check if this coordinate is valid for the given field
        ///
        /// Kept for backwards compatibility - validates against a specific Field instance
        ///
        /// __Parameters__
        ///
        /// - `field`: Field instance to validate against
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is within field boundaries, `false` otherwise
        pub fn isValidForField(self: Coordinate, field: Field) bool {
            return field.contains(self.x, self.y);
        }
        
        /// Check if coordinate is in either end zone
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in home or away endzone (y < 10 or y > 110), `false` otherwise
        pub fn isInEndZone(self: Coordinate) bool {
            if (!self.isValid()) return false;
            return self.y < END_ZONE_LENGTH_YARDS or 
                   self.y > (FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS);
        }
        
        /// Check if coordinate is in the south (home) end zone
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in home endzone (y < 10), `false` otherwise
        pub fn isInSouthEndZone(self: Coordinate) bool {
            return self.isValid() and self.y < END_ZONE_LENGTH_YARDS;
        }
        
        /// Check if coordinate is in the north (away) end zone
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in away endzone (y > 110), `false` otherwise
        pub fn isInNorthEndZone(self: Coordinate) bool {
            return self.isValid() and 
                   self.y > (FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS);
        }
        
        /// Check if coordinate is on a sideline
        ///
        /// Uses epsilon tolerance for floating-point comparison
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is on east or west sideline boundaries, `false` otherwise
        pub fn isOnSideline(self: Coordinate) bool {
            const epsilon = 0.01; // Tolerance for floating point comparison
            return self.isValid() and 
                   (@abs(self.x) < epsilon or 
                    @abs(self.x - FIELD_WIDTH_YARDS) < epsilon);
        }
        
        /// Check if coordinate is on a goal line
        ///
        /// Uses epsilon tolerance for floating-point comparison
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is on either goal line (y = 10 or y = 110), `false` otherwise
        pub fn isOnGoalLine(self: Coordinate) bool {
            const epsilon = 0.01;
            return self.isValid() and
                   (@abs(self.y - END_ZONE_LENGTH_YARDS) < epsilon or
                    @abs(self.y - (FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS)) < epsilon);
        }
        
        /// Clamp coordinate to field boundaries
        ///
        /// Returns a new coordinate with x and y values clamped to valid field ranges
        ///
        /// __Return__
        ///
        /// - New Coordinate with values clamped to field boundaries
        pub fn clamp(self: Coordinate) Coordinate {
            return Coordinate.init(
                std.math.clamp(self.x, 0.0, FIELD_WIDTH_YARDS),
                std.math.clamp(self.y, 0.0, FIELD_LENGTH_YARDS)
            );
        }
    };

// ╚═════════════════╝

// ╔═══ VALIDATION ERRORS ═══╗

    /// Error types for coordinate validation
    pub const CoordinateError = error{
        /// X coordinate is outside field boundaries
        OutOfBoundsX,
        
        /// Y coordinate is outside field boundaries
        OutOfBoundsY,
        
        /// Coordinate is invalid (general validation failure)
        InvalidCoordinate,
    };
    
    /// Validate coordinate with detailed error information
    ///
    /// Performs boundary checking and returns specific error types for out-of-bounds conditions
    ///
    /// __Parameters__
    ///
    /// - `coord`: Coordinate to validate
    ///
    /// __Return__
    ///
    /// - Returns void on success, or specific CoordinateError on validation failure
    pub fn validateCoordinate(coord: Coordinate) CoordinateError!void {
        if (coord.x < 0.0 or coord.x > FIELD_WIDTH_YARDS) {
            return CoordinateError.OutOfBoundsX;
        }
        if (coord.y < 0.0 or coord.y > FIELD_LENGTH_YARDS) {
            return CoordinateError.OutOfBoundsY;
        }
    }

// ╚═════════════════╝