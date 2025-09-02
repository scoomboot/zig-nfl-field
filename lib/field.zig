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
    
    // └────────────────────────────────────────────────────────────────────────────┘
    
    // ┌─── Hash Mark Positioning ──────────────────────────────────────────────────┐
    
        /// Distance between hash marks (in yards)
        pub const HASH_SEPARATION_YARDS: f32 = 23.583333;
        
        /// Distance from sideline to nearest hash mark (in yards)
        pub const HASH_FROM_SIDELINE_YARDS: f32 = 14.875;
    
    // └────────────────────────────────────────────────────────────────────────────┘
    
    // ┌─── Conversion Factors ──────────────────────────────────────────────────────┐
    
        /// Yards to feet conversion factor
        pub const YARDS_TO_FEET: f32 = 3.0;
        
        /// Feet to yards conversion factor
        pub const FEET_TO_YARDS: f32 = 0.333333;
    
    // └────────────────────────────────────────────────────────────────────────────┘

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
        
        /// Optional field metadata
        metadata: ?FieldMetadata = null,
        
        /// Dynamic wear areas list
        wear_areas_list: std.ArrayList(WearArea),
        
        /// Owned strings from JSON deserialization (freed on deinit)
        owned_name: ?[]u8 = null,
        owned_stadium_name: ?[]u8 = null,
        owned_team_home: ?[]u8 = null,
        owned_team_away: ?[]u8 = null,
        
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
                .wear_areas_list = std.ArrayList(WearArea).init(allocator),
            };
        }
        
        /// Initialize a field with custom dimensions
        ///
        /// __Parameters__
        ///
        /// - `allocator`: Memory allocator for dynamic operations
        /// - `length`: Total field length including endzones in yards
        /// - `width`: Field width in yards
        /// - `end_zone_length`: Length of each endzone in yards
        ///
        /// __Return__
        ///
        /// - A Field struct with custom dimensions or FieldError.InvalidDimensions
        pub fn initCustom(
            allocator: std.mem.Allocator,
            length: f32,
            width: f32,
            end_zone_length: f32
        ) FieldError!Field {
            // Validate dimensions are positive
            if (length <= 0 or width <= 0 or end_zone_length <= 0) {
                return FieldError.InvalidDimensions;
            }
            
            // Validate endzones don't exceed field length
            if (end_zone_length * 2 >= length) {
                return FieldError.InvalidDimensions;
            }
            
            // Calculate proportional hash marks at 28% and 72% of width
            const hash_from_sideline = width * 0.28;
            
            return Field{
                .allocator = allocator,
                .length = length,
                .width = width,
                .endzone_length = end_zone_length,
                .north_boundary = length,
                .south_boundary = 0.0,
                .east_boundary = width,
                .west_boundary = 0.0,
                .left_hash_x = hash_from_sideline,
                .right_hash_x = width - hash_from_sideline,
                .center_x = width / 2.0,
                .wear_areas_list = std.ArrayList(WearArea).init(allocator),
            };
        }
        
        /// Deinitialize the field and free any allocated resources
        pub fn deinit(self: *Field) void {
            // Free the wear areas list
            self.wear_areas_list.deinit();
            
            // Free owned strings from JSON deserialization
            if (self.owned_name) |str| {
                self.allocator.free(str);
            }
            if (self.owned_stadium_name) |str| {
                self.allocator.free(str);
            }
            if (self.owned_team_home) |str| {
                self.allocator.free(str);
            }
            if (self.owned_team_away) |str| {
                self.allocator.free(str);
            }
        }
        
        /// Reset the field to default NFL dimensions
        ///
        /// Preserves the allocator reference while resetting all dimensions
        /// to standard NFL field values.
        pub fn reset(self: *Field) void {
            const allocator = self.allocator;
            // Clear wear areas before reset
            self.wear_areas_list.deinit();
            
            // Free owned strings before reset
            if (self.owned_name) |str| {
                allocator.free(str);
            }
            if (self.owned_stadium_name) |str| {
                allocator.free(str);
            }
            if (self.owned_team_home) |str| {
                allocator.free(str);
            }
            if (self.owned_team_away) |str| {
                allocator.free(str);
            }
            
            self.* = Field.init(allocator);
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
        
        /// Check if a Coordinate struct is within field boundaries
        ///
        /// __Parameters__
        ///
        /// - `coord`: Coordinate struct to check
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is within field boundaries, `false` otherwise
        pub fn containsCoordinate(self: Field, coord: Coordinate) bool {
            return self.contains(coord.x, coord.y);
        }
        
        /// Check if a coordinate is within the playing field (excludes endzones)
        ///
        /// __Parameters__
        ///
        /// - `coord`: Coordinate to check
        ///
        /// __Return__
        ///
        /// - `true` if coordinate is in playing field (not in endzones), `false` otherwise
        pub fn containsInPlay(self: Field, coord: Coordinate) bool {
            return coord.x >= 0 and coord.x <= self.width and
                   coord.y >= self.endzone_length and 
                   coord.y <= (self.length - self.endzone_length);
        }
        
        /// Check if a rectangular area is entirely within field boundaries
        ///
        /// __Parameters__
        ///
        /// - `top_left`: Top-left corner of the area
        /// - `bottom_right`: Bottom-right corner of the area
        ///
        /// __Return__
        ///
        /// - `true` if entire area is within field boundaries, `false` otherwise
        pub fn containsArea(self: Field, top_left: Coordinate, bottom_right: Coordinate) bool {
            // Check both corners are within bounds
            if (!self.containsCoordinate(top_left) or !self.containsCoordinate(bottom_right)) {
                return false;
            }
            
            // Validate area dimensions: bottom_right.x > top_left.x (east of) and top_left.y > bottom_right.y (north of)
            if (bottom_right.x <= top_left.x or bottom_right.y >= top_left.y) {
                return false;
            }
            
            return true;
        }
        
        /// Check if a line segment is entirely within field boundaries
        ///
        /// __Parameters__
        ///
        /// - `start`: Starting coordinate of the line
        /// - `end`: Ending coordinate of the line
        ///
        /// __Return__
        ///
        /// - `true` if entire line is within field boundaries, `false` otherwise
        pub fn containsLine(self: Field, start: Coordinate, end: Coordinate) bool {
            // Check endpoints first
            if (!self.containsCoordinate(start) or !self.containsCoordinate(end)) {
                return false;
            }
            
            // For a line to be contained, we need to check if it crosses boundaries
            // Since the field is a rectangle, if both endpoints are inside,
            // the entire line is inside (convex shape property)
            return true;
        }
        
        /// Get the type of boundary violation for a coordinate
        ///
        /// __Parameters__
        ///
        /// - `coord`: Coordinate to check
        ///
        /// __Return__
        ///
        /// - BoundaryViolation enum if coordinate is out of bounds, null if within bounds
        pub fn getBoundaryViolation(self: Field, coord: Coordinate) ?BoundaryViolation {
            // Check west boundary first
            if (coord.x < self.west_boundary) {
                return .west_out_of_bounds;
            }
            
            // Check east boundary
            if (coord.x > self.east_boundary) {
                return .east_out_of_bounds;
            }
            
            // Check south boundary
            if (coord.y < self.south_boundary) {
                return .south_out_of_bounds;
            }
            
            // Check north boundary
            if (coord.y > self.north_boundary) {
                return .north_out_of_bounds;
            }
            
            // Coordinate is within bounds
            return null;
        }
        
        /// Calculate minimum distance from coordinate to any field boundary
        ///
        /// __Parameters__
        ///
        /// - `coord`: Coordinate to measure from
        ///
        /// __Return__
        ///
        /// - Minimum distance to nearest boundary in yards (negative if outside)
        pub fn distanceToBoundary(self: Field, coord: Coordinate) f32 {
            // Calculate distances to each boundary
            const dist_west = coord.x - self.west_boundary;
            const dist_east = self.east_boundary - coord.x;
            const dist_south = coord.y - self.south_boundary;
            const dist_north = self.north_boundary - coord.y;
            
            // Find minimum distance (negative values indicate outside boundary)
            var min_dist = dist_west;
            min_dist = @min(min_dist, dist_east);
            min_dist = @min(min_dist, dist_south);
            min_dist = @min(min_dist, dist_north);
            
            return min_dist;
        }
        
        /// Calculate minimum distance from coordinate to either sideline
        ///
        /// __Parameters__
        ///
        /// - `coord`: Coordinate to measure from
        ///
        /// __Return__
        ///
        /// - Distance to nearest sideline in yards (negative if outside field width)
        pub fn distanceToSideline(self: Field, coord: Coordinate) f32 {
            // Calculate distances to both sidelines
            const dist_west = coord.x - self.west_boundary;
            const dist_east = self.east_boundary - coord.x;
            
            // Return the minimum distance
            return @min(dist_west, dist_east);
        }
        
        /// Calculate minimum distance from coordinate to nearest endzone
        ///
        /// __Parameters__
        ///
        /// - `coord`: Coordinate to measure from
        ///
        /// __Return__
        ///
        /// - Distance to nearest endzone in yards (negative if inside an endzone)
        pub fn distanceToEndZone(self: Field, coord: Coordinate) f32 {
            // If in home endzone, distance is negative
            if (coord.y < self.endzone_length) {
                return coord.y - self.endzone_length;
            }
            
            // If in away endzone, distance is negative
            const away_endzone_start = self.length - self.endzone_length;
            if (coord.y > away_endzone_start) {
                return away_endzone_start - coord.y;
            }
            
            // In playing field, calculate distance to nearest endzone boundary
            const dist_to_home = coord.y - self.endzone_length;
            const dist_to_away = away_endzone_start - coord.y;
            
            return @min(dist_to_home, dist_to_away);
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
        
        // ┌─── Metadata Management ────────────────────────────────────────────────────┐
        
            /// Sets field metadata.
            ///
            /// __Parameters__
            ///
            /// - `metadata`: FieldMetadata struct to associate with this field
            pub fn setMetadata(self: *Field, metadata: FieldMetadata) void {
                self.metadata = metadata;
                // Clear existing wear areas list and copy from metadata
                self.wear_areas_list.clearRetainingCapacity();
                for (metadata.wear_areas) |area| {
                    self.wear_areas_list.append(area) catch {};
                }
            }
            
            /// Gets current field condition multiplier.
            ///
            /// __Return__
            ///
            /// - Field condition multiplier (0.0 to 1.0), defaults to 1.0 if no metadata
            pub fn getConditionMultiplier(self: Field) f32 {
                if (self.metadata) |meta| {
                    return meta.field_condition.toMultiplier();
                }
                return 1.0;
            }
            
            /// Checks if weather affects play.
            ///
            /// __Return__
            ///
            /// - `true` if weather conditions are impactful, `false` otherwise
            pub fn hasWeatherImpact(self: Field) bool {
                if (self.metadata) |meta| {
                    const weather = meta.weather;
                    return weather.wind_speed_mph > 15.0 or
                           weather.precipitation != .none or
                           weather.temperature_fahrenheit < 32.0 or
                           weather.temperature_fahrenheit > 95.0;
                }
                return false;
            }
            
            /// Gets wind vector for ball physics.
            ///
            /// __Return__
            ///
            /// - Wind vector with x and y components normalized to 0-1 range
            pub fn getWindVector(self: Field) struct { x: f32, y: f32 } {
                if (self.metadata) |meta| {
                    const weather = meta.weather;
                    const wind_rad = weather.wind_direction_degrees * std.math.pi / 180.0;
                    const wind_factor = weather.wind_speed_mph / 50.0; // Normalize to 0-1
                    
                    return .{
                        .x = @sin(wind_rad) * wind_factor,
                        .y = @cos(wind_rad) * wind_factor,
                    };
                }
                return .{ .x = 0.0, .y = 0.0 };
            }
            
            /// Adds a wear area to the field.
            ///
            /// __Parameters__
            ///
            /// - `center`: Center coordinate of the wear area
            /// - `radius`: Radius of the wear area in yards
            /// - `severity`: Wear severity from 0.0 (no wear) to 1.0 (completely worn)
            ///
            /// __Return__
            ///
            /// - Error if allocation fails
            pub fn addWearArea(
                self: *Field,
                center: Coordinate,
                radius: f32,
                severity: f32,
            ) !void {
                const wear_area = WearArea{
                    .center = center,
                    .radius = radius,
                    .severity = std.math.clamp(severity, 0.0, 1.0),
                };
                
                try self.wear_areas_list.append(wear_area);
                
                // Update metadata if present
                if (self.metadata) |*meta| {
                    meta.wear_areas = self.wear_areas_list.items;
                }
            }
            
            /// Gets field condition at a specific coordinate.
            ///
            /// __Parameters__
            ///
            /// - `coord`: Coordinate to check condition at
            ///
            /// __Return__
            ///
            /// - Condition multiplier at the coordinate (0.0 to 1.0)
            pub fn getConditionAt(self: Field, coord: Coordinate) f32 {
                var condition = self.getConditionMultiplier();
                
                // Check wear areas
                const wear_areas = if (self.metadata) |meta| meta.wear_areas else self.wear_areas_list.items;
                for (wear_areas) |area| {
                    const dist = std.math.sqrt(
                        std.math.pow(f32, coord.x - area.center.x, 2) +
                        std.math.pow(f32, coord.y - area.center.y, 2)
                    );
                    
                    if (dist <= area.radius) {
                        const wear_factor = 1.0 - (dist / area.radius);
                        condition *= (1.0 - (area.severity * wear_factor));
                    }
                }
                
                return condition;
            }
            
            /// Serialize field metadata to JSON
            ///
            /// Converts the field's metadata into a JSON string that can be saved or transmitted.
            /// The metadata is converted to a simplified format compatible with std.json.
            ///
            /// __Parameters__
            ///
            /// - `allocator`: Memory allocator for JSON string creation
            ///
            /// __Return__
            ///
            /// - JSON string containing serialized metadata, or error if serialization fails
            /// - Returns error.NoMetadata if field has no metadata set
            /// - Caller owns the returned memory
            pub fn serializeMetadata(self: Field, allocator: std.mem.Allocator) ![]u8 {
                // Check if metadata exists
                const metadata = self.metadata orelse return error.NoMetadata;
                
                // Create array for wear areas
                var wear_areas = try allocator.alloc(SerializableWearArea, self.wear_areas_list.items.len);
                defer allocator.free(wear_areas);
                
                for (self.wear_areas_list.items, 0..) |area, i| {
                    wear_areas[i] = SerializableWearArea{
                        .center_x = area.center.x,
                        .center_y = area.center.y,
                        .radius = area.radius,
                        .severity = area.severity,
                    };
                }
                
                // Convert precipitation enum to string
                const precipitation_str = switch (metadata.weather.precipitation) {
                    .none => "none",
                    .light_rain => "light_rain",
                    .heavy_rain => "heavy_rain",
                    .snow => "snow",
                    .sleet => "sleet",
                    .fog => "fog",
                };
                
                // Convert field condition enum to string
                const condition_str = switch (metadata.field_condition) {
                    .excellent => "excellent",
                    .good => "good",
                    .fair => "fair",
                    .poor => "poor",
                    .unplayable => "unplayable",
                };
                
                // Create serializable structure
                const serializable = SerializableMetadata{
                    .stadium_name = metadata.stadium_name,
                    .team_home = metadata.team_home,
                    .team_away = metadata.team_away,
                    .temperature_fahrenheit = metadata.weather.temperature_fahrenheit,
                    .wind_speed_mph = metadata.weather.wind_speed_mph,
                    .wind_direction_degrees = metadata.weather.wind_direction_degrees,
                    .precipitation = precipitation_str,
                    .humidity_percent = metadata.weather.humidity_percent,
                    .field_condition = condition_str,
                    .wear_areas = wear_areas,
                    .game_time = metadata.game_time,
                    .attendance = metadata.attendance,
                    .has_dome = metadata.has_dome,
                    .has_retractable_roof = metadata.has_retractable_roof,
                    .elevation_feet = metadata.elevation_feet,
                };
                
                // Serialize to JSON
                var json_buffer = std.ArrayList(u8).init(allocator);
                defer json_buffer.deinit();
                
                try std.json.stringify(serializable, .{ .whitespace = .indent_2 }, json_buffer.writer());
                
                // Return owned copy of the JSON string
                return try json_buffer.toOwnedSlice();
            }
            
            /// Deserialize field metadata from JSON
            ///
            /// Parses a JSON string and updates the field's metadata with the deserialized values.
            /// The JSON must match the structure produced by serializeMetadata.
            ///
            /// __Parameters__
            ///
            /// - `json_str`: JSON string containing serialized metadata
            /// - `allocator`: Memory allocator for creating metadata structures
            ///
            /// __Return__
            ///
            /// - void on success, or error if deserialization fails
            pub fn deserializeMetadata(self: *Field, json_str: []const u8, allocator: std.mem.Allocator) !void {
                // Parse JSON
                const parsed = try std.json.parseFromSlice(
                    SerializableMetadata,
                    allocator,
                    json_str,
                    .{ .allocate = .alloc_always }
                );
                defer parsed.deinit();
                
                const serializable = parsed.value;
                
                // Free any existing owned strings
                if (self.owned_stadium_name) |str| {
                    self.allocator.free(str);
                    self.owned_stadium_name = null;
                }
                if (self.owned_team_home) |str| {
                    self.allocator.free(str);
                    self.owned_team_home = null;
                }
                if (self.owned_team_away) |str| {
                    self.allocator.free(str);
                    self.owned_team_away = null;
                }
                
                // Duplicate strings that need to persist beyond JSON parser lifetime
                const stadium_name_dup = try self.allocator.dupe(u8, serializable.stadium_name);
                const team_home_dup = try self.allocator.dupe(u8, serializable.team_home);
                const team_away_dup = try self.allocator.dupe(u8, serializable.team_away);
                
                // Store owned strings for later cleanup
                self.owned_stadium_name = stadium_name_dup;
                self.owned_team_home = team_home_dup;
                self.owned_team_away = team_away_dup;
                
                // Convert precipitation string to enum
                const precipitation = if (std.mem.eql(u8, serializable.precipitation, "none"))
                    Precipitation.none
                else if (std.mem.eql(u8, serializable.precipitation, "light_rain"))
                    Precipitation.light_rain
                else if (std.mem.eql(u8, serializable.precipitation, "heavy_rain"))
                    Precipitation.heavy_rain
                else if (std.mem.eql(u8, serializable.precipitation, "snow"))
                    Precipitation.snow
                else if (std.mem.eql(u8, serializable.precipitation, "sleet"))
                    Precipitation.sleet
                else if (std.mem.eql(u8, serializable.precipitation, "fog"))
                    Precipitation.fog
                else
                    Precipitation.none;
                
                // Convert field condition string to enum
                const field_condition = if (std.mem.eql(u8, serializable.field_condition, "excellent"))
                    FieldCondition.excellent
                else if (std.mem.eql(u8, serializable.field_condition, "good"))
                    FieldCondition.good
                else if (std.mem.eql(u8, serializable.field_condition, "fair"))
                    FieldCondition.fair
                else if (std.mem.eql(u8, serializable.field_condition, "poor"))
                    FieldCondition.poor
                else if (std.mem.eql(u8, serializable.field_condition, "unplayable"))
                    FieldCondition.unplayable
                else
                    FieldCondition.good;
                
                // Clear existing wear areas
                self.wear_areas_list.clearRetainingCapacity();
                
                // Convert wear areas back to internal format
                for (serializable.wear_areas) |area| {
                    try self.wear_areas_list.append(WearArea{
                        .center = Coordinate.init(area.center_x, area.center_y),
                        .radius = area.radius,
                        .severity = area.severity,
                    });
                }
                
                // Create new metadata structure with duplicated strings
                const metadata = FieldMetadata{
                    .stadium_name = stadium_name_dup,
                    .team_home = team_home_dup,
                    .team_away = team_away_dup,
                    .weather = WeatherConditions{
                        .temperature_fahrenheit = serializable.temperature_fahrenheit,
                        .wind_speed_mph = serializable.wind_speed_mph,
                        .wind_direction_degrees = serializable.wind_direction_degrees,
                        .precipitation = precipitation,
                        .humidity_percent = serializable.humidity_percent,
                    },
                    .field_condition = field_condition,
                    .wear_areas = self.wear_areas_list.items,
                    .game_time = serializable.game_time,
                    .attendance = serializable.attendance,
                    .has_dome = serializable.has_dome,
                    .has_retractable_roof = serializable.has_retractable_roof,
                    .elevation_feet = serializable.elevation_feet,
                };
                
                // Update field metadata
                self.metadata = metadata;
            }
            
            /// Export field configuration to JSON
            ///
            /// Exports the complete field configuration including dimensions, surface type,
            /// and metadata (if present) to a JSON string.
            ///
            /// __Parameters__
            ///
            /// - `allocator`: Memory allocator for JSON string creation
            ///
            /// __Return__
            ///
            /// - JSON string containing complete field configuration
            /// - Caller owns the returned memory
            pub fn exportToJson(self: Field, allocator: std.mem.Allocator) ![]u8 {
                // Create a structure that includes both field properties and metadata
                const FieldExport = struct {
                    // Basic field properties
                    name: []const u8,
                    width: f32,
                    length: f32,
                    endzone_length: f32,
                    surface_type: []const u8,
                    
                    // Boundaries
                    north_boundary: f32,
                    south_boundary: f32,
                    east_boundary: f32,
                    west_boundary: f32,
                    
                    // Hash marks
                    left_hash_x: f32,
                    right_hash_x: f32,
                    center_x: f32,
                    
                    // Optional metadata (as nested JSON object)
                    metadata: ?SerializableMetadata,
                };
                
                // Convert surface type enum to string
                const surface_str = switch (self.surface_type) {
                    .grass => "grass",
                    .turf => "turf",
                    .hybrid => "hybrid",
                };
                
                // Prepare metadata if present
                var metadata_export: ?SerializableMetadata = null;
                var wear_areas_buf: []SerializableWearArea = &.{};
                defer if (wear_areas_buf.len > 0) allocator.free(wear_areas_buf);
                
                if (self.metadata) |meta| {
                    // Create wear areas array
                    wear_areas_buf = try allocator.alloc(SerializableWearArea, self.wear_areas_list.items.len);
                    
                    for (self.wear_areas_list.items, 0..) |area, i| {
                        wear_areas_buf[i] = SerializableWearArea{
                            .center_x = area.center.x,
                            .center_y = area.center.y,
                            .radius = area.radius,
                            .severity = area.severity,
                        };
                    }
                    
                    // Convert enums to strings
                    const precipitation_str = switch (meta.weather.precipitation) {
                        .none => "none",
                        .light_rain => "light_rain",
                        .heavy_rain => "heavy_rain",
                        .snow => "snow",
                        .sleet => "sleet",
                        .fog => "fog",
                    };
                    
                    const condition_str = switch (meta.field_condition) {
                        .excellent => "excellent",
                        .good => "good",
                        .fair => "fair",
                        .poor => "poor",
                        .unplayable => "unplayable",
                    };
                    
                    metadata_export = SerializableMetadata{
                        .stadium_name = meta.stadium_name,
                        .team_home = meta.team_home,
                        .team_away = meta.team_away,
                        .temperature_fahrenheit = meta.weather.temperature_fahrenheit,
                        .wind_speed_mph = meta.weather.wind_speed_mph,
                        .wind_direction_degrees = meta.weather.wind_direction_degrees,
                        .precipitation = precipitation_str,
                        .humidity_percent = meta.weather.humidity_percent,
                        .field_condition = condition_str,
                        .wear_areas = wear_areas_buf,
                        .game_time = meta.game_time,
                        .attendance = meta.attendance,
                        .has_dome = meta.has_dome,
                        .has_retractable_roof = meta.has_retractable_roof,
                        .elevation_feet = meta.elevation_feet,
                    };
                }
                
                // Create export structure
                const field_export = FieldExport{
                    .name = self.name,
                    .width = self.width,
                    .length = self.length,
                    .endzone_length = self.endzone_length,
                    .surface_type = surface_str,
                    .north_boundary = self.north_boundary,
                    .south_boundary = self.south_boundary,
                    .east_boundary = self.east_boundary,
                    .west_boundary = self.west_boundary,
                    .left_hash_x = self.left_hash_x,
                    .right_hash_x = self.right_hash_x,
                    .center_x = self.center_x,
                    .metadata = metadata_export,
                };
                
                // Serialize to JSON
                var json_buffer = std.ArrayList(u8).init(allocator);
                defer json_buffer.deinit();
                
                try std.json.stringify(field_export, .{ .whitespace = .indent_2 }, json_buffer.writer());
                
                return try json_buffer.toOwnedSlice();
            }
        
        // └────────────────────────────────────────────────────────────────────────┘
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
    
    /// Boundary violation types for coordinate checking
    pub const BoundaryViolation = enum {
        /// Coordinate is west (left) of field boundary
        west_out_of_bounds,
        
        /// Coordinate is east (right) of field boundary
        east_out_of_bounds,
        
        /// Coordinate is south (bottom) of field boundary
        south_out_of_bounds,
        
        /// Coordinate is north (top) of field boundary
        north_out_of_bounds,
    };

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                                   FIELD METADATA                                   ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

    /// Field metadata containing additional properties and state.
    pub const FieldMetadata = struct {
        // Field identification
        stadium_name: []const u8 = "Generic Stadium",
        team_home: []const u8 = "",
        team_away: []const u8 = "",
        
        // Weather conditions
        weather: WeatherConditions = .{},
        
        // Field conditions
        field_condition: FieldCondition = .good,
        wear_areas: []WearArea = &.{},
        
        // Game information
        game_time: ?i64 = null,
        attendance: ?u32 = null,
        
        // Field features
        has_dome: bool = false,
        has_retractable_roof: bool = false,
        elevation_feet: f32 = 0.0,
    };
    
    /// Weather conditions affecting the field.
    pub const WeatherConditions = struct {
        temperature_fahrenheit: f32 = 70.0,
        wind_speed_mph: f32 = 0.0,
        wind_direction_degrees: f32 = 0.0, // 0 = North, 90 = East
        precipitation: Precipitation = .none,
        humidity_percent: f32 = 50.0,
    };
    
    /// Types of precipitation.
    pub const Precipitation = enum {
        none,
        light_rain,
        heavy_rain,
        snow,
        sleet,
        fog,
    };
    
    /// Field condition states.
    pub const FieldCondition = enum {
        excellent,
        good,
        fair,
        poor,
        unplayable,
        
        /// Convert field condition to a performance multiplier
        ///
        /// __Return__
        ///
        /// - Multiplier value from 0.0 (unplayable) to 1.0 (excellent)
        pub fn toMultiplier(self: FieldCondition) f32 {
            return switch (self) {
                .excellent => 1.0,
                .good => 0.95,
                .fair => 0.85,
                .poor => 0.70,
                .unplayable => 0.0,
            };
        }
    };
    
    /// Areas of field wear.
    pub const WearArea = struct {
        center: Coordinate,
        radius: f32,
        severity: f32, // 0.0 = no wear, 1.0 = completely worn
    };

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                                   FIELD BUILDER                                    ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

    /// Builder pattern for constructing Field instances with fluent API
    pub const FieldBuilder = struct {
        /// Field being constructed
        field: Field,
        
        /// Initialize a new field builder with default NFL dimensions
        ///
        /// __Parameters__
        ///
        /// - `allocator`: Memory allocator for the field
        ///
        /// __Return__
        ///
        /// - A new FieldBuilder instance
        pub fn init(allocator: std.mem.Allocator) FieldBuilder {
            return FieldBuilder{
                .field = Field.init(allocator),
            };
        }
        
        /// Set the field name
        ///
        /// __Parameters__
        ///
        /// - `name`: Name for the field
        ///
        /// __Return__
        ///
        /// - Pointer to this builder for method chaining
        pub fn setName(self: *FieldBuilder, name: []const u8) *FieldBuilder {
            self.field.name = name;
            return self;
        }
        
        /// Set the surface type
        ///
        /// __Parameters__
        ///
        /// - `surface`: Type of playing surface
        ///
        /// __Return__
        ///
        /// - Pointer to this builder for method chaining
        pub fn setSurface(self: *FieldBuilder, surface: SurfaceType) *FieldBuilder {
            self.field.surface_type = surface;
            return self;
        }
        
        /// Set custom field dimensions
        ///
        /// __Parameters__
        ///
        /// - `length`: Total field length including endzones in yards
        /// - `width`: Field width in yards
        ///
        /// __Return__
        ///
        /// - Pointer to this builder for method chaining, or FieldError.InvalidDimensions
        pub fn setDimensions(self: *FieldBuilder, length: f32, width: f32) FieldError!*FieldBuilder {
            // Validate dimensions are positive
            if (length <= 0 or width <= 0) {
                return FieldError.InvalidDimensions;
            }
            
            // Validate endzones don't exceed field length (using current endzone_length)
            if (self.field.endzone_length * 2 >= length) {
                return FieldError.InvalidDimensions;
            }
            
            // Update dimensions
            self.field.length = length;
            self.field.width = width;
            
            // Update boundaries
            self.field.north_boundary = length;
            self.field.east_boundary = width;
            
            // Recalculate proportional hash marks at 28% and 72% of width
            const hash_from_sideline = width * 0.28;
            self.field.left_hash_x = hash_from_sideline;
            self.field.right_hash_x = width - hash_from_sideline;
            
            // Update center position
            self.field.center_x = width / 2.0;
            
            return self;
        }
        
        /// Build and return the configured field
        ///
        /// __Return__
        ///
        /// - The configured Field instance
        pub fn build(self: FieldBuilder) Field {
            return self.field;
        }
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

// ╔═══════════════════════════════════════════════════════════════════════════════════╗
// ║                             METADATA SERIALIZATION                                 ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

    /// Simplified wear area structure for JSON serialization
    pub const SerializableWearArea = struct {
        center_x: f32,
        center_y: f32,
        radius: f32,
        severity: f32,
    };

    /// Simplified metadata structure for JSON serialization
    ///
    /// This structure is designed to be compatible with Zig's std.json serialization.
    /// It uses only basic types that can be directly serialized without custom handlers.
    pub const SerializableMetadata = struct {
        // Field identification
        stadium_name: []const u8,
        team_home: []const u8,
        team_away: []const u8,
        
        // Weather conditions (flattened)
        temperature_fahrenheit: f32,
        wind_speed_mph: f32,
        wind_direction_degrees: f32,
        precipitation: []const u8,  // String representation of enum
        humidity_percent: f32,
        
        // Field conditions
        field_condition: []const u8,  // String representation of enum
        
        // Wear areas (simplified array)
        wear_areas: []SerializableWearArea,
        
        // Game information
        game_time: ?i64,
        attendance: ?u32,
        
        // Field features
        has_dome: bool,
        has_retractable_roof: bool,
        elevation_feet: f32,
    };
    
    /// Import field configuration from JSON
    ///
    /// Creates a field instance from a JSON string containing
    /// field configuration and optional metadata.
    ///
    /// __Parameters__
    ///
    /// - `allocator`: Memory allocator for field creation
    /// - `json_str`: JSON string containing field configuration
    ///
    /// __Return__
    ///
    /// - Configured Field instance, or error if import fails
    pub fn importFromJson(allocator: std.mem.Allocator, json_str: []const u8) !Field {
        // Define import structure matching export format
        const FieldImport = struct {
            name: []const u8,
            width: f32,
            length: f32,
            endzone_length: f32,
            surface_type: []const u8,
            north_boundary: f32,
            south_boundary: f32,
            east_boundary: f32,
            west_boundary: f32,
            left_hash_x: f32,
            right_hash_x: f32,
            center_x: f32,
            metadata: ?SerializableMetadata,
        };
        
        // Parse JSON
        const parsed = try std.json.parseFromSlice(
            FieldImport,
            allocator,
            json_str,
            .{ .allocate = .alloc_always }
        );
        defer parsed.deinit();
        
        const import = parsed.value;
        
        // Convert surface type string to enum
        const surface_type = if (std.mem.eql(u8, import.surface_type, "grass"))
            SurfaceType.grass
        else if (std.mem.eql(u8, import.surface_type, "turf"))
            SurfaceType.turf
        else if (std.mem.eql(u8, import.surface_type, "hybrid"))
            SurfaceType.hybrid
        else
            SurfaceType.turf;
        
        // Duplicate the name string to persist beyond JSON parser lifetime
        const name_dup = try allocator.dupe(u8, import.name);
        
        // Create field with imported dimensions
        var field = Field{
            .allocator = allocator,
            .name = name_dup,
            .owned_name = name_dup,  // Track ownership for cleanup
            .width = import.width,
            .length = import.length,
            .endzone_length = import.endzone_length,
            .surface_type = surface_type,
            .north_boundary = import.north_boundary,
            .south_boundary = import.south_boundary,
            .east_boundary = import.east_boundary,
            .west_boundary = import.west_boundary,
            .left_hash_x = import.left_hash_x,
            .right_hash_x = import.right_hash_x,
            .center_x = import.center_x,
            .wear_areas_list = std.ArrayList(WearArea).init(allocator),
            .metadata = null,
        };
        
        // Import metadata if present
        if (import.metadata) |meta_import| {
            // Convert wear areas
            for (meta_import.wear_areas) |area| {
                try field.wear_areas_list.append(WearArea{
                    .center = Coordinate.init(area.center_x, area.center_y),
                    .radius = area.radius,
                    .severity = area.severity,
                });
            }
            
            // Convert precipitation string to enum
            const precipitation = if (std.mem.eql(u8, meta_import.precipitation, "none"))
                Precipitation.none
            else if (std.mem.eql(u8, meta_import.precipitation, "light_rain"))
                Precipitation.light_rain
            else if (std.mem.eql(u8, meta_import.precipitation, "heavy_rain"))
                Precipitation.heavy_rain
            else if (std.mem.eql(u8, meta_import.precipitation, "snow"))
                Precipitation.snow
            else if (std.mem.eql(u8, meta_import.precipitation, "sleet"))
                Precipitation.sleet
            else if (std.mem.eql(u8, meta_import.precipitation, "fog"))
                Precipitation.fog
            else
                Precipitation.none;
            
            // Convert field condition string to enum
            const field_condition = if (std.mem.eql(u8, meta_import.field_condition, "excellent"))
                FieldCondition.excellent
            else if (std.mem.eql(u8, meta_import.field_condition, "good"))
                FieldCondition.good
            else if (std.mem.eql(u8, meta_import.field_condition, "fair"))
                FieldCondition.fair
            else if (std.mem.eql(u8, meta_import.field_condition, "poor"))
                FieldCondition.poor
            else if (std.mem.eql(u8, meta_import.field_condition, "unplayable"))
                FieldCondition.unplayable
            else
                FieldCondition.good;
            
            // Duplicate metadata strings to persist beyond JSON parser lifetime
            const stadium_name_dup = try allocator.dupe(u8, meta_import.stadium_name);
            const team_home_dup = try allocator.dupe(u8, meta_import.team_home);
            const team_away_dup = try allocator.dupe(u8, meta_import.team_away);
            
            // Track ownership for cleanup
            field.owned_stadium_name = stadium_name_dup;
            field.owned_team_home = team_home_dup;
            field.owned_team_away = team_away_dup;
            
            // Set metadata with duplicated strings
            field.metadata = FieldMetadata{
                .stadium_name = stadium_name_dup,
                .team_home = team_home_dup,
                .team_away = team_away_dup,
                .weather = WeatherConditions{
                    .temperature_fahrenheit = meta_import.temperature_fahrenheit,
                    .wind_speed_mph = meta_import.wind_speed_mph,
                    .wind_direction_degrees = meta_import.wind_direction_degrees,
                    .precipitation = precipitation,
                    .humidity_percent = meta_import.humidity_percent,
                },
                .field_condition = field_condition,
                .wear_areas = field.wear_areas_list.items,
                .game_time = meta_import.game_time,
                .attendance = meta_import.attendance,
                .has_dome = meta_import.has_dome,
                .has_retractable_roof = meta_import.has_retractable_roof,
                .elevation_feet = meta_import.elevation_feet,
            };
        }
        
        return field;
    }
