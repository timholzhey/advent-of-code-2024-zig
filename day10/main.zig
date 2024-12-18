const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;

fn scoreTrailheadRecurse(input: []const u8, visited_positions: *[]bool, dimensions: Vec2D(i32), pos: Vec2D(i32), level: u32, distinct: bool) u32 {
    if (!pos.isWithinZeroRect(dimensions)) {
        return 0;
    }

    const index = pos.to2DIndex(@intCast(dimensions.x + 1));
    if ((std.fmt.parseInt(u64, input[index .. index + 1], 10) catch unreachable) != level) {
        return 0;
    }

    if (!distinct and visited_positions.*[index]) {
        return 0;
    }

    if (level == 0) {
        visited_positions.*[index] = true;
        return 1;
    }

    var score: u32 = 0;
    for (Direction.cardinals) |direction| {
        score += scoreTrailheadRecurse(input, visited_positions, dimensions, pos.add(direction.toNormVec2D(i32)), level - 1, distinct);
    }

    visited_positions.*[index] = true;

    return score;
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    sum_trailhead_scores: u64,
    sum_trailhead_ratings: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const dimensions = Vec2D(i32){
        .x = @intCast(std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable),
        .y = @intCast(std.mem.count(u8, input_trimmed, "\n") + 1),
    };

    // Part 1
    var sum_trailhead_scores: u64 = 0;
    {
        var visited_positions = try allocator.alloc(bool, input_trimmed.len);
        defer allocator.free(visited_positions);

        for (input_trimmed, 0..) |char, index| {
            if (char != '9') {
                continue;
            }

            @memset(visited_positions, false);

            const pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));
            sum_trailhead_scores += scoreTrailheadRecurse(input_trimmed, &visited_positions, dimensions, pos, 9, false);
        }
    }

    // Part 2
    var sum_trailhead_ratings: u64 = 0;
    {
        var visited_positions = try allocator.alloc(bool, input_trimmed.len);
        defer allocator.free(visited_positions);

        for (input_trimmed, 0..) |char, index| {
            if (char != '9') {
                continue;
            }

            @memset(visited_positions, false);

            const pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));
            sum_trailhead_ratings += scoreTrailheadRecurse(input_trimmed, &visited_positions, dimensions, pos, 9, true);
        }
    }

    return .{
        .sum_trailhead_scores = sum_trailhead_scores,
        .sum_trailhead_ratings = sum_trailhead_ratings,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 10 - Part 1: {}\n", .{solution.sum_trailhead_scores});
    std.debug.print("Day 10 - Part 2: {}\n", .{solution.sum_trailhead_ratings});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(36, solution.sum_trailhead_scores);
    try std.testing.expectEqual(81, solution.sum_trailhead_ratings);
}
