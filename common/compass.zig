const Vec2D = @import("vectors.zig").Vec2D;

pub const Direction = enum(i8) {
    north = 0,
    north_east = 1,
    east = 2,
    south_east = 3,
    south = 4,
    south_west = 5,
    west = 6,
    north_west = 7,

    pub const cardinals = [_]Direction{ .north, .east, .south, .west };
    pub const ordinals = [_]Direction{ .north_east, .south_east, .south_west, .north_west };
    pub const cardinals_ordinals = [_]Direction{ .north, .north_east, .east, .south_east, .south, .south_west, .west, .north_west };

    pub const RotationDirection = enum(i8) {
        clockwise = 1,
        anti_clockwise = -1,
    };

    pub const RotationStep = enum(i8) {
        eighth = 1,
        quarter = 2,
        half = 4,
        three_quarters = 6,
    };

    pub fn rotate(self: Direction, direction: RotationDirection, step: RotationStep) Direction {
        return cardinals_ordinals[@as(usize, @intCast((@intFromEnum(self) + @intFromEnum(direction) * @intFromEnum(step)))) % cardinals_ordinals.len];
    }

    pub fn opposite(self: Direction) Direction {
        return self.rotate(.clockwise, .half);
    }

    pub fn isHorizontal(self: Direction) bool {
        return self == .east or self == .west;
    }

    pub fn isVertical(self: Direction) bool {
        return self == .north or self == .south;
    }

    pub fn toNormVec2D(self: Direction, comptime T: type) Vec2D(T) {
        return switch (self) {
            .north => .{ .x = 0, .y = -1 },
            .north_east => .{ .x = 1, .y = -1 },
            .east => .{ .x = 1, .y = 0 },
            .south_east => .{ .x = 1, .y = 1 },
            .south => .{ .x = 0, .y = 1 },
            .south_west => .{ .x = -1, .y = 1 },
            .west => .{ .x = -1, .y = 0 },
            .north_west => .{ .x = -1, .y = -1 },
        };
    }
};
