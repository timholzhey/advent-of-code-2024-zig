const std = @import("std");

const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    const directions = [_]Direction{ .Up, .Down, .Left, .Right };

    fn rotateClockwise(self: Direction) Direction {
        return switch (self) {
            .Up => Direction.Right,
            .Down => Direction.Left,
            .Left => Direction.Up,
            .Right => Direction.Down,
        };
    }

    fn rotateAntiClockwise(self: Direction) Direction {
        return switch (self) {
            .Up => Direction.Left,
            .Down => Direction.Right,
            .Left => Direction.Down,
            .Right => Direction.Up,
        };
    }
};

const Position = struct {
    y: i32,
    x: i32,

    fn fromIndex(index: usize, width: usize) Position {
        return .{
            .y = @intCast(index / width),
            .x = @intCast(index % width),
        };
    }

    fn toIndex(self: Position, width: usize) usize {
        return @intCast(self.y * @as(i32, @intCast(width)) + self.x);
    }

    fn isInside(self: Position, width: usize, height: usize) bool {
        return self.y >= 0 and self.x >= 0 and self.y < height and self.x < width;
    }

    fn moveDirection(self: Position, direction: Direction) Position {
        return switch (direction) {
            .Up => .{ .y = self.y - 1, .x = self.x },
            .Down => .{ .y = self.y + 1, .x = self.x },
            .Left => .{ .y = self.y, .x = self.x - 1 },
            .Right => .{ .y = self.y, .x = self.x + 1 },
        };
    }
};

fn floodFillRegionAccumRecurse(input: []const u8, grid_width: usize, grid_height: usize, pos: Position, visited_positions: *[]bool, value: u8) !struct {
    area: u64,
    perimeter: u64,
    num_sides: u64,
} {
    if (!pos.isInside(grid_width, grid_height)) {
        return error.NotPartOfRegion;
    }

    const index = pos.toIndex(grid_width + 1);
    if (input[index] != value) {
        return error.NotPartOfRegion;
    }

    if (visited_positions.*[index]) {
        return .{ .area = 0, .perimeter = 0, .num_sides = 0 };
    }

    visited_positions.*[index] = true;

    var area: u64 = 1;
    var perimeter: u64 = 0;
    var num_sides: u64 = 0;

    for (Direction.directions) |direction| {
        const neighbor_pos = pos.moveDirection(direction);
        const clockwise_next_pos = pos.moveDirection(direction.rotateClockwise());
        const clockwise_forward_pos = neighbor_pos.moveDirection(direction.rotateClockwise());

        const neighbor = floodFillRegionAccumRecurse(input, grid_width, grid_height, neighbor_pos, visited_positions, value) catch {
            perimeter += 1;

            // Outer corner -> Add side
            if (!clockwise_next_pos.isInside(grid_width, grid_height) or input[clockwise_next_pos.toIndex(grid_width + 1)] != value) {
                num_sides += 1;
            }

            continue;
        };

        // Inner corner -> Add side
        if ((clockwise_next_pos.isInside(grid_width, grid_height) and input[clockwise_next_pos.toIndex(grid_width + 1)] == value) and
            (!clockwise_forward_pos.isInside(grid_width, grid_height) or input[clockwise_forward_pos.toIndex(grid_width + 1)] != value))
        {
            num_sides += 1;
        }

        area += neighbor.area;
        perimeter += neighbor.perimeter;
        num_sides += neighbor.num_sides;
    }

    return .{ .area = area, .perimeter = perimeter, .num_sides = num_sides };
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    total_fence_price_perimeter: u64,
    total_fence_price_sides: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const grid_width = std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable;
    const grid_height = std.mem.count(u8, input_trimmed, "\n") + 1;

    var visited_positions = try allocator.alloc(bool, input_trimmed.len);
    defer allocator.free(visited_positions);
    @memset(visited_positions, false);

    // Part 1 & 2
    var total_fence_price_perimeter: u64 = 0;
    var total_fence_price_sides: u64 = 0;
    {
        for (input_trimmed, 0..) |char, index| {
            if (char == '\n') {
                continue;
            }
            if (visited_positions[index]) {
                continue;
            }

            const pos = Position.fromIndex(index, grid_width + 1);
            const region = floodFillRegionAccumRecurse(input_trimmed, grid_width, grid_height, pos, &visited_positions, char) catch unreachable;

            total_fence_price_perimeter += region.area * region.perimeter;
            total_fence_price_sides += region.area * region.num_sides;
        }
    }

    return .{
        .total_fence_price_perimeter = total_fence_price_perimeter,
        .total_fence_price_sides = total_fence_price_sides,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 12 - Part 1: {}\n", .{solution.total_fence_price_perimeter});
    std.debug.print("Day 12 - Part 2: {}\n", .{solution.total_fence_price_sides});
}

test "sample" {
    const solution1 = try solve(std.testing.allocator, @embedFile("sample1.txt"));
    try std.testing.expectEqual(1930, solution1.total_fence_price_perimeter);
    try std.testing.expectEqual(1206, solution1.total_fence_price_sides);

    const solution2 = try solve(std.testing.allocator, @embedFile("sample2.txt"));
    try std.testing.expectEqual(1184, solution2.total_fence_price_perimeter);
    try std.testing.expectEqual(368, solution2.total_fence_price_sides);

    const solution3 = try solve(std.testing.allocator, @embedFile("sample3.txt"));
    try std.testing.expectEqual(644, solution3.total_fence_price_perimeter);
    try std.testing.expectEqual(196, solution3.total_fence_price_sides);
}
