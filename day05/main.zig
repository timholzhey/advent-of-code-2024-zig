const std = @import("std");

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    sum_middle_page_correct_updates: u64,
    sum_middle_page_incorrect_corrected_updates: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    const pos_end_of_ordering_rules = std.mem.indexOf(u8, input_trimmed, "\n\n") orelse unreachable;
    const num_lines_updates = std.mem.count(u8, input_trimmed[pos_end_of_ordering_rules + 2 ..], "\n") + 1;

    var ordering_rules_map = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer {
        var rules_iter = ordering_rules_map.iterator();
        while (rules_iter.next()) |item| {
            item.value_ptr.deinit();
        }
        ordering_rules_map.deinit();
    }

    var ordering_rules_lines_iter = std.mem.tokenizeScalar(u8, input_trimmed[0..pos_end_of_ordering_rules], '\n');
    while (ordering_rules_lines_iter.next()) |line| {
        var columns_iter = std.mem.tokenizeScalar(u8, line, '|');
        const before_page_num = try std.fmt.parseInt(u32, columns_iter.next() orelse unreachable, 10);
        const after_page_num = try std.fmt.parseInt(u32, columns_iter.next() orelse unreachable, 10);

        var rules = ordering_rules_map.getPtr(before_page_num) orelse blk: {
            const new_array_list = std.ArrayList(u32).init(allocator);
            try ordering_rules_map.put(before_page_num, new_array_list);
            break :blk ordering_rules_map.getPtr(before_page_num) orelse unreachable;
        };

        try rules.append(after_page_num);
    }

    var updates = try std.ArrayList(std.ArrayList(u32)).initCapacity(allocator, num_lines_updates);
    defer {
        for (updates.items) |update| {
            update.deinit();
        }
        updates.deinit();
    }

    var updates_lines_iter = std.mem.tokenizeScalar(u8, input_trimmed[pos_end_of_ordering_rules + 2 ..], '\n');
    while (updates_lines_iter.next()) |line| {
        var update = std.ArrayList(u32).init(allocator);

        var columns_iter = std.mem.tokenizeScalar(u8, line, ',');
        while (columns_iter.next()) |column| {
            const page_num = try std.fmt.parseInt(u32, column, 10);
            try update.append(page_num);
        }

        try updates.append(update);
    }

    // Part 1
    var sum_middle_page_correct_updates: u64 = 0;
    for (updates.items) |update| blk: {
        for (update.items, 0..) |page_num, index| {
            const following_pages_for_num = ordering_rules_map.get(page_num) orelse continue;

            // Lookback and check for violated rules
            for (update.items[0..index]) |before_page_num| {
                for (following_pages_for_num.items) |after_page_num| {
                    if (before_page_num == after_page_num) {
                        break :blk;
                    }
                }
            }
        }

        sum_middle_page_correct_updates += update.items[update.items.len / 2];
    }

    // Part 2
    var sum_middle_page_incorrect_corrected_updates: u64 = 0;
    for (updates.items) |update| {
        var do_run = true;
        var was_incorrect = false;

        while (do_run) {
            do_run = false;
            for (update.items, 0..) |page_num, index| blk: {
                const following_pages_for_num = ordering_rules_map.get(page_num) orelse continue;

                // Lookback and check for violated rules
                for (update.items[0..index], 0..) |before_page_num, before_index| {
                    for (following_pages_for_num.items) |after_page_num| {
                        if (before_page_num == after_page_num) {
                            was_incorrect = true;

                            // Swap pages
                            update.items[before_index] = page_num;
                            update.items[index] = before_page_num;

                            // Restart check from the beginning
                            do_run = true;
                            break :blk;
                        }
                    }
                }
            }
        }

        if (!was_incorrect) {
            continue;
        }

        sum_middle_page_incorrect_corrected_updates += update.items[update.items.len / 2];
    }

    return .{
        .sum_middle_page_correct_updates = sum_middle_page_correct_updates,
        .sum_middle_page_incorrect_corrected_updates = sum_middle_page_incorrect_corrected_updates,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 05 - Part 1: {}\n", .{solution.sum_middle_page_correct_updates});
    std.debug.print("Day 05 - Part 2: {}\n", .{solution.sum_middle_page_incorrect_corrected_updates});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(143, solution.sum_middle_page_correct_updates);
    try std.testing.expectEqual(123, solution.sum_middle_page_incorrect_corrected_updates);
}
