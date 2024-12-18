const std = @import("std");

fn scoreTrailheadRecurse(input: []const u8, visited_positions: *[]bool, grid_width: usize, grid_height: usize, row: i32, col: i32, level: u32, distinct: bool) u32 {
    if (row < 0 or row >= grid_height or col < 0 or col >= grid_width) {
        return 0;
    }

    const index: usize = @intCast(row * (@as(i32, @intCast(grid_width)) + 1) + col);
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
    score += scoreTrailheadRecurse(input, visited_positions, grid_width, grid_height, row - 1, col, level - 1, distinct);
    score += scoreTrailheadRecurse(input, visited_positions, grid_width, grid_height, row + 1, col, level - 1, distinct);
    score += scoreTrailheadRecurse(input, visited_positions, grid_width, grid_height, row, col - 1, level - 1, distinct);
    score += scoreTrailheadRecurse(input, visited_positions, grid_width, grid_height, row, col + 1, level - 1, distinct);

    visited_positions.*[index] = true;

    return score;
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    sum_trailhead_scores: u64,
    sum_trailhead_ratings: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const grid_width = std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable;
    const grid_height = std.mem.count(u8, input_trimmed, "\n") + 1;

    // Part 1
    var sum_trailhead_scores: u64 = 0;
    {
        var visited_positions = try allocator.alloc(bool, input_trimmed.len);
        defer allocator.free(visited_positions);

        for (0..input_trimmed.len) |index| {
            const char = input_trimmed[index];

            if (char != '9') {
                continue;
            }

            const row: i32 = @intCast(index / (grid_width + 1));
            const col: i32 = @intCast(index % (grid_width + 1));

            @memset(visited_positions, false);

            sum_trailhead_scores += scoreTrailheadRecurse(input_trimmed, &visited_positions, grid_width, grid_height, row, col, 9, false);
        }
    }

    // Part 2
    var sum_trailhead_ratings: u64 = 0;
    {
        var visited_positions = try allocator.alloc(bool, input_trimmed.len);
        defer allocator.free(visited_positions);

        for (0..input_trimmed.len) |index| {
            const char = input_trimmed[index];

            if (char != '9') {
                continue;
            }

            const row: i32 = @intCast(index / (grid_width + 1));
            const col: i32 = @intCast(index % (grid_width + 1));

            @memset(visited_positions, false);

            sum_trailhead_ratings += scoreTrailheadRecurse(input_trimmed, &visited_positions, grid_width, grid_height, row, col, 9, true);
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
