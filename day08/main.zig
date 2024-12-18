const std = @import("std");
const Vec2D = @import("common").vectors.Vec2D;

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    num_unique_antinodes_two: u64,
    num_unique_antinodes_multiple: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const dimensions = Vec2D(i32){
        .x = @intCast(std.mem.indexOfScalar(u8, input_trimmed, '\n') orelse unreachable),
        .y = @intCast(std.mem.count(u8, input_trimmed, "\n") + 1),
    };

    var antennas_freq_map = std.AutoHashMap(u8, std.ArrayList(Vec2D(i32))).init(allocator);
    defer {
        var freq_iter = antennas_freq_map.iterator();
        while (freq_iter.next()) |freq| {
            freq.value_ptr.deinit();
        }
        antennas_freq_map.deinit();
    }

    for (input_trimmed, 0..) |char, index| {
        if (std.ascii.isAlphanumeric(char)) {
            const pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));

            var freq = antennas_freq_map.getPtr(char) orelse blk: {
                const new_array_list = std.ArrayList(Vec2D(i32)).init(allocator);
                try antennas_freq_map.put(char, new_array_list);
                break :blk antennas_freq_map.getPtr(char) orelse unreachable;
            };

            try freq.append(pos);
        }
    }

    // Part 1
    var num_unique_antinodes_two: u64 = 0;
    {
        var is_antinode_grid = try allocator.alloc(bool, input_trimmed.len);
        defer allocator.free(is_antinode_grid);
        @memset(is_antinode_grid, false);

        blk: for (input_trimmed, 0..) |char, index| {
            if (char == '\n') continue;

            const pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));

            var freq_iter = antennas_freq_map.iterator();
            while (freq_iter.next()) |freq| {
                for (freq.value_ptr.items) |antenna_pos| {
                    const delta = antenna_pos.sub(pos);

                    if (delta.magSq() == 0) {
                        continue;
                    }

                    const second_antenna_pos = antenna_pos.add(delta);

                    if (!second_antenna_pos.isWithinZeroRect(dimensions)) {
                        continue;
                    }

                    const second_antenna_index: usize = second_antenna_pos.to2DIndex(@intCast(dimensions.x + 1));

                    if (input_trimmed[second_antenna_index] == freq.key_ptr.*) {
                        if (!is_antinode_grid[index]) {
                            num_unique_antinodes_two += 1;
                            is_antinode_grid[index] = true;
                            continue :blk;
                        }
                    }
                }
            }
        }
    }

    // Part 2
    var num_unique_antinodes_multiple: u64 = 0;
    {
        var is_antinode_grid = try allocator.alloc(bool, input_trimmed.len);
        defer allocator.free(is_antinode_grid);
        @memset(is_antinode_grid, false);

        blk: for (input_trimmed, 0..) |char, index| {
            if (char == '\n') continue;

            const pos = Vec2D(i32).from2DIndex(index, @intCast(dimensions.x + 1));

            var freq_iter = antennas_freq_map.iterator();
            while (freq_iter.next()) |freq| {
                for (freq.value_ptr.items) |antenna_pos| {
                    if (antenna_pos.x == pos.x and antenna_pos.y == pos.y) {
                        continue;
                    }

                    var delta = antenna_pos.sub(pos);
                    delta = delta.norm();

                    for ([_]i32{ -1, 1 }) |direction| {
                        var next_antenna_pos = pos;

                        while (true) {
                            next_antenna_pos = delta.norm().mulScalar(direction).add(next_antenna_pos);

                            if (next_antenna_pos.equals(antenna_pos)) {
                                break;
                            }

                            if (!next_antenna_pos.isWithinZeroRect(dimensions)) {
                                break;
                            }

                            const next_antenna_index: usize = next_antenna_pos.to2DIndex(@intCast(dimensions.x + 1));

                            if (input_trimmed[next_antenna_index] != freq.key_ptr.*) {
                                continue;
                            }

                            if (!is_antinode_grid[index]) {
                                num_unique_antinodes_multiple += 1;
                                is_antinode_grid[index] = true;
                                continue :blk;
                            }
                        }
                    }

                    if (input_trimmed[index] == freq.key_ptr.*) {
                        if (!is_antinode_grid[index]) {
                            num_unique_antinodes_multiple += 1;
                            is_antinode_grid[index] = true;
                            continue :blk;
                        }
                    }
                }
            }
        }
    }

    return .{
        .num_unique_antinodes_two = num_unique_antinodes_two,
        .num_unique_antinodes_multiple = num_unique_antinodes_multiple,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 08 - Part 1: {}\n", .{solution.num_unique_antinodes_two});
    std.debug.print("Day 08 - Part 2: {}\n", .{solution.num_unique_antinodes_multiple});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(14, solution.num_unique_antinodes_two);
    try std.testing.expectEqual(34, solution.num_unique_antinodes_multiple);
}
