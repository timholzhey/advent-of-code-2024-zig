const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;
const Direction = @import("common").compass.Direction;

fn solve(_: std.mem.Allocator, input: []const u8) !struct {
    num_xmas_occurences: u64,
    num_mas_in_x_shape: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const dimensions = Vec2D(i32){
        .x = @intCast(std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable),
        .y = @intCast(std.mem.count(u8, input_trimmed, "\n") + 1),
    };

    // Part 1
    var num_xmas_occurences: u32 = 0;
    {
        for (input_trimmed, 0..) |char, index| {
            if (char != 'X') {
                continue;
            }

            // Check all 8 directions
            for (Direction.cardinals_ordinals) |direction| {
                var pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));

                const rem_chars = "MAS";
                var found = true;
                for (rem_chars) |rem_char| {
                    pos = pos.add(direction.toNormVec2D(i32));

                    if (!pos.isWithinZeroRect(dimensions)) {
                        found = false;
                        break;
                    }

                    const next_char = input_trimmed[pos.to2DIndex(@intCast(dimensions.x + 1))];
                    if (next_char != rem_char) {
                        found = false;
                        break;
                    }
                }

                if (found) {
                    num_xmas_occurences += 1;
                }
            }
        }
    }

    // Part 2
    var num_mas_in_x_shape: u32 = 0;
    {
        for (input_trimmed, 0..) |char, index| {
            if (char != 'A') {
                continue;
            }

            // Check diagonals
            var found = true;
            for ([_]Direction{ .north_east, .south_east }) |direction| {
                const pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));

                const diagonal_pos1 = pos.add(direction.toNormVec2D(i32));
                const diagonal_pos2 = pos.add(direction.opposite().toNormVec2D(i32));

                if (!diagonal_pos1.isWithinZeroRect(dimensions) or !diagonal_pos2.isWithinZeroRect(dimensions)) {
                    found = false;
                    break;
                }

                const char1 = input_trimmed[diagonal_pos1.to2DIndex(@intCast(dimensions.x + 1))];
                const char2 = input_trimmed[diagonal_pos2.to2DIndex(@intCast(dimensions.x + 1))];

                if (!((char1 == 'M' and char2 == 'S') or (char1 == 'S' and char2 == 'M'))) {
                    found = false;
                    break;
                }
            }

            if (found) {
                num_mas_in_x_shape += 1;
            }
        }
    }

    return .{
        .num_xmas_occurences = num_xmas_occurences,
        .num_mas_in_x_shape = num_mas_in_x_shape,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 04 - Part 1: {}\n", .{solution.num_xmas_occurences});
    std.debug.print("Day 04 - Part 2: {}\n", .{solution.num_mas_in_x_shape});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(18, solution.num_xmas_occurences);
    try std.testing.expectEqual(9, solution.num_mas_in_x_shape);
}
