const std = @import("std");

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct { total_distance: u64, similarity_score: u64 } {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const num_lines = std.mem.count(u8, input_trimmed, "\n") + 1;
    var location_ids_col1 = try std.ArrayList(u32).initCapacity(allocator, num_lines);
    defer location_ids_col1.deinit();
    var location_ids_col2 = try std.ArrayList(u32).initCapacity(allocator, num_lines);
    defer location_ids_col2.deinit();

    var lines_iter = std.mem.tokenizeScalar(u8, input_trimmed, '\n');
    while (lines_iter.next()) |line| {
        var columns_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (columns_iter.next()) |column| {
            const number = try std.fmt.parseInt(u32, column, 10);
            try switch (columns_iter.index - column.len) {
                0 => location_ids_col1.append(number),
                else => location_ids_col2.append(number),
            };
        }
    }

    // Part 1
    std.mem.sort(u32, location_ids_col1.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, location_ids_col2.items, {}, std.sort.asc(u32));

    var total_distance: u64 = 0;
    for (location_ids_col1.items, location_ids_col2.items) |id1, id2| {
        total_distance += @abs(@as(i64, id1) - @as(i64, id2));
    }

    // Part 2
    var similarity_score: u64 = 0;
    var col2_index: usize = 0;
    for (location_ids_col1.items, 0..) |id1, col1_index| {
        var num_occurrences_col2: u32 = 0;
        for (location_ids_col2.items[col2_index..]) |id2| {
            if (id1 == id2) {
                num_occurrences_col2 += 1;
            } else if (id1 < id2) {
                break;
            }
        }
        similarity_score += id1 * num_occurrences_col2;
        if (col1_index + 1 < location_ids_col1.items.len and location_ids_col1.items[col1_index + 1] != id1) {
            col2_index += num_occurrences_col2;
        }
    }

    return .{
        .total_distance = total_distance,
        .similarity_score = similarity_score,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 01 - Part 1: {}\n", .{solution.total_distance});
    std.debug.print("Day 01 - Part 2: {}\n", .{solution.similarity_score});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(11, solution.total_distance);
    try std.testing.expectEqual(31, solution.similarity_score);
}
