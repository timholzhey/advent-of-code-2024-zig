const std = @import("std");

const StonesList = std.DoublyLinkedList(u64);

inline fn stoneMapIncCountPut(stone_map: *std.AutoHashMap(u64, u64), stone_num: u64, count: u64) !void {
    const res = try stone_map.getOrPut(stone_num);
    if (res.found_existing) {
        res.value_ptr.* += count;
    } else {
        res.value_ptr.* = count;
    }
}

inline fn stoneMapDecCountDrop(stone_map: *std.AutoHashMap(u64, u64), stone_num: u64, count: u64) !void {
    const res = stone_map.getPtr(stone_num) orelse unreachable;
    res.* -= count;
    if (res.* == 0) {
        _ = stone_map.remove(stone_num);
    }
}

fn evolveStoneDistribution(stone_map: *std.AutoHashMap(u64, u64), generations: u32) !void {
    for (0..generations) |_| {
        var stone_map_init = try stone_map.clone();
        defer stone_map_init.deinit();

        var stone_iter = stone_map_init.iterator();

        while (stone_iter.next()) |stone| {
            const stone_num = stone.key_ptr.*;
            const stone_count = stone.value_ptr.*;

            // 0 -> 1
            if (stone_num == 0) {
                try stoneMapDecCountDrop(stone_map, stone_num, stone_count);
                try stoneMapIncCountPut(stone_map, 1, stone_count);
                continue;
            }

            const num_digits = std.math.log10_int(stone_num) + 1;

            // Odd number of digits -> Multiply by 2024
            if (num_digits % 2 != 0) {
                try stoneMapDecCountDrop(stone_map, stone_num, stone_count);
                try stoneMapIncCountPut(stone_map, stone_num * 2024, stone_count);
                continue;
            }

            var num_buffer: [32]u8 = undefined;
            const num_str = try std.fmt.bufPrint(&num_buffer, "{}", .{stone_num});

            const left_half_num = try std.fmt.parseInt(u64, num_str[0 .. num_digits / 2], 10);
            const right_half_num = try std.fmt.parseInt(u64, num_str[num_digits / 2 ..], 10);

            // Even number of digits -> Split into two halves
            try stoneMapDecCountDrop(stone_map, stone_num, stone_count);
            try stoneMapIncCountPut(stone_map, left_half_num, stone_count);
            try stoneMapIncCountPut(stone_map, right_half_num, stone_count);
        }
    }
}

fn solve(allocator: std.mem.Allocator, input: []const u8) !struct {
    num_stones_blink25: u64,
    num_stones_blink75: u64,
} {
    const input_trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var arena_allocator = arena.allocator();

    var stones_list = StonesList{};

    var stones_iter = std.mem.tokenizeScalar(u8, input_trimmed, ' ');
    while (stones_iter.next()) |stone| {
        const number = try std.fmt.parseInt(u64, stone, 10);
        const stone_node = try arena_allocator.create(StonesList.Node);
        stone_node.data = number;
        stones_list.append(stone_node);
    }

    // Part 1
    var num_stones_blink25: u64 = 0;
    {
        var stone_map = std.AutoHashMap(u64, u64).init(allocator);
        defer stone_map.deinit();

        var current_stone = stones_list.first;
        while (current_stone) |stone| : (current_stone = stone.next) {
            const res = try stone_map.getOrPut(stone.data);
            if (res.found_existing) {
                res.value_ptr.* += 1;
            } else {
                res.value_ptr.* = 1;
            }
        }

        try evolveStoneDistribution(&stone_map, 25);

        var stone_iter = stone_map.iterator();
        while (stone_iter.next()) |stone| {
            num_stones_blink25 += stone.value_ptr.*;
        }
    }

    // Part 2
    var num_stones_blink75: u64 = 0;
    {
        var stone_map = std.AutoHashMap(u64, u64).init(allocator);
        defer stone_map.deinit();

        var current_stone = stones_list.first;
        while (current_stone) |stone| : (current_stone = stone.next) {
            const res = try stone_map.getOrPut(stone.data);
            if (res.found_existing) {
                res.value_ptr.* += 1;
            } else {
                res.value_ptr.* = 1;
            }
        }

        try evolveStoneDistribution(&stone_map, 75);

        var stone_iter = stone_map.iterator();
        while (stone_iter.next()) |stone| {
            num_stones_blink75 += stone.value_ptr.*;
        }
    }

    return .{
        .num_stones_blink25 = num_stones_blink25,
        .num_stones_blink75 = num_stones_blink75,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution = try solve(allocator, @embedFile("input.txt"));
    std.debug.print("Day 11 - Part 1: {}\n", .{solution.num_stones_blink25});
    std.debug.print("Day 11 - Part 2: {}\n", .{solution.num_stones_blink75});
}

test "sample" {
    const solution = try solve(std.testing.allocator, @embedFile("sample.txt"));
    try std.testing.expectEqual(55312, solution.num_stones_blink25);
    try std.testing.expectEqual(65601038650482, solution.num_stones_blink75);
}
