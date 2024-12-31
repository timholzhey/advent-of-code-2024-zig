const std = @import("std");
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
        return cardinals_ordinals[@as(usize, @intCast(@mod(@intFromEnum(self) + @intFromEnum(direction) * @intFromEnum(step), @as(i8, @intCast(cardinals_ordinals.len)))))];
    }

    pub fn rotateEither(self: Direction, step: RotationStep) [2]Direction {
        return .{ self.rotate(.clockwise, step), self.rotate(.anti_clockwise, step) };
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

test "rotate" {
    try std.testing.expectEqual(Direction.north_east, Direction.north.rotate(.clockwise, .eighth));
    try std.testing.expectEqual(Direction.north_west, Direction.north.rotate(.anti_clockwise, .eighth));
    try std.testing.expectEqual(Direction.east, Direction.north.rotate(.clockwise, .quarter));
    try std.testing.expectEqual(Direction.west, Direction.north.rotate(.anti_clockwise, .quarter));
    try std.testing.expectEqual(Direction.south, Direction.north.rotate(.clockwise, .half));
    try std.testing.expectEqual(Direction.south, Direction.north.rotate(.anti_clockwise, .half));
    try std.testing.expectEqual(Direction.west, Direction.north.rotate(.clockwise, .three_quarters));
    try std.testing.expectEqual(Direction.east, Direction.north.rotate(.anti_clockwise, .three_quarters));
    try std.testing.expectEqual(Direction.west, Direction.south_west.rotate(.clockwise, .eighth));
    try std.testing.expectEqual(Direction.south, Direction.south_west.rotate(.anti_clockwise, .eighth));
    try std.testing.expectEqual(Direction.north_west, Direction.south_west.rotate(.clockwise, .quarter));
    try std.testing.expectEqual(Direction.south_east, Direction.south_west.rotate(.anti_clockwise, .quarter));
    try std.testing.expectEqual(Direction.north_east, Direction.south_west.rotate(.clockwise, .half));
    try std.testing.expectEqual(Direction.north_east, Direction.south_west.rotate(.anti_clockwise, .half));
    try std.testing.expectEqual(Direction.south_east, Direction.south_west.rotate(.clockwise, .three_quarters));
    try std.testing.expectEqual(Direction.north_west, Direction.south_west.rotate(.anti_clockwise, .three_quarters));
}

test "rotateEither" {
    const northEitherEighth = Direction.north.rotateEither(.eighth);
    try std.testing.expectEqual(Direction.north_east, northEitherEighth[0]);
    try std.testing.expectEqual(Direction.north_west, northEitherEighth[1]);
    const northEitherQuarter = Direction.north.rotateEither(.quarter);
    try std.testing.expectEqual(Direction.east, northEitherQuarter[0]);
    try std.testing.expectEqual(Direction.west, northEitherQuarter[1]);
    const northEitherHalf = Direction.north.rotateEither(.half);
    try std.testing.expectEqual(Direction.south, northEitherHalf[0]);
    try std.testing.expectEqual(Direction.south, northEitherHalf[1]);
    const northEitherThreeQuarters = Direction.north.rotateEither(.three_quarters);
    try std.testing.expectEqual(Direction.west, northEitherThreeQuarters[0]);
    try std.testing.expectEqual(Direction.east, northEitherThreeQuarters[1]);
}
