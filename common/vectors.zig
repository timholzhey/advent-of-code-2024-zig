const std = @import("std");

pub fn Vec2D(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,

        pub fn from2DIndex(index: usize, width: usize) Self {
            return .{
                .x = @intCast(index % width),
                .y = @intCast(index / width),
            };
        }

        pub fn to2DIndex(self: Self, width: usize) usize {
            return @intCast(self.y * @as(T, @intCast(width)) + self.x);
        }

        pub fn norm(self: Self) Self {
            const gcd = std.math.gcd(@abs(self.x), @abs(self.y));
            return .{
                .x = @divTrunc(self.x, @as(T, @intCast(gcd))),
                .y = @divTrunc(self.y, @as(T, @intCast(gcd))),
            };
        }

        pub fn equals(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }

        pub fn add(self: Self, other: Self) Self {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn magSq(self: Self) T {
            return self.x * self.x + self.y * self.y;
        }

        pub fn mulScalar(self: Self, scalar: T) Self {
            return .{
                .x = self.x * scalar,
                .y = self.y * scalar,
            };
        }

        pub fn modVec(self: Self, modulus: Self) Self {
            return .{
                .x = @mod(self.x, modulus.x),
                .y = @mod(self.y, modulus.y),
            };
        }

        pub fn divFloorScalar(self: Self, scalar: T) Self {
            return .{
                .x = @divFloor(self.x, scalar),
                .y = @divFloor(self.y, scalar),
            };
        }

        pub fn divFloorVec(self: Self, other: Self) Self {
            return .{
                .x = @divFloor(self.x, other.x),
                .y = @divFloor(self.y, other.y),
            };
        }

        pub fn isWithinRect(self: Self, min: Self, max: Self) bool {
            return self.x >= min.x and self.y >= min.y and self.x < max.x and self.y < max.y;
        }

        pub fn isWithinZeroRect(self: Self, max: Self) bool {
            return self.x >= 0 and self.y >= 0 and self.x < max.x and self.y < max.y;
        }
    };
}
