const std = @import("std");

inline fn gridGetCharAtPos(grid: []const u8, width: usize, x: i32, y: i32) !u8 {
    if (x < 0 or x >= width or y < 0) {
        return error.OutOfBounds;
    }

    const index: usize = @intCast(y * (@as(i32, @intCast(width)) + 1) + x);
    if (index >= grid.len) {
        return error.OutOfBounds;
    }

    return grid[index];
}

fn solve(_: std.mem.Allocator, input: []const u8) !struct {
    num_xmas_occurences: u64,
    num_mas_in_x_shape: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const grid_width = std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable;

    // Part 1
    var num_xmas_occurences: u32 = 0;
    {
        for (input_trimmed, 0..) |char, index| {
            if (char != 'X') {
                continue;
            }

            const row = index / (grid_width + 1);
            const col = index % (grid_width + 1);

            // Check all 8 directions
            for ([_]i32{ -1, 0, 1 }) |dx| {
                for ([_]i32{ -1, 0, 1 }) |dy| {
                    if (dx == 0 and dy == 0) {
                        continue;
                    }

                    var x: i32 = @intCast(col);
                    var y: i32 = @intCast(row);

                    const rem_chars = "MAS";
                    var found = true;
                    for (rem_chars) |rem_char| {
                        x += dx;
                        y += dy;

                        const next_char = gridGetCharAtPos(input_trimmed, grid_width, x, y) catch {
                            found = false;
                            break;
                        };

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
    }

    // Part 2
    var num_mas_in_x_shape: u32 = 0;
    {
        for (input_trimmed, 0..) |char, index| {
            if (char != 'A') {
                continue;
            }

            const row = index / (grid_width + 1);
            const col = index % (grid_width + 1);

            // Check diagonals
            var found = true;
            for ([_]i32{ -1, 1 }) |dir| {
                const x: i32 = @intCast(col);
                const y: i32 = @intCast(row);

                const char1 = gridGetCharAtPos(input_trimmed, grid_width, x - 1, y - dir) catch {
                    found = false;
                    break;
                };
                const char2 = gridGetCharAtPos(input_trimmed, grid_width, x + 1, y + dir) catch {
                    found = false;
                    break;
                };

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
