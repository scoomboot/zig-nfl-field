// field.zig — NFL field representation and coordinate system
//
// repo   : https://github.com/fisty/zig-nfl-field
// docs   : https://fisty.github.io/zig-nfl-field/field
// author : https://github.com/fisty
//
// Vibe coded by fisty.

const std = @import("std");

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                                     CONSTANTS                                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

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

    // ┌─── Field Dimensions ────────────────────────────────────────────────────────┐
    
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
    
    // ┌─── Hash Mark Positioning ──────────────────────────────────────────────────┐
    
        /// Distance between hash marks (in yards)
        pub const HASH_SEPARATION_YARDS: f32 = 23.583333;
        
        /// Distance from sideline to nearest hash mark (in yards)
        pub const HASH_FROM_SIDELINE_YARDS: f32 = 14.875;
    
    // ┌─── Conversion Factors ──────────────────────────────────────────────────────┐
    
        /// Yards to feet conversion factor
        pub const YARDS_TO_FEET: f32 = 3.0;
        
        /// Feet to yards conversion factor
        pub const FEET_TO_YARDS: f32 = 0.333333;

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                                    FIELD STRUCT                                    ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

    /// Represents an NFL field with coordinate system
    pub const Field = struct {
        /// Width of the field in yards
        width: f32 = FIELD_WIDTH_YARDS,
        
        /// Total length including endzones in yards  
        length: f32 = FIELD_LENGTH_YARDS,
        
        /// Length of each endzone in yards
        endzone_length: f32 = END_ZONE_LENGTH_YARDS,
        
        /// Name of the field
        name: []const u8 = "NFL Field",
        
        /// Type of playing surface
        surface_type: SurfaceType = .turf,
        
        /// Memory allocator for dynamic operations
        allocator: std.mem.Allocator,
        
        /// Northern boundary of the field (max Y coordinate)
        north_boundary: f32 = FIELD_LENGTH_YARDS,
        
        /// Southern boundary of the field (min Y coordinate)
        south_boundary: f32 = 0.0,
        
        /// Eastern boundary of the field (max X coordinate)
        east_boundary: f32 = FIELD_WIDTH_YARDS,
        
        /// Western boundary of the field (min X coordinate)
        west_boundary: f32 = 0.0,
        
        /// X position of left hash mark
        left_hash_x: f32 = HASH_FROM_SIDELINE_YARDS,
        
        /// X position of right hash mark
        right_hash_x: f32 = FIELD_WIDTH_YARDS - HASH_FROM_SIDELINE_YARDS,
        
        /// X position of field center
        center_x: f32 = FIELD_WIDTH_YARDS / 2.0,
        
        /// Initialize a new field with default NFL dimensions
        ///
        /// __Parameters__
        ///
        /// - `allocator`: Memory allocator for dynamic operations
        ///
        /// __Return__
        ///
        /// - A Field struct with default NFL dimensions
        pub fn init(allocator: std.mem.Allocator) Field {
            return Field{
                .allocator = allocator,
            };
        }
        
        /// Deinitialize the field and free any allocated resources
        pub fn deinit(self: *Field) void {
            // Currently no dynamic allocations to free
            // This function exists for future extensibility
            _ = self;
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
    
    /// Types of playing surfaces
    pub const SurfaceType = enum {
        grass,
        turf,
        hybrid,
    };
    
    /// Field orientation options
    pub const Orientation = enum {
        north_south,
        east_west,
    };
    
    /// Field-related error types
    pub const FieldError = error{
        InvalidDimensions,
        AllocationError,
    };

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                                 COORDINATE STRUCT                                  ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

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
        
        // ┌─── Coordinate Conversions ─────────────────────────────────────────────┐
        
            /// Convert coordinate from yards to feet
            ///
            /// __Return__
            ///
            /// - New Coordinate with x and y values in feet
            pub fn toFeet(self: Coordinate) Coordinate {
                return Coordinate.init(
                    self.x * YARDS_TO_FEET,
                    self.y * YARDS_TO_FEET
                );
            }
            
            /// Create a coordinate from feet measurements
            ///
            /// Static factory method to create a Coordinate from measurements in feet
            ///
            /// __Parameters__
            ///
            /// - `x_feet`: X position in feet
            /// - `y_feet`: Y position in feet
            ///
            /// __Return__
            ///
            /// - New Coordinate with values converted to yards
            pub fn fromFeet(x_feet: f32, y_feet: f32) Coordinate {
                return Coordinate.init(
                    x_feet * FEET_TO_YARDS,
                    y_feet * FEET_TO_YARDS
                );
            }
            
            /// Get the nearest yard line to this coordinate
            ///
            /// Returns the yard line number from the perspective of the home team.
            /// Returns null if the coordinate is in either endzone.
            ///
            /// __Return__
            ///
            /// - `?u8` The yard line number (0-100 from home goal line), or null if in endzone
            pub fn nearestYardLine(self: Coordinate) ?u8 {
                // Return null if in either endzone
                if (self.y < END_ZONE_LENGTH_YARDS or 
                    self.y > FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS) {
                    return null;
                }
                
                // Calculate distance from home goal line
                const yards_from_home_goal = self.y - END_ZONE_LENGTH_YARDS;
                
                // Round to nearest yard line
                const yard_line = @round(yards_from_home_goal);
                
                // Return yard line from home perspective (0-100)
                return @intFromFloat(yard_line);
            }
            
            /// Mirror coordinate across field centerline (east-west axis)
            ///
            /// Reflects the coordinate across the vertical center of the field
            ///
            /// __Return__
            ///
            /// - New Coordinate mirrored across x = 26.67 yards
            pub fn mirrorX(self: Coordinate) Coordinate {
                const center_x = FIELD_WIDTH_YARDS / 2.0;
                const mirrored_x = center_x + (center_x - self.x);
                return Coordinate.init(mirrored_x, self.y);
            }
            
            /// Mirror coordinate across midfield line (north-south axis)
            ///
            /// Reflects the coordinate across the horizontal center of the field
            ///
            /// __Return__
            ///
            /// - New Coordinate mirrored across y = 60 yards
            pub fn mirrorY(self: Coordinate) Coordinate {
                const center_y = FIELD_LENGTH_YARDS / 2.0;
                const mirrored_y = center_y + (center_y - self.y);
                return Coordinate.init(self.x, mirrored_y);
            }
            
            /// Rotate coordinate 180° around field center
            ///
            /// Equivalent to applying both mirrorX and mirrorY transformations
            ///
            /// __Return__
            ///
            /// - New Coordinate rotated 180° around the field center point
            pub fn rotate180(self: Coordinate) Coordinate {
                const center_x = FIELD_WIDTH_YARDS / 2.0;
                const center_y = FIELD_LENGTH_YARDS / 2.0;
                return Coordinate.init(
                    center_x + (center_x - self.x),
                    center_y + (center_y - self.y)
                );
            }
        
        // └────────────────────────────────────────────────────────────────────────┘
    };

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                                 VALIDATION ERRORS                                  ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

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

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                               CONVERSION UTILITIES                                 ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

    /// Convert a coordinate to a field position string
    ///
    /// Formats the coordinate as a descriptive field position string such as:
    /// - "Own 30" - home team's 30-yard line
    /// - "Opp 45" - opponent's 45-yard line  
    /// - "Midfield" - the 50-yard line
    /// - "South End Zone" - home endzone
    /// - "North End Zone" - away endzone
    ///
    /// __Parameters__
    ///
    /// - `coord`: Coordinate to convert to field position
    /// - `allocator`: Memory allocator for string creation
    ///
    /// __Return__
    ///
    /// - Allocated string with field position, caller owns memory
    pub fn coordinateToFieldPosition(coord: Coordinate, allocator: std.mem.Allocator) ![]u8 {
        // Check if in endzones
        if (coord.y < END_ZONE_LENGTH_YARDS) {
            return try allocator.dupe(u8, "South End Zone");
        }
        if (coord.y > FIELD_LENGTH_YARDS - END_ZONE_LENGTH_YARDS) {
            return try allocator.dupe(u8, "North End Zone");
        }
        
        // Calculate yard line from home goal
        const yards_from_home_goal = coord.y - END_ZONE_LENGTH_YARDS;
        const yard_line = @round(yards_from_home_goal);
        
        // Handle goal lines
        if (yard_line == 0) {
            return try allocator.dupe(u8, "Own Goal");
        }
        if (yard_line == 100) {
            return try allocator.dupe(u8, "Opp Goal");
        }
        
        // Handle midfield
        if (yard_line == 50) {
            return try allocator.dupe(u8, "Midfield");
        }
        
        // Determine which side of the field
        if (yard_line < 50) {
            // Home team's side
            const line_num: u32 = @intFromFloat(yard_line);
            return try std.fmt.allocPrint(allocator, "Own {d}", .{line_num});
        } else {
            // Opponent's side
            const line_num: u32 = @intFromFloat(100 - yard_line);
            return try std.fmt.allocPrint(allocator, "Opp {d}", .{line_num});
        }
    }
    
    /// Convert a yard line to a coordinate
    ///
    /// Creates a coordinate from a yard line number and horizontal position.
    /// The yard line is interpreted from the home team's perspective.
    ///
    /// __Parameters__
    ///
    /// - `yard_line`: Yard line number (0-100)
    /// - `x_position`: Horizontal position on the field (0 to FIELD_WIDTH_YARDS)
    ///
    /// __Return__
    ///
    /// - Coordinate at the specified yard line and horizontal position
    pub fn fieldPositionToCoordinate(yard_line: u8, x_position: f32) Coordinate {
        // Convert yard line to y coordinate
        // Add endzone length to get absolute position
        const y_position = @as(f32, @floatFromInt(yard_line)) + END_ZONE_LENGTH_YARDS;
        
        return Coordinate.init(x_position, y_position);
    }