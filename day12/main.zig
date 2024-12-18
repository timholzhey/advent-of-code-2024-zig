const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;

fn floodFillRegionAccumRecurse(input: []const u8, dimensions: Vec2D(i32), pos: Vec2D(i32), visited_positions: *[]bool, value: u8) !struct {
    area: u64,
    perimeter: u64,
    num_sides: u64,
} {
    if (!pos.isWithinZeroRect(dimensions)) {
        return error.NotPartOfRegion;
    }

    const index = pos.to2DIndex(@intCast(dimensions.x + 1));
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

    for (Direction.cardinals) |direction| {
        const neighbor_pos = pos.add(direction.toNormVec2D(i32));

        const direction_right = direction.rotate(.clockwise, .quarter);
        const clockwise_next_pos = pos.add(direction_right.toNormVec2D(i32));
        const clockwise_forward_pos = neighbor_pos.add(direction_right.toNormVec2D(i32));

        const neighbor = floodFillRegionAccumRecurse(input, dimensions, neighbor_pos, visited_positions, value) catch {
            perimeter += 1;

            // Outer corner -> Add side
            if (!clockwise_next_pos.isWithinZeroRect(dimensions) or input[clockwise_next_pos.to2DIndex(@intCast(dimensions.x + 1))] != value) {
                num_sides += 1;
            }

            continue;
        };

        // Inner corner -> Add side
        if ((clockwise_next_pos.isWithinZeroRect(dimensions) and input[clockwise_next_pos.to2DIndex(@intCast(dimensions.x + 1))] == value) and
            (!clockwise_forward_pos.isWithinZeroRect(dimensions) or input[clockwise_forward_pos.to2DIndex(@intCast(dimensions.x + 1))] != value))
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

    const dimensions = Vec2D(i32){
        .x = @intCast(std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable),
        .y = @intCast(std.mem.count(u8, input_trimmed, "\n") + 1),
    };

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

            const pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));
            const region = floodFillRegionAccumRecurse(input_trimmed, dimensions, pos, &visited_positions, char) catch unreachable;

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
